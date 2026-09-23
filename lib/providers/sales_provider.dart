import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/daily_sales_summary.dart';
import '../models/sale_transaction.dart';
import '../models/shop_model.dart';
import '../services/sales_repository.dart';

class SalesProvider extends ChangeNotifier {
  final SalesRepository _repository;

  List<Shop> _shops = [];
  Shop? _currentShop;
  DailySalesSummary _todaySummary = DailySalesSummary(
    shopId: '',
    date: DateTime.now(),
  );

  bool _isLoading = true;
  String? _errorMessage;
  SaleTransaction? _lastRecordedTx;

  StreamSubscription<List<Shop>>? _shopsSubscription;
  StreamSubscription<DailySalesSummary>? _salesSubscription;

  SalesProvider(this._repository) {
    _init();
  }

  List<Shop> get shops => _shops;
  Shop? get currentShop => _currentShop;
  DailySalesSummary get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SaleTransaction? get lastRecordedTx => _lastRecordedTx;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shops = await _repository.getShops();
      final savedShopId = await _repository.getSelectedShopId();

      if (_shops.isNotEmpty) {
        _currentShop = _shops.firstWhere(
          (s) => s.id == savedShopId,
          orElse: () => _shops.first,
        );
      }

      if (_currentShop != null) {
        _todaySummary = await _repository.getDailySales(
          _currentShop!.id,
          DateTime.now(),
        );
        _subscribeToSales(_currentShop!.id);
      }

      _shopsSubscription = _repository.watchShops().listen((shops) {
        _shops = shops;
        if (_currentShop != null) {
          try {
            _currentShop = shops.firstWhere((s) => s.id == _currentShop!.id);
          } catch (_) {
            if (shops.isNotEmpty) _currentShop = shops.first;
          }
        }
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToSales(String shopId) {
    _salesSubscription?.cancel();
    _salesSubscription = _repository
        .watchDailySales(shopId, DateTime.now())
        .listen((summary) {
      _todaySummary = summary;
      notifyListeners();
    });
  }

  Future<void> selectShop(String shopId) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      _currentShop = shop;
      await _repository.setSelectedShopId(shopId);
      _subscribeToSales(shopId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Shop not found: $shopId';
      notifyListeners();
    }
  }

  Future<SaleTransaction?> recordSale(int ticketCount) async {
    if (_currentShop == null) return null;

    try {
      final tx = await _repository.recordSale(
        shopId: _currentShop!.id,
        ticketCount: ticketCount,
        config: _currentShop!.pricingConfig,
      );
      _lastRecordedTx = tx;
      notifyListeners();
      return tx;
    } catch (e) {
      _errorMessage = 'Failed to record sale: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> undoLastSale() async {
    if (_currentShop == null) return false;
    try {
      final result = await _repository.undoLastSale(_currentShop!.id);
      if (result) {
        _lastRecordedTx = null;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Failed to undo sale: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> resetTodaySales() async {
    if (_currentShop == null) return;
    try {
      await _repository.resetDaySales(_currentShop!.id);
      _lastRecordedTx = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to reset: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _shopsSubscription?.cancel();
    _salesSubscription?.cancel();
    super.dispose();
  }
}
