import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/daily_sales_summary.dart';
import '../models/pricing_config.dart';
import '../models/sale_transaction.dart';
import '../models/shop_model.dart';
import 'pricing_calculator.dart';
import 'sales_repository.dart';

class MockLiveSalesRepository implements SalesRepository {
  static const String _keyShops = 'sales_auditor_shops_v1';
  static const String _keyAdminPin = 'sales_auditor_admin_pin_v1';
  static const String _keySelectedShop = 'sales_auditor_selected_shop_v1';
  static const String _keySalesPrefix = 'sales_auditor_daily_sales_v1_';

  final _uuid = const Uuid();
  final _shopsStreamController = StreamController<List<Shop>>.broadcast();
  final Map<String, StreamController<DailySalesSummary>> _salesStreamControllers =
      {};

  List<Shop> _shops = [];
  String _adminPin = '1234';
  String _selectedShopId = '';
  final Map<String, DailySalesSummary> _salesCache = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load or set PIN
      _adminPin = prefs.getString(_keyAdminPin) ?? '1234';

      // Load or set selected shop
      _selectedShopId = prefs.getString(_keySelectedShop) ?? '';

      // Load shops
      final shopsJson = prefs.getString(_keyShops);
      if (shopsJson != null) {
        final List<dynamic> decoded = jsonDecode(shopsJson);
        _shops = decoded
            .map((item) => Shop.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _shops = [];
        await _saveShopsToPrefs(prefs);
      }

      if (_selectedShopId.isEmpty && _shops.isNotEmpty) {
        _selectedShopId = _shops.first.id;
      }

      // Load today's sales for all shops
      final todayStr = _dateKey(DateTime.now());
      for (final shop in _shops) {
        final cacheKey = '${shop.id}_$todayStr';
        final savedSalesJson = prefs.getString('$_keySalesPrefix$cacheKey');
        if (savedSalesJson != null) {
          _salesCache[cacheKey] = DailySalesSummary.fromJson(
            jsonDecode(savedSalesJson) as Map<String, dynamic>,
          );
        } else {
          _salesCache[cacheKey] = DailySalesSummary(
            shopId: shop.id,
            date: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Fallback in-memory
      _shops = [];
    }

    _initialized = true;
    _notifyShopsChanged();
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _cacheKey(String shopId, DateTime date) =>
      '${shopId}_${_dateKey(date)}';

  StreamController<DailySalesSummary> _getSalesController(
    String shopId,
    DateTime date,
  ) {
    final key = _cacheKey(shopId, date);
    return _salesStreamControllers.putIfAbsent(
      key,
      () => StreamController<DailySalesSummary>.broadcast(),
    );
  }

  void _notifyShopsChanged() {
    _shopsStreamController.add(List.unmodifiable(_shops));
  }

  void _notifySalesChanged(String shopId, DateTime date) {
    final key = _cacheKey(shopId, date);
    final summary = _salesCache[key] ??
        DailySalesSummary(shopId: shopId, date: date);
    _getSalesController(shopId, date).add(summary);
  }

  Future<void> _saveShopsToPrefs([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_shops.map((s) => s.toJson()).toList());
      await p.setString(_keyShops, jsonString);
    } catch (_) {}
  }

  Future<void> _saveSalesToPrefs(String cacheKey, DailySalesSummary summary) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        '$_keySalesPrefix$cacheKey',
        jsonEncode(summary.toJson()),
      );
    } catch (_) {}
  }

  @override
  Stream<List<Shop>> watchShops() {
    return _shopsStreamController.stream;
  }

  @override
  Future<List<Shop>> getShops() async {
    if (!_initialized) await init();
    return List.unmodifiable(_shops);
  }

  @override
  Future<Shop?> getShop(String shopId) async {
    if (!_initialized) await init();
    try {
      return _shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveShop(Shop shop) async {
    if (!_initialized) await init();
    final index = _shops.indexWhere((s) => s.id == shop.id);
    if (index >= 0) {
      _shops[index] = shop;
    } else {
      _shops.add(shop);
    }
    await _saveShopsToPrefs();
    _notifyShopsChanged();
  }

  @override
  Future<void> updateShopPricing(String shopId, PricingConfig config) async {
    if (!_initialized) await init();
    final index = _shops.indexWhere((s) => s.id == shopId);
    if (index >= 0) {
      _shops[index] = _shops[index].copyWith(pricingConfig: config);
      await _saveShopsToPrefs();
      _notifyShopsChanged();
    }
  }

  @override
  Stream<DailySalesSummary> watchDailySales(String shopId, DateTime date) {
    return _getSalesController(shopId, date).stream;
  }

  @override
  Future<DailySalesSummary> getDailySales(String shopId, DateTime date) async {
    if (!_initialized) await init();
    final key = _cacheKey(shopId, date);
    return _salesCache[key] ?? DailySalesSummary(shopId: shopId, date: date);
  }

  @override
  Future<SaleTransaction> recordSale({
    required String shopId,
    required int ticketCount,
    required PricingConfig config,
  }) async {
    if (!_initialized) await init();
    final now = DateTime.now();
    final key = _cacheKey(shopId, now);

    final calc = PricingCalculator.calculate(
      ticketCount: ticketCount,
      config: config,
    );

    final transaction = SaleTransaction(
      id: _uuid.v4(),
      shopId: shopId,
      timestamp: now,
      ticketCount: ticketCount,
      totalAmount: calc.totalAmount,
      unitPrice: calc.unitPrice,
      isSetOrBulk: calc.isSetOrBulk,
    );

    final currentSummary = _salesCache[key] ??
        DailySalesSummary(shopId: shopId, date: now);
    final updatedList = List<SaleTransaction>.from(currentSummary.transactions)
      ..add(transaction);

    final newSummary = currentSummary.copyWith(transactions: updatedList);
    _salesCache[key] = newSummary;

    await _saveSalesToPrefs(key, newSummary);
    _notifySalesChanged(shopId, now);

    return transaction;
  }

  @override
  Future<bool> undoLastSale(String shopId) async {
    if (!_initialized) await init();
    final now = DateTime.now();
    final key = _cacheKey(shopId, now);

    final currentSummary = _salesCache[key];
    if (currentSummary == null || currentSummary.activeTransactions.isEmpty) {
      return false;
    }

    final activeTxs = currentSummary.activeTransactions;
    final lastActiveTx = activeTxs.last;

    final updatedTransactions = currentSummary.transactions.map((t) {
      if (t.id == lastActiveTx.id) {
        return t.copyWith(isCancelled: true);
      }
      return t;
    }).toList();

    final newSummary = currentSummary.copyWith(transactions: updatedTransactions);
    _salesCache[key] = newSummary;

    await _saveSalesToPrefs(key, newSummary);
    _notifySalesChanged(shopId, now);
    return true;
  }

  @override
  Future<void> resetDaySales(String shopId) async {
    if (!_initialized) await init();
    final now = DateTime.now();
    final key = _cacheKey(shopId, now);
    final newSummary = DailySalesSummary(shopId: shopId, date: now);
    _salesCache[key] = newSummary;
    await _saveSalesToPrefs(key, newSummary);
    _notifySalesChanged(shopId, now);
  }

  @override
  Future<bool> verifyAdminPin(String pin) async {
    if (!_initialized) await init();
    return pin == _adminPin;
  }

  @override
  Future<void> updateAdminPin(String newPin) async {
    if (!_initialized) await init();
    _adminPin = newPin;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAdminPin, newPin);
    } catch (_) {}
  }

  @override
  Future<String> getSelectedShopId() async {
    if (!_initialized) await init();
    return _selectedShopId;
  }

  @override
  Future<void> setSelectedShopId(String shopId) async {
    if (!_initialized) await init();
    _selectedShopId = shopId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedShop, shopId);
    } catch (_) {}
  }
}
