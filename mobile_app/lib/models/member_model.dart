/// Member model matching backend MemberDto
class Member {
  final int id;
  final String fullName;
  final String email;
  final DateTime joinDate;
  final double rankLevel;
  final bool isActive;
  final String? avatarUrl;
  final String tier; // Standard, Gold, Platinum
  final double walletBalance;
  final double totalSpent;

  Member({
    required this.id,
    required this.fullName,
    required this.email,
    required this.joinDate,
    this.rankLevel = 0.0,
    this.isActive = true,
    this.avatarUrl,
    this.tier = 'Standard',
    this.walletBalance = 0.0,
    this.totalSpent = 0.0,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? json['Id'] ?? 0,
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      joinDate:
          DateTime.tryParse(
            (json['joinDate'] ?? json['JoinDate'] ?? '').toString(),
          ) ??
          DateTime.now(),
      rankLevel: (json['rankLevel'] ?? json['RankLevel'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
      avatarUrl: json['avatarUrl'] ?? json['AvatarUrl'],
      tier: (json['tier'] ?? json['Tier'])?.toString() ?? 'Standard',
      walletBalance: (json['walletBalance'] ?? json['WalletBalance'] ?? 0)
          .toDouble(),
      totalSpent: (json['totalSpent'] ?? json['TotalSpent'] ?? 0).toDouble(),
    );
  }

  /// Get tier display name in Vietnamese
  String get tierDisplayName {
    switch (tier) {
      case 'Gold':
        return 'Vàng';
      case 'Platinum':
        return 'Bạch Kim';
      default:
        return 'Tiêu Chuẩn';
    }
  }
}
