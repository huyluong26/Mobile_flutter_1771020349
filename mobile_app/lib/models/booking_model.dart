/// Court model
class Court {
  final int id;
  final String name;
  final double pricePerHour;
  final String? description;
  final bool isActive;

  Court({
    required this.id,
    required this.name,
    required this.pricePerHour,
    this.description,
    this.isActive = true,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? json['PricePerHour'] ?? 0)
          .toDouble(),
      description: json['description'] ?? json['Description'],
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pricePerHour': pricePerHour,
      'description': description,
      'isActive': isActive,
    };
  }
}

/// Booking model
class Booking {
  final int id;
  final int courtId;
  final String courtName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final bool isRecurring;
  final int memberId;
  final String memberName;

  Booking({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.isRecurring = false,
    required this.memberId,
    required this.memberName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? json['Id'] ?? 0,
      courtId: json['courtId'] ?? json['CourtId'] ?? 0,
      courtName: json['courtName'] ?? json['CourtName'] ?? '',
      startTime:
          DateTime.tryParse(
            (json['startTime'] ?? json['StartTime'] ?? '').toString(),
          ) ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(
            (json['endTime'] ?? json['EndTime'] ?? '').toString(),
          ) ??
          DateTime.now(),
      totalPrice: (json['totalPrice'] ?? json['TotalPrice'] ?? 0).toDouble(),
      status: _parseStatus(json['status'] ?? json['Status']),
      isRecurring: json['isRecurring'] ?? json['IsRecurring'] ?? false,
      memberId: json['memberId'] ?? json['MemberId'] ?? 0,
      memberName: json['memberName'] ?? json['MemberName'] ?? '',
    );
  }

  static String _parseStatus(dynamic status) {
    if (status is String) return status;
    if (status is int) {
      switch (status) {
        case 0:
          return 'PendingPayment';
        case 1:
          return 'Confirmed';
        case 2:
          return 'Cancelled';
        case 3:
          return 'Completed';
      }
    }
    return status?.toString() ?? 'Confirmed';
  }

  String get statusDisplay {
    switch (status) {
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Cancelled':
        return 'Đã hủy';
      case 'Completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  String get timeDisplay {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get dateDisplay {
    return '${startTime.day}/${startTime.month}/${startTime.year}';
  }
}
