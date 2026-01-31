/// Paged result for list APIs

/// Paged result for list APIs
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  int get totalPages => (totalCount / pageSize).ceil();

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}

/// Match history DTO
class MatchHistory {
  final int matchId;
  final String tournamentName;
  final DateTime? date;
  final String result;
  final String score;
  final String opponentName;

  MatchHistory({
    required this.matchId,
    required this.tournamentName,
    this.date,
    required this.result,
    required this.score,
    required this.opponentName,
  });

  factory MatchHistory.fromJson(Map<String, dynamic> json) {
    return MatchHistory(
      matchId: json['matchId'] ?? 0,
      tournamentName: json['tournamentName'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      result: json['result'] ?? '',
      score: json['score'] ?? '',
      opponentName: json['opponentName'] ?? '',
    );
  }
}
