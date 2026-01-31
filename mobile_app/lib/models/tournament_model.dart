/// Tournament model
class Tournament {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final double entryFee;
  final double prizePool;
  final int participantCount;
  final String format;
  final bool isJoined;

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.status,
    this.entryFee = 0.0,
    this.prizePool = 0.0,
    this.participantCount = 0,
    this.format = 'Knockout',
    this.isJoined = false,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      status: _parseStatus(json['status']),
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      prizePool: (json['prizePool'] ?? 0).toDouble(),
      participantCount: json['participantCount'] ?? 0,
      format: _parseFormat(json['format']),
      isJoined: json['isJoined'] ?? json['IsJoined'] ?? false,
    );
  }

  // Handle both int (enum index) and string status
  static String _parseStatus(dynamic status) {
    if (status == null) return 'Upcoming';
    if (status is String) return status;
    if (status is int) {
      switch (status) {
        case 0:
          return 'Upcoming';
        case 1:
          return 'Ongoing';
        case 2:
          return 'Completed';
        case 3:
          return 'Cancelled';
        default:
          return 'Upcoming';
      }
    }
    return status.toString();
  }

  // Handle both int (enum index) and string format
  static String _parseFormat(dynamic format) {
    if (format == null) return 'Knockout';
    if (format is String) return format;
    if (format is int) {
      switch (format) {
        case 0:
          return 'Knockout';
        case 1:
          return 'RoundRobin';
        default:
          return 'Knockout';
      }
    }
    return format.toString();
  }

  String get statusDisplay {
    switch (status) {
      case 'Upcoming':
      case 'Open':
      case 'Registering':
        return 'Đang mở';
      case 'Ongoing':
      case 'DrawCompleted':
        return 'Đang diễn ra';
      case 'Completed':
      case 'Finished':
        return 'Đã kết thúc';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get formatDisplay {
    switch (format) {
      case 'Knockout':
        return 'Loại trực tiếp';
      case 'RoundRobin':
        return 'Vòng tròn';
      default:
        return format;
    }
  }

  String get dateDisplay {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }
}
