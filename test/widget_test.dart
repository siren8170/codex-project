import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/data/diary_store.dart';
import 'package:one_day/main.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('녹음, 캘린더, 설정 화면이 전환되고 값이 즉시 반영된다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final diaryStore = MemoryDiaryStore([
      Diary(date: DateTime(2026, 10, 1), title: '10월 1일 일기', body: '오늘 본문'),
      Diary(date: DateTime(2026, 10, 5), title: '10월 5일 일기', body: '5일 본문'),
    ]);
    await tester.pumpWidget(
      OneDayApp(
        timeService: FakeTimeService(DateTime(2026, 10, 2, 7, 30)),
        settingsStore: MemorySettingsStore(),
        diaryStore: diaryStore,
        initialDiaries: await diaryStore.loadAll(),
      ),
    );
    expect(find.text('논리적 오늘 · 2026년 10월 2일 금요일'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('녹음 보관함'), 180);
    expect(find.text('녹음 보관함'), findsOneWidget);

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
