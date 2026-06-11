import 'contest.dart';

class ContestDetail extends ContestSummary {
  final String? description;
  final String? rulesText;
  final String? awardText;
  final String? bannerUrl;
  final String? locationText;
  final int? teamMinMembers;
  final int? teamMaxMembers;
  final bool requiresSubmission;
  final int? proposedBy;
  final int createdBy;

  ContestDetail({
    required super.contestId,
    required super.slug,
    required super.title,
    required super.deliveryMode,
    required super.participationMode,
    required super.status,
    required super.startAt,
    required super.endAt,
    super.registrationOpenAt,
    super.registrationCloseAt,
    super.maxEntries,
    super.hostFacultyId,
    required super.isPublic,
    this.description,
    this.rulesText,
    this.awardText,
    this.bannerUrl,
    this.locationText,
    this.teamMinMembers,
    this.teamMaxMembers,
    required this.requiresSubmission,
    this.proposedBy,
    required this.createdBy,
  });

  factory ContestDetail.fromJson(Map<String, dynamic> j) => ContestDetail(
        contestId: j['contest_id'],
        slug: j['slug'],
        title: j['title'],
        deliveryMode: j['delivery_mode'],
        participationMode: j['participation_mode'],
        status: j['status'],
        startAt: DateTime.parse(j['start_at']),
        endAt: DateTime.parse(j['end_at']),
        registrationOpenAt: j['registration_open_at'] != null
            ? DateTime.parse(j['registration_open_at']) : null,
        registrationCloseAt: j['registration_close_at'] != null
            ? DateTime.parse(j['registration_close_at']) : null,
        maxEntries: j['max_entries'],
        hostFacultyId: j['host_faculty_id'],
        isPublic: j['is_public'],
        description: j['description'],
        rulesText: j['rules_text'],
        awardText: j['award_text'],
        bannerUrl: j['banner_url'],
        locationText: j['location_text'],
        teamMinMembers: j['team_min_members'],
        teamMaxMembers: j['team_max_members'],
        requiresSubmission: j['requires_submission'] ?? false,
        proposedBy: j['proposed_by'],
        createdBy: j['created_by'],
      );

  bool get isRegOpen => status == 'REG_OPEN';
  bool get isFinished => status == 'FINISHED';
  bool get isTeam => participationMode == 'TEAM';
}
