import 'package:flutter/material.dart';

/// 3 Simple UI Status Tags as specified by user:
/// 🟢 Matches: Math and ticket-mix match claimed average perfectly.
/// 🟡 Close Enough: Slight difference between claim and math, but within normal daily limits.
/// 🔴 Mismatch: Shopkeeper claims low earnings, but high bundle sales prove average should be much higher.
enum AiStatusTag {
  matches,
  closeEnough,
  mismatch;

  String get label {
    switch (this) {
      case AiStatusTag.matches:
        return 'Matches';
      case AiStatusTag.closeEnough:
        return 'Close Enough';
      case AiStatusTag.mismatch:
        return 'Mismatch';
    }
  }

  String get emoji {
    switch (this) {
      case AiStatusTag.matches:
        return '🟢';
      case AiStatusTag.closeEnough:
        return '🟡';
      case AiStatusTag.mismatch:
        return '🔴';
    }
  }

  String get badgeText => '$emoji $label';

  Color get color {
    switch (this) {
      case AiStatusTag.matches:
        return const Color(0xFF10B981); // Emerald
      case AiStatusTag.closeEnough:
        return const Color(0xFFF59E0B); // Amber
      case AiStatusTag.mismatch:
        return const Color(0xFFEF4444); // Crimson Rose
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AiStatusTag.matches:
        return const Color(0xFF10B981).withValues(alpha: 0.15);
      case AiStatusTag.closeEnough:
        return const Color(0xFFF59E0B).withValues(alpha: 0.15);
      case AiStatusTag.mismatch:
        return const Color(0xFFEF4444).withValues(alpha: 0.15);
    }
  }

  static AiStatusTag fromString(String? value) {
    if (value == null) return AiStatusTag.matches;
    final lower = value.trim().toLowerCase();
    if (lower.contains('mismatch') || lower.contains('flag')) {
      return AiStatusTag.mismatch;
    }
    if (lower.contains('close') || lower.contains('enough') || lower.contains('review')) {
      return AiStatusTag.closeEnough;
    }
    return AiStatusTag.matches;
  }
}

/// Detailed AI Audit Benchmark Result for a single shop
class ShopAiBenchmark {
  final String shopId;
  final String shopName;
  final String shopCode;
  final int totalTickets;
  final double totalRevenue;
  final double actualAveragePrice;
  final double claimedAveragePrice;
  final int bundleTicketsCount; // 12-ticket sets & bulk
  final int singleTicketsCount; // single tickets
  final double bundleRatioPercentage;
  final double singleRatioPercentage;
  final AiStatusTag statusTag;
  final String auditSummary;
  final String ticketMixAnalysis;
  final String habitTrackingAnalysis;
  final String whatsappProofText;
  final DateTime auditedAt;
  final String modelUsed;

  const ShopAiBenchmark({
    required this.shopId,
    required this.shopName,
    required this.shopCode,
    required this.totalTickets,
    required this.totalRevenue,
    required this.actualAveragePrice,
    required this.claimedAveragePrice,
    required this.bundleTicketsCount,
    required this.singleTicketsCount,
    required this.bundleRatioPercentage,
    required this.singleRatioPercentage,
    required this.statusTag,
    required this.auditSummary,
    required this.ticketMixAnalysis,
    required this.habitTrackingAnalysis,
    required this.whatsappProofText,
    required this.auditedAt,
    required this.modelUsed,
  });

  double get variance => actualAveragePrice - claimedAveragePrice;

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'shopCode': shopCode,
      'totalTickets': totalTickets,
      'totalRevenue': totalRevenue,
      'actualAveragePrice': actualAveragePrice,
      'claimedAveragePrice': claimedAveragePrice,
      'bundleTicketsCount': bundleTicketsCount,
      'singleTicketsCount': singleTicketsCount,
      'bundleRatioPercentage': bundleRatioPercentage,
      'singleRatioPercentage': singleRatioPercentage,
      'statusTag': statusTag.name,
      'auditSummary': auditSummary,
      'ticketMixAnalysis': ticketMixAnalysis,
      'habitTrackingAnalysis': habitTrackingAnalysis,
      'whatsappProofText': whatsappProofText,
      'auditedAt': auditedAt.toIso8601String(),
      'modelUsed': modelUsed,
    };
  }

  factory ShopAiBenchmark.fromJson(Map<String, dynamic> json) {
    return ShopAiBenchmark(
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      shopCode: json['shopCode'] as String? ?? '',
      totalTickets: json['totalTickets'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      actualAveragePrice:
          (json['actualAveragePrice'] as num?)?.toDouble() ?? 0.0,
      claimedAveragePrice:
          (json['claimedAveragePrice'] as num?)?.toDouble() ?? 47.20,
      bundleTicketsCount: json['bundleTicketsCount'] as int? ?? 0,
      singleTicketsCount: json['singleTicketsCount'] as int? ?? 0,
      bundleRatioPercentage:
          (json['bundleRatioPercentage'] as num?)?.toDouble() ?? 0.0,
      singleRatioPercentage:
          (json['singleRatioPercentage'] as num?)?.toDouble() ?? 0.0,
      statusTag: AiStatusTag.fromString(json['statusTag'] as String?),
      auditSummary: json['auditSummary'] as String? ?? '',
      ticketMixAnalysis: json['ticketMixAnalysis'] as String? ?? '',
      habitTrackingAnalysis: json['habitTrackingAnalysis'] as String? ?? '',
      whatsappProofText: json['whatsappProofText'] as String? ?? '',
      auditedAt: json['auditedAt'] != null
          ? DateTime.parse(json['auditedAt'] as String)
          : DateTime.now(),
      modelUsed: json['modelUsed'] as String? ?? 'nvidia/nemotron-3-super-120b-a12b',
    );
  }
}

/// Network Trust Matrix Summary across all shops
class NetworkTrustMatrixSummary {
  final int totalShops;
  final int verifiedMatchesCount;
  final int closeEnoughCount;
  final int mismatchCount;
  final double trustIntegrityPercentage;
  final double averageNetworkTicketPrice;
  final double averageNetworkBundleRatio;

  const NetworkTrustMatrixSummary({
    required this.totalShops,
    required this.verifiedMatchesCount,
    required this.closeEnoughCount,
    required this.mismatchCount,
    required this.trustIntegrityPercentage,
    required this.averageNetworkTicketPrice,
    required this.averageNetworkBundleRatio,
  });

  factory NetworkTrustMatrixSummary.fromReports(List<ShopAiBenchmark> reports) {
    if (reports.isEmpty) {
      return const NetworkTrustMatrixSummary(
        totalShops: 0,
        verifiedMatchesCount: 0,
        closeEnoughCount: 0,
        mismatchCount: 0,
        trustIntegrityPercentage: 100.0,
        averageNetworkTicketPrice: 0.0,
        averageNetworkBundleRatio: 0.0,
      );
    }

    final total = reports.length;
    final matches = reports.where((r) => r.statusTag == AiStatusTag.matches).length;
    final close = reports.where((r) => r.statusTag == AiStatusTag.closeEnough).length;
    final mismatch = reports.where((r) => r.statusTag == AiStatusTag.mismatch).length;

    final integrity = ((matches + (close * 0.75)) / total) * 100.0;

    final totalTickets = reports.fold(0, (sum, r) => sum + r.totalTickets);
    final totalRevenue = reports.fold(0.0, (sum, r) => sum + r.totalRevenue);
    final totalBundles = reports.fold(0, (sum, r) => sum + r.bundleTicketsCount);

    final avgTicketPrice = totalTickets > 0 ? totalRevenue / totalTickets : 0.0;
    final avgBundleRatio = totalTickets > 0 ? (totalBundles / totalTickets) * 100.0 : 0.0;

    return NetworkTrustMatrixSummary(
      totalShops: total,
      verifiedMatchesCount: matches,
      closeEnoughCount: close,
      mismatchCount: mismatch,
      trustIntegrityPercentage: integrity.clamp(0.0, 100.0),
      averageNetworkTicketPrice: avgTicketPrice,
      averageNetworkBundleRatio: avgBundleRatio,
    );
  }
}

/// Cloud-stored configuration for NVIDIA Nemotron AI
class AiConfig {
  final String apiKey;
  final String modelName;
  final String endpointUrl;
  final double defaultClaimedRate;
  final DateTime updatedAt;

  const AiConfig({
    this.apiKey = '',
    this.modelName = 'nvidia/nemotron-3-super-120b-a12b',
    this.endpointUrl = 'https://integrate.api.nvidia.com/v1/chat/completions',
    this.defaultClaimedRate = 47.20,
    required this.updatedAt,
  });

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  AiConfig copyWith({
    String? apiKey,
    String? modelName,
    String? endpointUrl,
    double? defaultClaimedRate,
    DateTime? updatedAt,
  }) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      defaultClaimedRate: defaultClaimedRate ?? this.defaultClaimedRate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'modelName': modelName,
      'endpointUrl': endpointUrl,
      'defaultClaimedRate': defaultClaimedRate,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      apiKey: json['apiKey'] as String? ?? '',
      modelName: json['modelName'] as String? ?? 'nvidia/nemotron-3-super-120b-a12b',
      endpointUrl: json['endpointUrl'] as String? ??
          'https://integrate.api.nvidia.com/v1/chat/completions',
      defaultClaimedRate:
          (json['defaultClaimedRate'] as num?)?.toDouble() ?? 47.20,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
