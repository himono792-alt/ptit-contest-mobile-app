class RoundModel {
  final int roundId;
  final int contestId;
  final int roundNo;
  final String roundName;
  final String roundType;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? submissionOpenAt;
  final DateTime? submissionCloseAt;
  final bool isEliminationRound;

  RoundModel({
    required this.roundId,
    required this.contestId,
    required this.roundNo,
    required this.roundName,
    required this.roundType,
    required this.startAt,
    required this.endAt,
    this.submissionOpenAt,
    this.submissionCloseAt,
    required this.isEliminationRound,
  });

  factory RoundModel.fromJson(Map<String, dynamic> j) => RoundModel(
        roundId: j['round_id'],
        contestId: j['contest_id'],
        roundNo: j['round_no'],
        roundName: j['round_name'],
        roundType: j['round_type'],
        startAt: DateTime.parse(j['start_at']),
        endAt: DateTime.parse(j['end_at']),
        submissionOpenAt: j['submission_open_at'] != null ? DateTime.parse(j['submission_open_at']) : null,
        submissionCloseAt: j['submission_close_at'] != null ? DateTime.parse(j['submission_close_at']) : null,
        isEliminationRound: j['is_elimination_round'] ?? false,
      );
}
