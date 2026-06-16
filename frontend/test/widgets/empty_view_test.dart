// Test EmptyView: render title/subtitle/action + toggle decoratedIcon.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptit_contest/core/widgets/empty_view.dart';

void main() {
  testWidgets('render title + subtitle + action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            icon: Icons.inbox_outlined,
            title: 'Không có dữ liệu',
            subtitle: 'Hãy thử lại sau',
            action: FilledButton(onPressed: () {}, child: const Text('Tạo mới')),
          ),
        ),
      ),
    );

    expect(find.text('Không có dữ liệu'), findsOneWidget);
    expect(find.text('Hãy thử lại sau'), findsOneWidget);
    expect(find.text('Tạo mới'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('không subtitle/action → chỉ có title + icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyView(icon: Icons.notifications_none, title: 'Trống'),
        ),
      ),
    );

    expect(find.text('Trống'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('decoratedIcon=false vẫn render icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyView(
            icon: Icons.description_outlined,
            title: 'x',
            decoratedIcon: false,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });
}
