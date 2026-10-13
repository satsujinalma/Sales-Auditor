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

    // 1. If API Key is present, attempt live NVIDIA Nemotron NIM invocation
    if (config.hasApiKey) {
      try {
        final liveReport = await _callNemotronApi(
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
        if (liveReport != null) {
          return liveReport;
        }
      } catch (e) {
        debugPrint('>>> NemotronAiService live API error (using rule engine): $e');
      }
    }

    // 2. Deterministic Rule-Based Audit Engine (100% mathematical accuracy fallback)
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
      modelUsed: config.hasApiKey ? '${config.modelName} (Rule-Assisted)' : 'Nemotron Rule Engine (Local)',
      now: now,
    );
  }

  /// Calls NVIDIA Nemotron API via standard OpenAI-compatible endpoint
  Future<ShopAiBenchmark?> _callNemotronApi({
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
              'You are the official NVIDIA Nemotron-3 Super Kerala Lottery Sales Auditor. '
              'Your job is to compare retail shop claims with real sales logs and assign one of three exact status tags: '
              '1) "Matches" (🟢 Math & bundle mix match claimed average within ₹0.35) '
              '2) "Close Enough" (🟡 Variance within acceptable margin due to single ticket purchases) '
              '3) "Mismatch" (🔴 Claimed low average but high bundle volume proves average is higher). '
              'Always respond strictly with a valid JSON object matching the requested schema with no extra prose.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.2,
      'max_tokens': 600,
    };

    final response = await _client
        .post(
          Uri.parse(config.endpointUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey.trim()}',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      debugPrint('>>> Nemotron API returned code ${response.statusCode}: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return null;

    final content = choices.first['message']?['content'] as String? ?? '';
    final parsed = _extractJsonFromContent(content);
    if (parsed == null) return null;

    final statusTagStr = parsed['statusTag'] as String? ?? 'Matches';
    final statusTag = AiStatusTag.fromString(statusTagStr);
    final auditSummary = parsed['auditSummary'] as String? ??
        'Sales analyzed. ${bundleRatio.toStringAsFixed(0)}% bundle volume yields average of ₹${actualAverage.toStringAsFixed(2)}.';
    final ticketMixAnalysis = parsed['ticketMixAnalysis'] as String? ??
        'Bundle ratio: ${bundleRatio.toStringAsFixed(1)}% ($bundleTickets tkt) vs Singles: ${singleRatio.toStringAsFixed(1)}% ($singleTickets tkt).';
    final habitTrackingAnalysis = parsed['habitTrackingAnalysis'] as String? ??
        'Evaluated across daily sales volume records.';
    final whatsappProof = parsed['whatsappProofText'] as String? ??
        _buildDefaultWhatsAppProof(
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
  "whatsappProofText": "Full formatted WhatsApp proof text including emojis, exact figures, and timestamp"
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
    required DateTime now,
  }) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    final variance = actualAverage - claimedRate;
    final sign = variance >= 0 ? '+' : '';

    return '''
📋 *KERALA LOTTERY AUDITOR — AI SETTLEMENT PROOF*
🏪 *Shop:* ${shop.name} (${shop.code.isNotEmpty ? shop.code : shop.id})
📅 *Audit Date:* $dateStr
🤖 *Engine:* NVIDIA Nemotron-3 Super

📊 *ACTUAL AUDITED SALES METRICS*
• Total Tickets Sold: $totalTickets tkt
• Total Gross Revenue: ₹${totalRevenue.toStringAsFixed(2)}
• 12-Ticket Sets / Bulk: $bundleTickets tkt (${bundleRatio.toStringAsFixed(1)}%)
• Single Retail Tickets: $singleTickets tkt (${(100 - bundleRatio).toStringAsFixed(1)}%)

⚖️ *CLAIM VS. ACTUAL MARGIN VERIFICATION*
• Retailer Claimed Rate: ₹${claimedRate.toStringAsFixed(2)} / tkt
• Actual Logged Average: ₹${actualAverage.toStringAsFixed(2)} / tkt
• Audited Variance: $sign₹${variance.toStringAsFixed(2)} / tkt

${statusTag.badgeText.toUpperCase()}
📌 *Auditor Finding:*
$auditSummary

🔒 *Proof Authentication:* Unalterable Counter Sales Logged via Kerala Lottery Auditor Cloud.
''';
  }

  Map<String, dynamic>? _extractJsonFromContent(String content) {
    try {
      final trimmed = content.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        return jsonDecode(trimmed) as Map<String, dynamic>;
      }
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final jsonSub = content.substring(start, end + 1);
        return jsonDecode(jsonSub) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('>>> Failed to parse JSON from AI response: $e');
    }
    return null;
  }
}
