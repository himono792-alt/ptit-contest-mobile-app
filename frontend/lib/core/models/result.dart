class MyResultModel {
  final int contestId;
  final String contestTitle;
  final String contestSlug;
  final int entryId;
  final double? finalScore;
  final int? rankNo;
  final String? awardTitle;
  final DateTime publishedAt;
  final String? certQrCode;

  MyResultModel({
    required this.contestId,
    required this.contestTitle,
    required this.contestSlug,
    required this.entryId,
    this.finalScore,
    this.rankNo,
    this.awardTitle,
    required this.publishedAt,
    this.certQrCode,
  });

  factory MyResultModel.fromJson(Map<String, dynamic> j) => MyResultModel(
        contestId: j['contest_id'],
        contestTitle: j['contest_title'],
        contestSlug: j['contest_slug'],
        entryId: j['entry_id'],
        finalScore: j['final_score'] != null ? double.tryParse(j['final_score'].toString()) : null,
        rankNo: j['rank_no'],
        awardTitle: j['award_title'],
        publishedAt: DateTime.parse(j['published_at']),
        certQrCode: j['cert_qr_code'] as String?,
      );
}
