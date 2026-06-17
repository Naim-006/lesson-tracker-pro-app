import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lesson_tracker_pro/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LessonTrackerProApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
  });
}
