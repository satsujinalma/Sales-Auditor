import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ai_benchmark_models.dart';
import '../../models/daily_sales_summary.dart';
import '../../models/pricing_config.dart';
import '../../models/shop_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/ai_benchmark_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';

class AiBenchmarkView extends StatefulWidget {
  const AiBenchmarkView({super.key});

  @override
  State<AiBenchmarkView> createState() => _AiBenchmarkViewState();
}

class _AiBenchmarkViewState extends State<AiBenchmarkView> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  final NumberFormat _volumeFormat = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    AiBenchmarkProvider? aiProvider;
    try {
      aiProvider = context.watch<AiBenchmarkProvider>();
    } catch (_) {
      aiProvider = null;
    }

    if (aiProvider == null) {
      return const Center(
        child: Text(
          'AI Benchmark Provider is not available',
          style: TextStyle(color: LiquidGlassColors.textSecondary),
        ),
      );
    }

    final benchmarkProvider = aiProvider;
    final adminProvider = context.watch<AdminProvider>();
    final shops = adminProvider.shops;
    final summaries = adminProvider.allShopSummaries;
    final matrix = benchmarkProvider.trustMatrix;
    final reports = benchmarkProvider.reports;

    return RefreshIndicator(
      color: LiquidGlassColors.accentEmerald,
      backgroundColor: Colors.white,
      onRefresh: () async {
        await benchmarkProvider.runFullNetworkAudit(
          shops: shops,
          summaries: summaries,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 1. Intelligence Hub Header & Model Info
          _buildNemotronBrandHeader(context, benchmarkProvider, shops, summaries),

          const SizedBox(height: 14),

          // 2. Network Trust Matrix
          _buildNetworkTrustMatrix(context, matrix, benchmarkProvider.isAuditing),

          const SizedBox(height: 16),

          // 3. The Core Value Table: Weekly AI Shop Analyzer
          _buildWeeklyAiShopAnalyzerTable(context, benchmarkProvider, shops, summaries),

          const SizedBox(height: 18),

          // Section Title: Shop-by-Shop AI Cards
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  size: 14,
                  color: LiquidGlassColors.accentViolet,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SHOP-BY-SHOP AI AUDIT CARDS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: LiquidGlassColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.glassFillLight,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: LiquidGlassColors.glassBorderLight),
                ),
                child: Text(
                  '${reports.length} of ${shops.length} Analyzed',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: LiquidGlassColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. Shop-by-Shop AI Cards List
          if (reports.isEmpty && benchmarkProvider.isAuditing)
            _buildLoadingIndicator()
          else if (reports.isEmpty)
            _buildEmptyState(context, benchmarkProvider, shops, summaries)
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildShopAiCard(
                  context,
                  report,
                  benchmarkProvider,
                  adminProvider,
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  // ==================== 1. BRAND HEADER & AI ENGINE STATUS ====================

  Widget _buildNemotronBrandHeader(
    BuildContext context,
    AiBenchmarkProvider aiProvider,
    List<Shop> shops,
    Map<String, DailySalesSummary> summaries,
  ) {
    return LiquidGlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: Border.all(
        color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: LiquidGlassColors.accentEmerald,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'NVIDIA NEMOTRON AI',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: LiquidGlassColors.accentEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Cloud Synced • 3-Step Math & Mix Audit',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: LiquidGlassColors.textSecondary.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Cloud Database AI Key',
            icon: const Icon(
              Icons.key_rounded,
              size: 15,
              color: LiquidGlassColors.textMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            splashRadius: 14,
            onPressed: () => _showAiConfigDialog(context, aiProvider),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 30,
            child: ElevatedButton.icon(
              onPressed: aiProvider.isAuditing
                  ? null
                  : () {
                      aiProvider.runFullNetworkAudit(
                        shops: shops,
                        summaries: summaries,
                      );
                    },
              icon: aiProvider.isAuditing
                  ? const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 12),
              label: Text(
                aiProvider.isAuditing ? 'AUDITING...' : 'RUN AUDIT',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LiquidGlassColors.accentEmerald,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2. NETWORK TRUST MATRIX ====================

  Widget _buildNetworkTrustMatrix(
    BuildContext context,
    NetworkTrustMatrixSummary matrix,
    bool isAuditing,
  ) {
    final integrityScore = matrix.trustIntegrityPercentage.toStringAsFixed(0);

    return LiquidGlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                size: 14,
                color: LiquidGlassColors.accentCyan,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'NETWORK TRUST MATRIX',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: LiquidGlassColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$integrityScore% TRUST INTEGRITY',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: LiquidGlassColors.accentEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactTrustChip(
                  label: 'TOTAL',
                  value: '${matrix.totalShops}',
                  color: LiquidGlassColors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildCompactTrustChip(
                  label: 'MATCH',
                  value: '${matrix.verifiedMatchesCount}',
                  dotColor: const Color(0xFF10B981),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildCompactTrustChip(
                  label: 'CLOSE',
                  value: '${matrix.closeEnoughCount}',
                  dotColor: const Color(0xFFF59E0B),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildCompactTrustChip(
                  label: 'MISMATCH',
                  value: '${matrix.mismatchCount}',
                  dotColor: const Color(0xFFEF4444),
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTrustChip({
    required String label,
    required String value,
    required Color color,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: LiquidGlassColors.glassFillLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dotColor != null
              ? dotColor.withValues(alpha: 0.3)
              : LiquidGlassColors.glassBorderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: LiquidGlassColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 3. WEEKLY AI SHOP ANALYZER TABLE ====================

  Widget _buildWeeklyAiShopAnalyzerTable(
    BuildContext context,
    AiBenchmarkProvider aiProvider,
    List<Shop> shops,
    Map<String, DailySalesSummary> summaries,
  ) {
    final reports = aiProvider.reports;

    return LiquidGlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  size: 15,
                  color: LiquidGlassColors.accentCyan,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY AI SHOP ANALYZER',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Distributor Audit Ranking & Claim vs. Actual Comparison',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: LiquidGlassColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal scrolling data table for complete clarity
          if (reports.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: LiquidGlassColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'No network audit run yet today • Tap "RUN AUDIT" above',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LiquidGlassColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 680),
                child: DataTable(
                  headingRowHeight: 34,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  horizontalMargin: 8,
                  columnSpacing: 12,
                  headingTextStyle: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: LiquidGlassColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                  headingRowColor: WidgetStateProperty.all(
                    LiquidGlassColors.glassFillLight,
                  ),
                  columns: const [
                    DataColumn(label: Text('Shop Name')),
                    DataColumn(label: Text('Weekly Volume')),
                    DataColumn(label: Text('Claim vs. Actual')),
                    DataColumn(label: Text('AI Status Tag')),
                    DataColumn(label: Text('AI Audit Summary')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: reports.map((report) {
                    return _buildDataTableRow(context, report, aiProvider);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildDataTableRow(
    BuildContext context,
    ShopAiBenchmark report,
    AiBenchmarkProvider aiProvider,
  ) {
    return DataRow(
      cells: [
        // 1. Shop Name
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.shopName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: LiquidGlassColors.textPrimary,
                ),
              ),
              if (report.shopCode.isNotEmpty)
                Text(
                  'Code: ${report.shopCode}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: LiquidGlassColors.accentViolet,
                  ),
                ),
            ],
          ),
        ),

        // 2. Volume
        DataCell(
          Text(
            '${_volumeFormat.format(report.totalTickets)} tkt',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LiquidGlassColors.textPrimary,
            ),
          ),
        ),

        // 3. Claim vs Actual
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Claim: ${_currencyFormat.format(report.claimedAveragePrice)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassColors.textSecondary,
                ),
              ),
              Text(
                'Actual: ${_currencyFormat.format(report.actualAveragePrice)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: report.statusTag == AiStatusTag.mismatch
                      ? LiquidGlassColors.accentRose
                      : LiquidGlassColors.accentEmerald,
                ),
              ),
            ],
          ),
        ),

        // 4. AI Status Tag
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: report.statusTag.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: report.statusTag.color.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              report.statusTag.badgeText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: report.statusTag.color,
              ),
            ),
          ),
        ),

        // 5. AI Audit Summary
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              report.auditSummary,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: LiquidGlassColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 6. Action
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'View Breakdown',
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: LiquidGlassColors.accentCyan,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: LiquidGlassColors.glassFillLight,
                  padding: const EdgeInsets.all(6),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _showBreakdownModal(context, report),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Send WhatsApp Proof',
                icon: const Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: LiquidGlassColors.accentEmerald,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: LiquidGlassColors.accentEmerald.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(6),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _showWhatsAppProofModal(context, report, aiProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 4. SHOP-BY-SHOP DETAILED AI CARDS ====================

  Widget _buildShopAiCard(
    BuildContext context,
    ShopAiBenchmark report,
    AiBenchmarkProvider aiProvider,
    AdminProvider adminProvider,
  ) {
    final bundleRatio = report.bundleRatioPercentage;
    final singleRatio = report.singleRatioPercentage;

    return LiquidGlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      border: Border.all(
        color: report.statusTag.color.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Shop Name, Code & Status Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        report.shopName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: LiquidGlassColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (report.shopCode.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: LiquidGlassColors.accentViolet.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.shopCode,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: LiquidGlassColors.accentViolet,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: report.statusTag.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: report.statusTag.color.withValues(alpha: 0.40),
                  ),
                ),
                child: Text(
                  report.statusTag.badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: report.statusTag.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Compact 4-Cell Glass Metric Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: LiquidGlassColors.glassFillLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LiquidGlassColors.glassBorderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCell(
                    label: 'CLAIMED',
                    value: _currencyFormat.format(report.claimedAveragePrice),
                    color: LiquidGlassColors.textSecondary,
                    onTapEdit: () => _showEditClaimDialog(
                      context,
                      report,
                      aiProvider,
                      adminProvider,
                    ),
                  ),
                ),
                Container(width: 1, height: 22, color: LiquidGlassColors.glassBorderLight),
                Expanded(
                  child: _buildMetricCell(
                    label: 'ACTUAL',
                    value: _currencyFormat.format(report.actualAveragePrice),
                    color: report.statusTag == AiStatusTag.mismatch
                        ? LiquidGlassColors.accentRose
                        : LiquidGlassColors.accentEmerald,
                  ),
                ),
                Container(width: 1, height: 22, color: LiquidGlassColors.glassBorderLight),
                Expanded(
                  child: _buildMetricCell(
                    label: 'VARIANCE',
                    value: '${report.variance >= 0 ? '+' : ''}${_currencyFormat.format(report.variance)}',
                    color: report.statusTag == AiStatusTag.mismatch
                        ? LiquidGlassColors.accentRose
                        : LiquidGlassColors.accentEmerald,
                  ),
                ),
                Container(width: 1, height: 22, color: LiquidGlassColors.glassBorderLight),
                Expanded(
                  child: _buildMetricCell(
                    label: 'SETS MIX',
                    value: '${bundleRatio.toStringAsFixed(0)}%',
                    color: LiquidGlassColors.accentEmerald,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Ticket-Mix Ratio Bar (12-Ticket Sets vs Singles)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12-Ticket Sets: ${bundleRatio.toStringAsFixed(1)}% (${report.bundleTicketsCount} tkt)',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: LiquidGlassColors.accentEmerald,
                ),
              ),
              Text(
                'Singles: ${singleRatio.toStringAsFixed(1)}% (${report.singleTicketsCount} tkt)',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: LiquidGlassColors.accentCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    flex: bundleRatio.round().clamp(1, 100),
                    child: Container(
                      color: LiquidGlassColors.accentEmerald,
                    ),
                  ),
                  Expanded(
                    flex: (100 - bundleRatio.round()).clamp(1, 100),
                    child: Container(
                      color: LiquidGlassColors.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // AI Summary Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: LiquidGlassColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LiquidGlassColors.glassBorderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: LiquidGlassColors.accentViolet,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    report.auditSummary,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: LiquidGlassColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Bottom Action: One-Click WhatsApp Proof Exporter & Breakdown
          Row(
            children: [
              const Text(
                'Audited by NVDIA AI',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassColors.textMuted,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () => _showBreakdownModal(context, report),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LiquidGlassColors.accentViolet,
                    side: BorderSide(
                      color: LiquidGlassColors.accentViolet.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Breakdown',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  onPressed: () => _showWhatsAppProofModal(context, report, aiProvider),
                  icon: const Icon(Icons.send_rounded, size: 12),
                  label: const Text(
                    'WhatsApp Proof',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell({
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTapEdit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: LiquidGlassColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            if (onTapEdit != null) ...[
              const SizedBox(width: 2),
              InkWell(
                onTap: onTapEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 10,
                  color: LiquidGlassColors.accentViolet,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==================== 5. MODALS & DIALOGS ====================

  /// 3-Step Detailed Breakdown Modal
  void _showBreakdownModal(BuildContext context, ShopAiBenchmark report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiquidGlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: LiquidGlassColors.glassBorderGlow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI AUDIT BREAKDOWN: ${report.shopName}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: LiquidGlassColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: report.statusTag.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.statusTag.badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: report.statusTag.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step 1: Math Comparison
            _buildStepTile(
              stepNumber: '1',
              title: 'Math Comparison',
              description:
                  'Claimed Rate: ${_currencyFormat.format(report.claimedAveragePrice)} vs Actual Math: ${_currencyFormat.format(report.actualAveragePrice)} (${report.variance >= 0 ? '+' : ''}${_currencyFormat.format(report.variance)} variance).',
              icon: Icons.calculate_outlined,
              accentColor: LiquidGlassColors.accentCyan,
            ),
            const SizedBox(height: 10),

            // Step 2: Ticket-Mix Verification
            _buildStepTile(
              stepNumber: '2',
              title: 'Ticket-Mix Verification',
              description: report.ticketMixAnalysis,
              icon: Icons.confirmation_number_outlined,
              accentColor: LiquidGlassColors.accentEmerald,
            ),
            const SizedBox(height: 10),

            // Step 3: Habit Tracking
            _buildStepTile(
              stepNumber: '3',
              title: 'Habit Tracking',
              description: report.habitTrackingAnalysis,
              icon: Icons.history_toggle_off_rounded,
              accentColor: LiquidGlassColors.accentViolet,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: LiquidGlassButton(
                label: 'CLOSE BREAKDOWN',
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTile({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LiquidGlassColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiquidGlassColors.glassBorderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: LiquidGlassColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WhatsApp Proof Exporter Modal
  void _showWhatsAppProofModal(
    BuildContext context,
    ShopAiBenchmark report,
    AiBenchmarkProvider aiProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.send_rounded,
              size: 20,
              color: Color(0xFF25D366),
            ),
            const SizedBox(width: 8),
            const Text(
              'WhatsApp Proof Exporter',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'One-click settlement proof ready to send to retailer:',
                style: TextStyle(fontSize: 11.5, color: LiquidGlassColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LiquidGlassColors.glassBorderLight),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    report.whatsappProofText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: LiquidGlassColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await aiProvider.copyProofText(report);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proof copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 15),
            label: const Text('Copy Text'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await aiProvider.shareToWhatsApp(report);
            },
            icon: const Icon(Icons.share, size: 15),
            label: const Text('Send on WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Edit Retailer Claimed Rate Dialog
  void _showEditClaimDialog(
    BuildContext context,
    ShopAiBenchmark report,
    AiBenchmarkProvider aiProvider,
    AdminProvider adminProvider,
  ) {
    final controller = TextEditingController(
      text: report.claimedAveragePrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Edit Claimed Rate: ${report.shopName}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the average price per ticket claimed by the retailer:',
              style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                prefixText: '₹ ',
                labelText: 'Claimed Rate',
                filled: true,
                fillColor: LiquidGlassColors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRate = double.tryParse(controller.text.trim());
              if (newRate != null && newRate > 0) {
                Navigator.pop(ctx);
                final shop = adminProvider.shops.firstWhere(
                  (s) => s.id == report.shopId,
                  orElse: () => Shop(
                    id: report.shopId,
                    name: report.shopName,
                    location: '',
                    code: report.shopCode,
                    pricingConfig: const PricingConfig(),
                  ),
                );
                final summary = adminProvider.allShopSummaries[report.shopId] ??
                    DailySalesSummary(shopId: report.shopId, date: DateTime.now());

                await aiProvider.reAuditShop(
                  shop: shop,
                  summary: summary,
                  claimedRate: newRate,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LiquidGlassColors.accentViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Re-Audit'),
          ),
        ],
      ),
    );
  }

  /// NVIDIA AI Cloud API Key Configuration Dialog
  void _showAiConfigDialog(BuildContext context, AiBenchmarkProvider aiProvider) {
    final keyController = TextEditingController(text: aiProvider.config.apiKey);
    final modelController = TextEditingController(text: aiProvider.config.modelName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: LiquidGlassColors.accentEmerald),
            SizedBox(width: 8),
            Text(
              'NVIDIA AI Cloud Database Config',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The API key is securely saved in the Cloud Database (Firestore settings/ai_config) and accessible only to authenticated Admins.',
                style: TextStyle(fontSize: 11.5, color: LiquidGlassColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'NVIDIA API Key',
                  hintText: 'nvapi-...',
                  prefixIcon: const Icon(Icons.key, size: 18),
                  filled: true,
                  fillColor: LiquidGlassColors.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: 'Model Identifier',
                  hintText: 'nvidia/nemotron-3-super-120b-a12b',
                  prefixIcon: const Icon(Icons.smart_toy_outlined, size: 18),
                  filled: true,
                  fillColor: LiquidGlassColors.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await aiProvider.saveAiConfig(
                apiKey: keyController.text.trim(),
                modelName: modelController.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI Configuration saved to Cloud Database!'),
                    backgroundColor: LiquidGlassColors.accentEmerald,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LiquidGlassColors.accentEmerald,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save to Cloud'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: LiquidGlassColors.accentEmerald),
            const SizedBox(height: 14),
            Text(
              'Nemotron AI is analyzing ticket bundles and calculating averages...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LiquidGlassColors.textSecondary.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AiBenchmarkProvider aiProvider,
    List<Shop> shops,
    Map<String, DailySalesSummary> summaries,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: LiquidGlassColors.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiquidGlassColors.glassBorderLight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 26,
              color: LiquidGlassColors.accentViolet.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              '${shops.length} Retail Shops Awaiting AI Verification',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: LiquidGlassColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nemotron-3 Super audits 12-ticket bundle ratios, claimed margins & past patterns in real time.',
              style: TextStyle(
                fontSize: 10.5,
                color: LiquidGlassColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
