import 'pricing_config.dart';

class Shop {
  final String id;
  final String name;
  final String location;
  final String code;
  final PricingConfig pricingConfig;
  final bool isActive;

  const Shop({
    required this.id,
    required this.name,
    required this.location,
    required this.code,
    required this.pricingConfig,
    this.isActive = true,
  });

  Shop copyWith({
    String? id,
    String? name,
    String? location,
    String? code,
    PricingConfig? pricingConfig,
    bool? isActive,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      code: code ?? this.code,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'code': code,
      'pricingConfig': pricingConfig.toJson(),
      'isActive': isActive,
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      code: json['code'] as String? ?? '',
      pricingConfig: json['pricingConfig'] != null
          ? PricingConfig.fromJson(
              json['pricingConfig'] as Map<String, dynamic>,
            )
          : const PricingConfig(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Pre-configured default shops (Empty by default; shops are created on user onboarding)
  static List<Shop> get defaultShops => const [];
}
