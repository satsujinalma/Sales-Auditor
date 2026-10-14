import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/ai_benchmark_models.dart';
import '../models/daily_sales_summary.dart';
import '../models/shop_model.dart';

class NemotronAiService {
  final http.Client _client;

  NemotronAiService({http.Client? client}) : _client = client ?? http.Client();

  /// Audits a shop using NVIDIA Nemotron AI with instant fallback to
  /// mathematical rule auditor if API key is not present or network times out.
  Future<ShopAiBenchmark> auditShopSales({
    required Shop shop,
    required DailySalesSummary summary,
    required AiConfig config,
    double? customClaimedRate,
    List<ShopAiBenchmark> pastReports = const [],
    bool allowFallback = false,
  }) async {
    final claimedRate = customClaimedRate ?? shop.claimedAverageRate;
    final totalTickets = summary.totalTicketsSold;
    final totalRevenue = summary.totalRevenue;
    final actualAverage = summary.averagePricePerTicket;
    final bundleTickets = summary.bulkTicketsSold;
    final singleTickets = summary.singleTicketsSold;
    final bundleRatio = summary.bulkTicketsPercentage;
    final singleRatio = summary.singleTicketsPercentage;
    final now = DateTime.now();

    // 1. If API Key is present, invoke live NVIDIA Nemotron NIM
    if (config.hasApiKey) {
      return await _callNemotronApi(
        shop: shop,
        claimedRate: claimedRate,
        totalTickets: totalTickets,
        totalRevenue: totalRevenue,
        actualAverage: actualAverage,
        bundleTickets: bundleTickets,
        singleTickets: singleTickets,
        bundleRatio: bundleRatio,
        singleRatio: singleRatio,
        config: config,
        pastReports: pastReports,
        now: now,
      );
    }

    // 2. Offline fallback only if explicitly permitted (e.g., test mocks)
    if (allowFallback) {
      return _generateRuleBasedAudit(
        shop: shop,
        claimedRate: claimedRate,
        totalTickets: totalTickets,
        totalRevenue: totalRevenue,
        actualAverage: actualAverage,
        bundleTickets: bundleTickets,
        singleTickets: singleTickets,
        bundleRatio: bundleRatio,
        singleRatio: singleRatio,
        modelUsed: 'Rule Engine Test',
        now: now,
      );
    }

    throw Exception(
      'NVIDIA API Key not found in Cloud Database. Please add apiKey in Firestore (settings/ai_config or settings/admin_config) to run live AI audits.',
    );
  }

  /// Calls NVIDIA Nemotron API via standard OpenAI-compatible endpoint
  Future<ShopAiBenchmark> _callNemotronApi({
    required Shop shop,
    required double claimedRate,
    required int totalTickets,
    required double totalRevenue,
    required double actualAverage,
    required int bundleTickets,
    required int singleTickets,
    required double bundleRatio,
    required double singleRatio,
    required AiConfig config,
    required List<ShopAiBenchmark> pastReports,
    required DateTime now,
  }) async {
    final prompt = _buildAuditPrompt(
      shopName: shop.name,
      shopCode: shop.code,
      claimedRate: claimedRate,
      totalTickets: totalTickets,
      totalRevenue: totalRevenue,
      actualAverage: actualAverage,
      bundleTickets: bundleTickets,
      singleTickets: singleTickets,
      bundleRatio: bundleRatio,
      singleRatio: singleRatio,
    );

    final requestBody = {
      'model': config.modelName,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are the official NVDIA AI Kerala Lottery Sales Auditor. '
              'Your job is to compare retail shop claims with real sales logs and assign one of three exact status tags: '
              '1) "Matches" (🟢 Math & bundle mix match claimed average within ₹0.35) '
              '2) "Close Enough" (🟡 Variance within acceptable margin due to single ticket purchases) '
              '3) "Mismatch" (🔴 Claimed low average but high bundle volume proves average is higher). '
              'Always provide depth in simple professional terms for weekly retailer settlements. '
              'Always respond strictly with a valid JSON object matching the requested schema with no extra prose.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.2,
      'max_tokens': 1024,
    };

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(config.endpointUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey.trim()}',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      if (kIsWeb && (e.toString().contains('Failed to fetch') || e.toString().contains('ClientException'))) {
        throw Exception(
          'Web Browser CORS Block: Direct API calls to NVIDIA are blocked by browser security (CORS) on Web. '
          'Native Android & iOS mobile apps do not have CORS restrictions and connect directly. '
          'For web testing, start Chrome with: flutter run -d chrome --web-browser-flag "--disable-web-security"',
        );
      }
      rethrow;
    }

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          detail = decoded['message'].toString();
        } else if (decoded is Map && decoded['error'] != null) {
          detail = decoded['error'].toString();
        }
      } catch (_) {}
      throw Exception('NVIDIA API Error (${response.statusCode}): $detail');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('NVIDIA API returned empty response.');
    }

    final content = choices.first['message']?['content'] as String? ?? '';
    final parsed = _extractJsonFromContent(content);
    if (parsed == null) {
      throw Exception('NVIDIA AI output could not be parsed as JSON: $content');
    }

    final statusTagStr = parsed['statusTag'] as String? ?? 'Matches';
    final statusTag = AiStatusTag.fromString(statusTagStr);
    final auditSummary = parsed['auditSummary'] as String? ??
        'Sales analyzed. ${bundleRatio.toStringAsFixed(0)}% bundle volume yields average of ₹${actualAverage.toStringAsFixed(2)}.';
    final ticketMixAnalysis = parsed['ticketMixAnalysis'] as String? ??
        'Bundle ratio: ${bundleRatio.toStringAsFixed(1)}% ($bundleTickets tkt) vs Singles: ${singleRatio.toStringAsFixed(1)}% ($singleTickets tkt).';
    final habitTrackingAnalysis = parsed['habitTrackingAnalysis'] as String? ??
        'Evaluated across daily sales volume records.';
    final settlementInsight = parsed['settlementInsight'] as String?;

    final whatsappProof = _buildDefaultWhatsAppProof(
      shop: shop,
      claimedRate: claimedRate,
      totalTickets: totalTickets,
      totalRevenue: totalRevenue,
      actualAverage: actualAverage,
      bundleTickets: bundleTickets,
      singleTickets: singleTickets,
      bundleRatio: bundleRatio,
      statusTag: statusTag,
      auditSummary: auditSummary,
      settlementDepth: settlementInsight,
      now: now,
    );

    return ShopAiBenchmark(
      shopId: shop.id,
      shopName: shop.name,
      shopCode: shop.code,
      totalTickets: totalTickets,
      totalRevenue: totalRevenue,
      actualAveragePrice: actualAverage,
      claimedAveragePrice: claimedRate,
      bundleTicketsCount: bundleTickets,
      singleTicketsCount: singleTickets,
      bundleRatioPercentage: bundleRatio,
      singleRatioPercentage: singleRatio,
      statusTag: statusTag,
      auditSummary: auditSummary,
      ticketMixAnalysis: ticketMixAnalysis,
      habitTrackingAnalysis: habitTrackingAnalysis,
      whatsappProofText: whatsappProof,
      auditedAt: now,
      modelUsed: config.modelName,
    );
  }

  /// Rule-based mathematical audit engine
  ShopAiBenchmark _generateRuleBasedAudit({
    required Shop shop,
    required double claimedRate,
    required int totalTickets,
    required double totalRevenue,
    required double actualAverage,
    required int bundleTickets,
    required int singleTickets,
    required double bundleRatio,
    required double singleRatio,
    required String modelUsed,
    required DateTime now,
  }) {
    AiStatusTag statusTag;
    String auditSummary;
    String ticketMixAnalysis;
    String habitAnalysis;

    final diff = actualAverage - claimedRate;

    if (totalTickets == 0) {
      statusTag = AiStatusTag.matches;
      auditSummary = 'No tickets entered for today yet. Counter is initialized.';
      ticketMixAnalysis = 'Waiting for counter ticket transactions.';
      habitAnalysis = 'Zero variance recorded.';
    } else if (bundleRatio >= 50.0 && diff >= 0.45) {
      // Flagged: high bundle sales, but owner claims low margins
      statusTag = AiStatusTag.mismatch;
      auditSummary =
          'Shop owner claims low margins (₹${claimedRate.toStringAsFixed(2)}), but ${bundleRatio.toStringAsFixed(0)}% bundle volume proves a higher average of ₹${actualAverage.toStringAsFixed(2)}. Flagged for review.';
      ticketMixAnalysis =
          'High 12-ticket set volume ($bundleTickets tickets, ${bundleRatio.toStringAsFixed(1)}%) heavily outpaces retail singles ($singleTickets tickets).';
      habitAnalysis =
          'Habit pattern detected: Recurrent discrepancy between declared margins and actual set ticket volumes.';
    } else if (diff.abs() <= 0.35) {
      // Healthy matches
      statusTag = AiStatusTag.matches;
      auditSummary =
          'Sales are healthy. ${bundleRatio.toStringAsFixed(0)}% bundle sales yield a strong ₹${actualAverage.toStringAsFixed(2)} average, proving reporting is accurate.';
      ticketMixAnalysis =
          'Balanced ticket distribution: $bundleTickets set tickets (${bundleRatio.toStringAsFixed(0)}%) and $singleTickets singles (${singleRatio.toStringAsFixed(0)}%).';
      habitAnalysis = 'Operating well within expected target margin ranges.';
    } else {
      // Close Enough: higher singles explain the lower average
      statusTag = AiStatusTag.closeEnough;
      auditSummary =
          'Higher single-ticket volume today (${singleRatio.toStringAsFixed(0)}%) explains the variance. Acceptable daily variance.';
      ticketMixAnalysis =
          'Single ticket volume is prominent at ${singleRatio.toStringAsFixed(1)}% ($singleTickets tickets).';
      habitAnalysis = 'Normal daily fluctuation based on consumer walk-in demand.';
    }

    final whatsappProof = _buildDefaultWhatsAppProof(
      shop: shop,
      claimedRate: claimedRate,
      totalTickets: totalTickets,
      totalRevenue: totalRevenue,
      actualAverage: actualAverage,
      bundleTickets: bundleTickets,
      singleTickets: singleTickets,
      bundleRatio: bundleRatio,
      statusTag: statusTag,
      auditSummary: auditSummary,
      now: now,
    );

    return ShopAiBenchmark(
      shopId: shop.id,
      shopName: shop.name,
      shopCode: shop.code,
      totalTickets: totalTickets,
      totalRevenue: totalRevenue,
      actualAveragePrice: actualAverage,
      claimedAveragePrice: claimedRate,
      bundleTicketsCount: bundleTickets,
      singleTicketsCount: singleTickets,
      bundleRatioPercentage: bundleRatio,
      singleRatioPercentage: singleRatio,
      statusTag: statusTag,
      auditSummary: auditSummary,
      ticketMixAnalysis: ticketMixAnalysis,
      habitTrackingAnalysis: habitAnalysis,
      whatsappProofText: whatsappProof,
      auditedAt: now,
      modelUsed: modelUsed,
    );
  }

  String _buildAuditPrompt({
    required String shopName,
    required String shopCode,
    required double claimedRate,
    required int totalTickets,
    required double totalRevenue,
    required double actualAverage,
    required int bundleTickets,
    required int singleTickets,
    required double bundleRatio,
    required double singleRatio,
  }) {
    return '''
Audit the following Kerala Lottery Retail Counter:
Shop Name: "$shopName" (Code: $shopCode)
Claimed Average Rate by Retailer: ₹${claimedRate.toStringAsFixed(2)}
Actual Total Tickets Sold: $totalTickets
Actual Gross Revenue: ₹${totalRevenue.toStringAsFixed(2)}
Actual Weighted Average Per Ticket: ₹${actualAverage.toStringAsFixed(2)}
12-Ticket Bundle Sales: $bundleTickets tickets (${bundleRatio.toStringAsFixed(1)}%)
Single Tickets Sales: $singleTickets tickets (${singleRatio.toStringAsFixed(1)}%)

Required Output JSON Format:
{
  "statusTag": "Matches" | "Close Enough" | "Mismatch",
  "auditSummary": "1-2 concise professional sentences for the distributor table",
  "ticketMixAnalysis": "Explanation of bundle vs singles mix",
  "habitTrackingAnalysis": "Assessment of reporting habit",
  "settlementInsight": "Depth and settlement insight for the distributor"
}
''';
  }

  String _buildDefaultWhatsAppProof({
    required Shop shop,
    required double claimedRate,
    required int totalTickets,
    required double totalRevenue,
    required double actualAverage,
    required int bundleTickets,
    required int singleTickets,
    required double bundleRatio,
    required AiStatusTag statusTag,
    required String auditSummary,
    String? settlementDepth,
    required DateTime now,
  }) {
    final dateStr = DateFormat('dd-MM-yyyy').format(now);
    final variance = actualAverage - claimedRate;
    final sign = variance >= 0 ? '+' : '';
    final singleRatio = (100.0 - bundleRatio).clamp(0.0, 100.0);
    final depth = (settlementDepth != null && settlementDepth.trim().isNotEmpty)
        ? settlementDepth.trim()
        : _generateSettlementInsight(
            statusTag: statusTag,
            bundleRatio: bundleRatio,
            singleRatio: singleRatio,
            claimedRate: claimedRate,
            actualAverage: actualAverage,
          );

    return '''
🚨 *KERALA LOTTERY SALES AUDIT REPORT* 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━
🏪 *Shop:* ${shop.name} (${shop.code.isNotEmpty ? shop.code : shop.id})
📅 *Audit Date:* $dateStr
🤖 *Audited by:* NVDIA AI

📊 *SALES METRICS:*
• Total Volume: $totalTickets tickets
• Gross Revenue: ₹${totalRevenue.toStringAsFixed(2)}
• Claimed Avg Rate: ₹${claimedRate.toStringAsFixed(2)} / ticket
• Actual Logged Rate: ₹${actualAverage.toStringAsFixed(2)} / ticket
• Margin Variance: $sign₹${variance.toStringAsFixed(2)} / ticket

📦 *TICKET-MIX BREAKDOWN:*
• 12-Ticket Sets: ${bundleRatio.toStringAsFixed(1)}% ($bundleTickets tickets)
• Single Tickets: ${singleRatio.toStringAsFixed(1)}% ($singleTickets tickets)

⚖️ *AI AUDIT VERDICT: ${statusTag.badgeText.toUpperCase()}*
$auditSummary

💡 *AUDIT DEPTH & SETTLEMENT INSIGHT:*
$depth

🔒 *Verified & Signed by Distributor Sales Audit Engine*
''';
  }

  String _generateSettlementInsight({
    required AiStatusTag statusTag,
    required double bundleRatio,
    required double singleRatio,
    required double claimedRate,
    required double actualAverage,
  }) {
    switch (statusTag) {
      case AiStatusTag.mismatch:
        return 'High bundle proportion (${bundleRatio.toStringAsFixed(1)}%) mathematically contradicts the claimed ₹${claimedRate.toStringAsFixed(2)} margin. Bundle sales at set pricing establish a minimum realized average of ₹${actualAverage.toStringAsFixed(2)}. Distributor settlement should be evaluated against logged data.';
      case AiStatusTag.matches:
        return 'Healthy balance between 12-ticket sets and walk-in singles. Unalterable logs confirm reporting accuracy within tolerance (₹${actualAverage.toStringAsFixed(2)} vs ₹${claimedRate.toStringAsFixed(2)}). Clear for standard weekly retailer settlement.';
      case AiStatusTag.closeEnough:
        return 'Prominent single-ticket transactions (${singleRatio.toStringAsFixed(1)}%) account for the observed margin variance. Retailer stated claim is supported by consumer purchasing patterns.';
    }
  }

  Map<String, dynamic>? _extractJsonFromContent(String content) {
    try {
      var cleaned = content.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final jsonSub = cleaned.substring(start, end + 1);
        try {
          return jsonDecode(jsonSub) as Map<String, dynamic>;
        } catch (_) {
          final relaxed = jsonSub.replaceAll(RegExp(r',\s*([\}\]])'), r'$1');
          return jsonDecode(relaxed) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('>>> Failed standard JSON parse from AI response: $e');
    }

    // Secondary fallback: regex extraction so we NEVER fail on partial truncation
    try {
      final statusMatch = RegExp(r'"statusTag"\s*:\s*"([^"]+)"').firstMatch(content);
      final summaryMatch = RegExp(r'"auditSummary"\s*:\s*"([^"]+)"').firstMatch(content);
      final mixMatch = RegExp(r'"ticketMixAnalysis"\s*:\s*"([^"]+)"').firstMatch(content);
      final habitMatch = RegExp(r'"habitTrackingAnalysis"\s*:\s*"([^"]+)"').firstMatch(content);
      final insightMatch = RegExp(r'"settlementInsight"\s*:\s*"([^"]+)"').firstMatch(content);

      if (statusMatch != null) {
        return {
          'statusTag': statusMatch.group(1),
          if (summaryMatch != null) 'auditSummary': summaryMatch.group(1),
          if (mixMatch != null) 'ticketMixAnalysis': mixMatch.group(1),
          if (habitMatch != null) 'habitTrackingAnalysis': habitMatch.group(1),
          if (insightMatch != null) 'settlementInsight': insightMatch.group(1),
        };
      }
    } catch (e) {
      debugPrint('>>> Regex extraction fallback error: $e');
    }

    return null;
  }

  @visibleForTesting
  Map<String, dynamic>? extractJsonForTesting(String content) =>
      _extractJsonFromContent(content);
}
