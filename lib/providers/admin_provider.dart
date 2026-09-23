import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/daily_sales_summary.dart';
import '../models/pricing_config.dart';
import '../models/shop_model.dart';
import '../services/sales_repository.dart';

class AdminProvider extends ChangeNotifier {
  final SalesRepository _repository;

  List<Shop> _shops = [];
  String _selectedShopId = 'nayarambalam';
  DailySalesSummary _selectedShopSummary = DailySalesSummary(
    shopId: '',
    date: DateTime.now(),
  );
  final Map<String, DailySalesSummary> _allShopSummaries = {};

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<Shop>>? _shopsSubscription;
  StreamSubscription<DailySalesSummary>? _selectedShopSalesSubscription;
  final Map<String, StreamSubscription<DailySalesSummary>>
      _multiShopSubscriptions = {};

  AdminProvider(this._repository) {
    _init();
  }

  List<Shop> get shops => _shops;
  String get selectedShopId => _selectedShopId;
  Shop? get selectedShop {
    try {
      return _shops.firstWhere((s) => s.id == _selectedShopId);
    } catch (_) {
      return _shops.isNotEmpty ? _shops.first : null;
    }
  }

  DailySalesSummary get selectedShopSummary => _selectedShopSummary;
  Map<String, DailySalesSummary> get allShopSummaries => _allShopSummaries;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shops = await _repository.getShops();
      if (_shops.isNotEmpty) {
        _selectedShopId = _shops.first.id;
        _selectedShopSummary = await _repository.getDailySales(
          _selectedShopId,
          DateTime.now(),
        );
        _subscribeToSelectedShop(_selectedShopId);
      }

      for (final shop in _shops) {
        _allShopSummaries[shop.id] = await _repository.getDailySales(
          shop.id,
          DateTime.now(),
        );
      }

      _updateMultiShopSubscriptions();

      _shopsSubscription = _repository.watchShops().listen((shops) {
        _shops = shops;
        _updateMultiShopSubscriptions();
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateMultiShopSubscriptions() {
    for (final sub in _multiShopSubscriptions.values) {
      sub.cancel();
    }
    _multiShopSubscriptions.clear();

    for (final shop in _shops) {
      _multiShopSubscriptions[shop.id] = _repository
          .watchDailySales(shop.id, DateTime.now())
          .listen((summary) {
        _allShopSummaries[shop.id] = summary;
        notifyListeners();
      });
    }
  }

  void _subscribeToSelectedShop(String shopId) {
    _selectedShopSalesSubscription?.cancel();
    _selectedShopSalesSubscription = _repository
        .watchDailySales(shopId, DateTime.now())
        .listen((summary) {
      _selectedShopSummary = summary;
      notifyListeners();
    });
  }

  void selectShop(String shopId) {
    if (_selectedShopId != shopId) {
      _selectedShopId = shopId;
      _subscribeToSelectedShop(shopId);
      notifyListeners();
    }
  }

  Future<bool> verifyPin(String pin) async {
    final valid = await _repository.verifyAdminPin(pin);
    _isAuthenticated = valid;
    notifyListeners();
    return valid;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updatePricing(String shopId, PricingConfig config) async {
    try {
      await _repository.updateShopPricing(shopId, config);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update pricing: $e';
      notifyListeners();
    }
  }

  Future<void> saveShop(Shop shop) async {
    try {
      await _repository.saveShop(shop);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save shop: $e';
      notifyListeners();
    }
  }

  Future<void> updatePin(String newPin) async {
    try {
      await _repository.updateAdminPin(newPin);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update PIN: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _shopsSubscription?.cancel();
    _selectedShopSalesSubscription?.cancel();
    for (final sub in _multiShopSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
