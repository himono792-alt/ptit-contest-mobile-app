/// Model phúc khảo kết quả (Result Appeal) — 2026-06-27.
class AppealModel {
  final int appealId;
  final int contestId;
  final int? roundId;
  final int entryId;
  final int submittedByStudentId;
  final String title;
  final String contentText;
  final String status; // PENDING / IN_REVIEW / ACCEPTED / REJECTED / CLOSED
  final String? responseText;
  final int? handledBy;
  final DateTime? handledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppealModel({
    required this.appealId,
    required this.contestId,
    this.roundId,
    required this.entryId,
    required this.submittedByStudentId,
    required this.title,
    required this.contentText,
    required this.status,
    this.responseText,
    this.handledBy,
    this.handledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppealModel.fromJson(Map<String, dynamic> j) => AppealModel(
        appealId: j['appeal_id'],
        contestId: j['contest_id'],
        roundId: j['round_id'],
        entryId: j['entry_id'],
        submittedByStudentId: j['submitted_by_student_id'],
        title: j['title'] ?? '',
        contentText: j['content_text'] ?? '',
        status: j['status'] ?? 'PENDING',
        responseText: j['response_text'] as String?,
        handledBy: j['handled_by'],
        handledAt: j['handled_at'] != null
            ? DateTime.parse(j['handled_at'])
            : null,
        createdAt: DateTime.parse(j['created_at']),
        updatedAt: DateTime.parse(j['updated_at']),
      );

  /// Nhãn tiếng Việt cho trạng thái.
  String get statusLabel => switch (status) {
        'PENDING' => 'Chờ xử lý',
        'IN_REVIEW' => 'Đang xem xét',
        'ACCEPTED' => 'Được chấp nhận',
        'REJECTED' => 'Bị từ chối',
        'CLOSED' => 'Đã đóng',
        _ => status,
      };

  bool get isOpen => status == 'PENDING' || status == 'IN_REVIEW';
}
