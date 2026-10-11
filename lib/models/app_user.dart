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

  factory AppUser.fromJson(Map<String, dynamic> json, [String? docId]) {
    final roleStr = json['role']?.toString().toLowerCase();
    final role = roleStr == 'admin' ? UserRole.admin : UserRole.shopkeeper;

    ApprovalStatus parseStatus(dynamic statusVal, bool? approvedBool) {
      if (role == UserRole.admin) return ApprovalStatus.approved;
      final str = statusVal?.toString().toLowerCase();
      if (str == 'approved') return ApprovalStatus.approved;
      if (str == 'rejected') return ApprovalStatus.rejected;
      if (str == 'pending') return ApprovalStatus.pending;
      if (approvedBool == true) return ApprovalStatus.approved;
      return ApprovalStatus.pending;
    }

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        // Handle Firestore Timestamp dynamically
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    final isApprovedVal = role == UserRole.admin || (json['isApproved'] as bool? ?? false);
    final status = parseStatus(json['approvalStatus'], isApprovedVal);

    return AppUser(
      id: (json['id'] as String?)?.isNotEmpty == true
          ? json['id'] as String
          : (docId ?? ''),
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: role,
      shopId: json['shopId'] as String?,
      shopName: json['shopName'] as String?,
      isApproved: role == UserRole.admin ? true : (status == ApprovalStatus.approved),
      approvalStatus: status,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      approvedAt: json['approvedAt'] != null ? parseDate(json['approvedAt']) : null,
    );
  }
}
