class SubmissionVersionModel {
  final int submissionVersionId;
  final int submissionId;
  final int versionNo;
  final String? title;
  final String? externalLink;
  final String? textAnswer;
  final String? note;
  final DateTime submittedAt;

  SubmissionVersionModel({
    required this.submissionVersionId,
    required this.submissionId,
    required this.versionNo,
    this.title,
    this.externalLink,
    this.textAnswer,
    this.note,
    required this.submittedAt,
  });

  factory SubmissionVersionModel.fromJson(Map<String, dynamic> j) =>
      SubmissionVersionModel(
        submissionVersionId: j['submission_version_id'],
        submissionId: j['submission_id'],
        versionNo: j['version_no'],
        title: j['title'],
        externalLink: j['external_link'],
        textAnswer: j['text_answer'],
        note: j['note'],
        submittedAt: DateTime.parse(j['submitted_at']),
      );
}

class SubmissionDetail {
  final int submissionId;
  final int roundId;
  final int entryId;
  final int currentVersionNo;
  final String status;
  final bool isLocked;
  final DateTime? submittedAt;
  final List<SubmissionVersionModel> versions;

  SubmissionDetail({
    required this.submissionId,
    required this.roundId,
    required this.entryId,
    required this.currentVersionNo,
    required this.status,
    required this.isLocked,
    this.submittedAt,
    required this.versions,
  });

  factory SubmissionDetail.fromJson(Map<String, dynamic> j) => SubmissionDetail(
        submissionId: j['submission_id'],
        roundId: j['round_id'],
        entryId: j['entry_id'],
        currentVersionNo: j['current_version_no'],
        status: j['status'],
        isLocked: j['is_locked'],
        submittedAt: j['submitted_at'] != null ? DateTime.parse(j['submitted_at']) : null,
        versions: (j['versions'] as List? ?? [])
            .map((v) => SubmissionVersionModel.fromJson(v))
            .toList(),
      );
}
