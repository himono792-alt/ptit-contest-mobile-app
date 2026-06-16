// Test Pill: (1) logic factory Pill.status (pure) + (2) render label (widget).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptit_contest/core/widgets/pill.dart';

void main() {
  group('Pill.status() → PillKind mapping', () {
    test('các status thành công → success', () {
      for (final s in ['APPROVED', 'PUBLISHED', 'REG_OPEN', 'COMPLETED']) {
        expect(Pill.status(s).kind, PillKind.success, reason: s);
      }
    });

    test('các status chờ/đang diễn ra → warn', () {
      for (final s in ['PENDING', 'ONGOING', 'SUBMITTED', 'PROPOSED']) {
        expect(Pill.status(s).kind, PillKind.warn, reason: s);
      }
    });

    test('các status tiêu cực → danger', () {
      for (final s in ['CANCELLED', 'REJECTED', 'LOCKED']) {
        expect(Pill.status(s).kind, PillKind.danger, reason: s);
      }
    });

    test('status lạ → neutral', () {
      expect(Pill.status('XYZ').kind, PillKind.neutral);
    });
  });

  testWidgets('Pill render đúng label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Pill(label: 'APPROVED', kind: PillKind.success)),
      ),
    );
    expect(find.text('APPROVED'), findsOneWidget);
  });
}
