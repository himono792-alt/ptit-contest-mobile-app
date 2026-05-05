class ContestSummary {
  final int contestId;
  final String slug;
  final String title;
  final String deliveryMode;
  final String participationMode;
  final String status;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? registrationOpenAt;
  final DateTime? registrationCloseAt;
  final int? maxEntries;
  final int? hostFacultyId;
  final bool isPublic;

  ContestSummary({
    required this.contestId,
    required this.slug,
    required this.title,
    required this.deliveryMode,
    required this.participationMode,
    required this.status,
    required this.startAt,
    required this.endAt,
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.maxEntries,
    this.hostFacultyId,
    required this.isPublic,
  });

  factory ContestSummary.fromJson(Map<String, dynamic> json) => ContestSummary(
        contestId: json['contest_id'] as int,
        slug: json['slug'] as String,
        title: json['title'] as String,
        deliveryMode: json['delivery_mode'] as String,
        participationMode: json['participation_mode'] as String,
        status: json['status'] as String,
        startAt: DateTime.parse(json['start_at']),
        endAt: DateTime.parse(json['end_at']),
        registrationOpenAt: json['registration_open_at'] != null
            ? DateTime.parse(json['registration_open_at'])
            : null,
        registrationCloseAt: json['registration_close_at'] != null
            ? DateTime.parse(json['registration_close_at'])
            : null,
        maxEntries: json['max_entries'] as int?,
        hostFacultyId: json['host_faculty_id'] as int?,
        isPublic: json['is_public'] as bool,
      );
}

class ContestListResponse {
  final List<ContestSummary> items;
  final int total;
  final int page;
  final int size;

  ContestListResponse({required this.items, required this.total, required this.page, required this.size});

  factory ContestListResponse.fromJson(Map<String, dynamic> json) =>
      ContestListResponse(
        items: (json['items'] as List).map((e) => ContestSummary.fromJson(e)).toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        size: json['size'] as int,
      );
}
