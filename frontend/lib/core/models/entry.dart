class EntryModel {
  final int entryId;
  final int contestId;
  final String entryType;
  final int? studentId;
  final int? teamId;
  final String registrationStatus;
  final String participantStatus;
  final String? registrationNote;
  final DateTime createdAt;

  EntryModel({
    required this.entryId,
    required this.contestId,
    required this.entryType,
    this.studentId,
    this.teamId,
    required this.registrationStatus,
    required this.participantStatus,
    this.registrationNote,
    required this.createdAt,
  });

  factory EntryModel.fromJson(Map<String, dynamic> j) => EntryModel(
        entryId: j['entry_id'],
        contestId: j['contest_id'],
        entryType: j['entry_type'],
        studentId: j['student_id'],
        teamId: j['team_id'],
        registrationStatus: j['registration_status'],
        participantStatus: j['participant_status'],
        registrationNote: j['registration_note'],
        createdAt: DateTime.parse(j['created_at']),
      );

  bool get isApproved => registrationStatus == 'APPROVED';
  bool get isPending => registrationStatus == 'PENDING';
  bool get isRejected => registrationStatus == 'REJECTED';
  bool get isCancelled => registrationStatus == 'CANCELLED';
}
