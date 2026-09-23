import '../models/daily_sales_summary.dart';
import '../models/pricing_config.dart';
import '../models/sale_transaction.dart';
import '../models/shop_model.dart';

abstract class SalesRepository {
  Stream<List<Shop>> watchShops();
  Future<List<Shop>> getShops();
  Future<Shop?> getShop(String shopId);
  Future<void> saveShop(Shop shop);
  Future<void> updateShopPricing(String shopId, PricingConfig config);

  Stream<DailySalesSummary> watchDailySales(String shopId, DateTime date);
  Future<DailySalesSummary> getDailySales(String shopId, DateTime date);
  Future<SaleTransaction> recordSale({
    required String shopId,
    required int ticketCount,
    required PricingConfig config,
  });
  Future<bool> undoLastSale(String shopId);
  Future<void> resetDaySales(String shopId);

  Future<bool> verifyAdminPin(String pin);
  Future<void> updateAdminPin(String newPin);

  Future<String> getSelectedShopId();
  Future<void> setSelectedShopId(String shopId);
}
