import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/daily_sales_summary.dart';
import '../models/pricing_config.dart';
import '../models/sale_transaction.dart';
import '../models/shop_model.dart';
import 'pricing_calculator.dart';
import 'sales_repository.dart';

class FirestoreSalesRepository implements SalesRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  static const String _keySelectedShop = 'sales_auditor_selected_shop_v1';

  FirestoreSalesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shopsRef =>
      _firestore.collection('shops');

  CollectionReference<Map<String, dynamic>> get _dailySalesRef =>
      _firestore.collection('daily_sales');

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _firestore.collection('settings').doc('admin_config');

  DocumentReference<Map<String, dynamic>> get _adminCredentialsRef =>
      _firestore.collection('settings').doc('admin_credentials');

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _docId(String shopId, DateTime date) =>
      '${shopId}_${_dateKey(date)}';

  Future<void> init() async {
    // Enable offline persistence settings
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Seed admin PIN if not set
    final settingsDoc = await _settingsRef.get();
    if (!settingsDoc.exists) {
      await _settingsRef.set({'adminPin': '1234'});
    }

    // Seed default admin credentials in cloud database if not set
    final credsDoc = await _adminCredentialsRef.get();
    if (!credsDoc.exists) {
      await _adminCredentialsRef.set({
        'username': 'admin',
        'password': 'vazhapazhamadmin@321',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Stream<List<Shop>> watchShops() {
    return _shopsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Shop.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<Shop>> getShops() async {
    final snapshot = await _shopsRef.get();
    return snapshot.docs.map((doc) => Shop.fromJson(doc.data())).toList();
  }

  @override
  Future<Shop?> getShop(String shopId) async {
    final doc = await _shopsRef.doc(shopId).get();
    if (doc.exists && doc.data() != null) {
      return Shop.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> saveShop(Shop shop) async {
    await _shopsRef.doc(shop.id).set(shop.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateShopPricing(String shopId, PricingConfig config) async {
    await _shopsRef.doc(shopId).set(
      {'pricingConfig': config.toJson()},
      SetOptions(merge: true),
    );
  }

  @override
  Stream<DailySalesSummary> watchDailySales(String shopId, DateTime date) {
    final docId = _docId(shopId, date);
    return _dailySalesRef.doc(docId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return DailySalesSummary(shopId: shopId, date: date);
      }
      return DailySalesSummary.fromJson(doc.data()!);
    });
  }

  @override
  Future<DailySalesSummary> getDailySales(String shopId, DateTime date) async {
    final docId = _docId(shopId, date);
    final doc = await _dailySalesRef.doc(docId).get();
    if (!doc.exists || doc.data() == null) {
      return DailySalesSummary(shopId: shopId, date: date);
    }
    return DailySalesSummary.fromJson(doc.data()!);
  }

  @override
  Future<SaleTransaction> recordSale({
    required String shopId,
    required int ticketCount,
    required PricingConfig config,
  }) async {
    final now = DateTime.now();
    final docId = _docId(shopId, now);

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

    final docRef = _dailySalesRef.doc(docId);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      DailySalesSummary summary;
      if (snapshot.exists && snapshot.data() != null) {
        summary = DailySalesSummary.fromJson(snapshot.data()!);
      } else {
        summary = DailySalesSummary(shopId: shopId, date: now);
      }

      final updatedTransactions = List<SaleTransaction>.from(summary.transactions)
        ..add(transaction);
      final newSummary = summary.copyWith(transactions: updatedTransactions);

      tx.set(docRef, newSummary.toJson(), SetOptions(merge: true));
    });

    return transaction;
  }

  @override
  Future<bool> undoLastSale(String shopId) async {
    final now = DateTime.now();
    final docId = _docId(shopId, now);
    final docRef = _dailySalesRef.doc(docId);

    bool undone = false;

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final summary = DailySalesSummary.fromJson(snapshot.data()!);
      final activeTxs = summary.activeTransactions;
      if (activeTxs.isEmpty) return;

      final lastActiveTx = activeTxs.last;
      final updatedList = summary.transactions.map((t) {
        if (t.id == lastActiveTx.id) {
          return t.copyWith(isCancelled: true);
        }
        return t;
      }).toList();

      final newSummary = summary.copyWith(transactions: updatedList);
      tx.set(docRef, newSummary.toJson(), SetOptions(merge: true));
      undone = true;
    });

    return undone;
  }

  @override
  Future<void> resetDaySales(String shopId) async {
    final now = DateTime.now();
    final docId = _docId(shopId, now);
    await _dailySalesRef.doc(docId).set(
      DailySalesSummary(shopId: shopId, date: now).toJson(),
    );
  }

  @override
  Future<bool> verifyAdminPin(String pin) async {
    try {
      final doc = await _settingsRef.get();
      final currentPin = doc.data()?['adminPin'] as String? ?? '1234';
      return pin == currentPin;
    } catch (_) {
      return pin == '1234';
    }
  }

  @override
  Future<void> updateAdminPin(String newPin) async {
    await _settingsRef.set({'adminPin': newPin}, SetOptions(merge: true));
  }

  @override
  Future<String> getSelectedShopId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySelectedShop) ?? 'nayarambalam';
    } catch (_) {
      return 'nayarambalam';
    }
  }

  @override
  Future<void> setSelectedShopId(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedShop, shopId);
    } catch (_) {}
  }

  Future<Map<String, String>> getAdminCredentials() async {
    try {
      final doc = await _adminCredentialsRef.get();
      if (doc.exists && doc.data() != null) {
        return {
          'username': doc.data()!['username'] as String? ?? 'admin',
          'password': doc.data()!['password'] as String? ?? 'vazhapazhamadmin@321',
        };
      }
    } catch (_) {}
    return {
      'username': 'admin',
      'password': 'vazhapazhamadmin@321',
    };
  }

  Future<void> updateAdminCredentials({
    required String username,
    required String password,
  }) async {
    await _adminCredentialsRef.set({
      'username': username.trim(),
      'password': password.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<bool> verifyAdminCredentials({
    required String username,
    required String password,
  }) async {
    final creds = await getAdminCredentials();
    return creds['username'] == username.trim() &&
        creds['password'] == password.trim();
  }
}
