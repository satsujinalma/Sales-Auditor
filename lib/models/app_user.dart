enum UserRole {
  shopkeeper,
  admin,
}

class AppUser {
  final String id;
  final String phoneNumber;
  final String name;
  final UserRole role;
  final String? shopId;
  final bool isProfileComplete;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.name = '',
    this.role = UserRole.shopkeeper,
    this.shopId,
    this.isProfileComplete = false,
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    UserRole? role,
    String? shopId,
    bool? isProfileComplete,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'role': role.name,
      'shopId': shopId,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String? ?? '',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.shopkeeper,
      shopId: json['shopId'] as String?,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
