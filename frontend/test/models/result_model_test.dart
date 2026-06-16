// Unit test cho MyResultModel.fromJson (2026-06-16).
// Đặc biệt: final_score đến từ BE dạng string/number → parse double an toàn.
import 'package:flutter_test/flutter_test.dart';
import 'package:ptit_contest/core/models/result.dart';

void main() {
  group('MyResultModel.fromJson', () {
    test('final_score dạng string "95.50" → 95.5 double', () {
      final r = MyResultModel.fromJson({
        'contest_id': 5,
        'contest_title': 'Thuật toán',
        'contest_slug': 'thuat-toan',
        'entry_id': 9,
        'final_score': '95.50',
        'rank_no': 1,
        'award_title': 'Giải Nhất',
        'published_at': '2026-06-15T10:00:00Z',
      });

      expect(r.contestId, 5);
      expect(r.finalScore, 95.5);
      expect(r.rankNo, 1);
      expect(r.awardTitle, 'Giải Nhất');
      expect(r.publishedAt, DateTime.parse('2026-06-15T10:00:00Z'));
    });

    test('final_score / rank_no null → null (chưa có kết quả)', () {
      final r = MyResultModel.fromJson({
        'contest_id': 5,
        'contest_title': 'X',
        'contest_slug': 'x',
        'entry_id': 9,
        'final_score': null,
        'rank_no': null,
        'award_title': null,
        'published_at': '2026-06-15T10:00:00Z',
      });

      expect(r.finalScore, isNull);
      expect(r.rankNo, isNull);
      expect(r.awardTitle, isNull);
    });
  });
}
