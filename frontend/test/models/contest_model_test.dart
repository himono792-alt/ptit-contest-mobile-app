// Unit test cho parse model ContestSummary / ContestListResponse (2026-06-16).
// Pure Dart — không cần Flutter binding. Khóa hành vi fromJson + default values.
import 'package:flutter_test/flutter_test.dart';
import 'package:ptit_contest/core/models/contest.dart';

void main() {
  group('ContestSummary.fromJson', () {
    test('parse đầy đủ field', () {
      final c = ContestSummary.fromJson({
        'contest_id': 7,
        'slug': 'lap-trinh-2026',
        'title': 'Lập trình 2026',
        'delivery_mode': 'ONLINE',
        'participation_mode': 'INDIVIDUAL',
        'status': 'ONGOING',
        'start_at': '2026-06-01T00:00:00Z',
        'end_at': '2026-06-10T00:00:00Z',
        'registration_open_at': '2026-05-20T00:00:00Z',
        'registration_close_at': '2026-05-30T00:00:00Z',
        'max_entries': 100,
        'host_faculty_id': 3,
        'is_public': true,
        'entries_count': 12,
      });

      expect(c.contestId, 7);
      expect(c.slug, 'lap-trinh-2026');
      expect(c.status, 'ONGOING');
      expect(c.startAt, DateTime.parse('2026-06-01T00:00:00Z'));
      expect(c.maxEntries, 100);
      expect(c.isPublic, isTrue);
      expect(c.entriesCount, 12);
    });

    test('entries_count thiếu → mặc định 0; optional null', () {
      final c = ContestSummary.fromJson({
        'contest_id': 1,
        'slug': 's',
        'title': 't',
        'delivery_mode': 'OFFLINE',
        'participation_mode': 'TEAM',
        'status': 'DRAFT',
        'start_at': '2026-06-01T00:00:00Z',
        'end_at': '2026-06-10T00:00:00Z',
        'is_public': false,
      });

      expect(c.entriesCount, 0);
      expect(c.registrationOpenAt, isNull);
      expect(c.maxEntries, isNull);
      expect(c.isPublic, isFalse);
    });
  });

  group('ContestListResponse.fromJson', () {
    test('parse items + pagination', () {
      final r = ContestListResponse.fromJson({
        'items': [
          {
            'contest_id': 1,
            'slug': 'a',
            'title': 'A',
            'delivery_mode': 'ONLINE',
            'participation_mode': 'INDIVIDUAL',
            'status': 'ONGOING',
            'start_at': '2026-06-01T00:00:00Z',
            'end_at': '2026-06-10T00:00:00Z',
            'is_public': true,
          },
        ],
        'total': 1,
        'page': 1,
        'size': 20,
      });

      expect(r.items, hasLength(1));
      expect(r.items.first.slug, 'a');
      expect(r.total, 1);
      expect(r.size, 20);
    });
  });
}
