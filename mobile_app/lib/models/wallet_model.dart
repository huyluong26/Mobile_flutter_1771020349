/// Wallet Transaction model
class WalletTransaction {
  final int id;
  final double amount;
  final String type; // Deposit, Spend, Refund
  final String status; // Pending, Completed, Rejected
  final DateTime createdAt;
  final String? description;
  final String? relatedId;
  final String? memberName;
  final String? proofImageUrl;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.description,
    this.relatedId,
    this.memberName,
    this.proofImageUrl,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? json['Id'] ?? 0,
      amount: (json['amount'] ?? json['Amount'] ?? 0).toDouble(),
      type: _parseType(json['type'] ?? json['Type']),
      status: _parseStatus(json['status'] ?? json['Status']),
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      description: json['description'] ?? json['Description'],
      relatedId: (json['relatedId'] ?? json['RelatedId'])?.toString(),
      memberName: json['memberName'] ?? json['MemberName'],
      proofImageUrl: json['proofImageUrl'] ?? json['ProofImageUrl'],
    );
  }

  static String _parseType(dynamic value) {
    if (value is String) return value;
    if (value is int) {
      switch (value) {
        case 0:
          return 'Deposit';
        case 1:
          return 'Withdraw';
        case 2:
          return 'Payment';
        case 3:
          return 'Refund';
        case 4:
          return 'Reward';
      }
    }
    return value?.toString() ?? 'Payment';
  }

  static String _parseStatus(dynamic value) {
    if (value is String) return value;
    if (value is int) {
      switch (value) {
        case 0:
          return 'Pending';
        case 1:
          return 'Completed';
        case 2:
          return 'Rejected';
        case 3:
          return 'Failed';
      }
    }
    return value?.toString() ?? 'Pending';
  }

  String get typeDisplay {
    switch (type) {
      case 'Deposit':
        return 'Nạp tiền';
      case 'Spend':
        return 'Chi tiêu';
      case 'Refund':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'Pending':
        return 'Chờ duyệt';
      case 'Completed':
        return 'Hoàn thành';
      case 'Rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  bool get isPending => status == 'Pending';
  bool get isCompleted => status == 'Completed';
}
