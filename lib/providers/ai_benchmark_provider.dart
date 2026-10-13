import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ai_benchmark_models.dart';
import '../models/daily_sales_summary.dart';
import '../models/shop_model.dart';
import '../services/nemotron_ai_service.dart';
import '../services/sales_repository.dart';

class AiBenchmarkProvider extends ChangeNotifier {
  final SalesRepository _repository;
  final NemotronAiService _aiService;

  AiConfig _config = AiConfig(updatedAt: DateTime.now());
  List<ShopAiBenchmark> _reports = [];
  bool _isLoading = false;
  bool _isAuditing = false;
  String? _errorMessage;
  ShopAiBenchmark? _selectedReport;

  AiBenchmarkProvider({
    required this._repository,
    NemotronAiService? aiService,
  })  : _aiService = aiService ?? NemotronAiService() {
    _init();
  }

  AiConfig get config => _config;
  List<ShopAiBenchmark> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isAuditing => _isAuditing;
  String? get errorMessage => _errorMessage;
  ShopAiBenchmark? get selectedReport => _selectedReport;

  NetworkTrustMatrixSummary get trustMatrix =>
      NetworkTrustMatrixSummary.fromReports(_reports);

  ShopAiBenchmark? getReportForShop(String shopId) {
    try {
      return _reports.firstWhere((r) => r.shopId == shopId);
    } catch (_) {
      return null;
    }
  }

  void selectReport(ShopAiBenchmark? report) {
    _selectedReport = report;
    notifyListeners();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _config = await _repository.getAiConfig();
    } catch (e) {
      debugPrint('>>> AiBenchmarkProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Run automated Nemotron AI audit for all shops across the distribution network
  Future<void> runFullNetworkAudit({
    required List<Shop> shops,
    required Map<String, DailySalesSummary> summaries,
  }) async {
    if (shops.isEmpty) return;

    _isAuditing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Refresh AI Config
      _config = await _repository.getAiConfig();

      final List<ShopAiBenchmark> newReports = [];

      for (final shop in shops) {
        final summary = summaries[shop.id] ??
            DailySalesSummary(shopId: shop.id, date: DateTime.now());

        final past = _reports.where((r) => r.shopId == shop.id).toList();

        final report = await _aiService.auditShopSales(
          shop: shop,
          summary: summary,
          config: _config,
          customClaimedRate: shop.claimedAverageRate,
          pastReports: past,
        );
        newReports.add(report);
      }

      _reports = newReports;
      if (_selectedReport != null) {
        _selectedReport = getReportForShop(_selectedReport!.shopId);
      }
    } catch (e) {
      _errorMessage = 'Audit run encountered an error: $e';
    } finally {
      _isAuditing = false;
      notifyListeners();
    }
  }

  /// Re-audit a single shop with a customized claimed rate
  Future<ShopAiBenchmark?> reAuditShop({
    required Shop shop,
    required DailySalesSummary summary,
    required double claimedRate,
  }) async {
    _isAuditing = true;
    notifyListeners();

    try {
      // 1. Update shop with new claimed rate in repository
      final updatedShop = shop.copyWith(claimedAverageRate: claimedRate);
      await _repository.saveShop(updatedShop);

      // 2. Run AI audit
      final report = await _aiService.auditShopSales(
        shop: updatedShop,
        summary: summary,
        config: _config,
        customClaimedRate: claimedRate,
      );

      // 3. Update report in memory
      final index = _reports.indexWhere((r) => r.shopId == shop.id);
      if (index != -1) {
        _reports[index] = report;
      } else {
        _reports.add(report);
      }

      if (_selectedReport?.shopId == shop.id) {
        _selectedReport = report;
      }

      _isAuditing = false;
      notifyListeners();
      return report;
    } catch (e) {
      _errorMessage = 'Failed to re-audit shop: $e';
      _isAuditing = false;
      notifyListeners();
      return null;
    }
  }

  /// Save new API Key and Model configuration to Cloud Database
  Future<bool> saveAiConfig({
    required String apiKey,
    required String modelName,
    String? endpointUrl,
    double? defaultClaimedRate,
  }) async {
    try {
      final updated = _config.copyWith(
        apiKey: apiKey.trim(),
        modelName: modelName.trim(),
        endpointUrl: endpointUrl?.trim(),
        defaultClaimedRate: defaultClaimedRate,
        updatedAt: DateTime.now(),
      );

      await _repository.saveAiConfig(updated);
      _config = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save AI configuration: $e';
      notifyListeners();
      return false;
    }
  }

  /// Launch WhatsApp with pre-filled AI Audit Proof
  Future<bool> shareToWhatsApp(ShopAiBenchmark report, {String? phoneNumber}) async {
    final encodedText = Uri.encodeComponent(report.whatsappProofText);
    final cleanPhone = phoneNumber?.replaceAll(RegExp(r'\D'), '') ?? '';

    final urlString = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encodedText'
        : 'https://wa.me/?text=$encodedText';

    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}

    // Fallback: Copy to clipboard
    await copyProofText(report);
    return false;
  }

  /// Copy WhatsApp Proof text to system clipboard
  Future<void> copyProofText(ShopAiBenchmark report) async {
    await Clipboard.setData(ClipboardData(text: report.whatsappProofText));
  }
}
