import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/time/time_service.dart';
import 'package:one_day/main.dart';

void main() {
  testWidgets('녹음, 캘린더, 설정 화면이 전환되고 값이 즉시 반영된다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      OneDayApp(timeService: FixedTimeService(DateTime(2026, 10, 2, 7, 30))),
    );
    expect(find.text('논리적 오늘 · 2026년 10월 2일 금요일'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('오늘의 보관함'), 180);
    expect(find.text('오늘의 보관함'), findsOneWidget);

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.text('하루 전환 시각'), findsOneWidget);
    expect(find.text('1일'), findsOneWidget);
    await tester.tap(find.text('04:00'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('09:00'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('09:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('논리적 오늘 · 2026년 10월 1일 목요일'), findsOneWidget);

    await tester.tap(find.text('캘린더'));
    await tester.pumpAndSettle();
    expect(find.text('그날의 일기'), findsOneWidget);
    expect(find.text('수정'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar-day-5')));
    await tester.pumpAndSettle();
    expect(find.text('읽기 전용'), findsOneWidget);
    expect(find.text('수정'), findsNothing);
  });
}
