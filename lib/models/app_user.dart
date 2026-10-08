enum UserRole {
  shopkeeper,
  admin,
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class AppUser {
  final String id;
  final String phoneNumber;
  final String name;
  final UserRole role;
  final String? shopId;
  final String? shopName;
  final bool isApproved;
  final ApprovalStatus approvalStatus;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime? approvedAt;

  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.name = '',
    this.role = UserRole.shopkeeper,
    this.shopId,
    this.shopName,
    this.isApproved = false,
    this.approvalStatus = ApprovalStatus.pending,
    this.isProfileComplete = false,
    required this.createdAt,
    this.approvedAt,
  });

  AppUser copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    UserRole? role,
    String? shopId,
    String? shopName,
    bool? isApproved,
    ApprovalStatus? approvalStatus,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? approvedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      isApproved: isApproved ?? this.isApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'role': role.name,
      'shopId': shopId,
      'shopName': shopName,
      'isApproved': isApproved,
      'approvalStatus': approvalStatus.name,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = json['role'] == 'admin' ? UserRole.admin : UserRole.shopkeeper;
    
    ApprovalStatus parseStatus(String? statusStr, bool? approvedBool) {
      if (role == UserRole.admin) return ApprovalStatus.approved;
      if (statusStr == 'approved') return ApprovalStatus.approved;
      if (statusStr == 'rejected') return ApprovalStatus.rejected;
      if (statusStr == 'pending') return ApprovalStatus.pending;
      if (approvedBool == true) return ApprovalStatus.approved;
      return ApprovalStatus.pending;
    }

    final isApprovedVal = role == UserRole.admin || (json['isApproved'] as bool? ?? false);
    final status = parseStatus(json['approvalStatus'] as String?, isApprovedVal);

    return AppUser(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: role,
      shopId: json['shopId'] as String?,
      shopName: json['shopName'] as String?,
      isApproved: role == UserRole.admin ? true : (status == ApprovalStatus.approved),
      approvalStatus: status,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
    );
  }
}
