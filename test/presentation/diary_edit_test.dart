import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/data/diary_store.dart';
import 'package:one_day/main.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('논리적 당일 일기를 수정·저장하면 예외 없이 카드에 반영된다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final diaryStore = MemoryDiaryStore([
      Diary(date: DateTime(2026, 10, 2), title: '오늘 초안', body: '오늘 초안 본문'),
    ]);
    await tester.pumpWidget(
      OneDayApp(
        timeService: FakeTimeService(DateTime(2026, 10, 2, 7, 30)),
        settingsStore: MemorySettingsStore(),
        diaryStore: diaryStore,
        initialDiaries: await diaryStore.loadAll(),
      ),
    );

    await tester.tap(find.text('캘린더'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('수정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '고친 제목');
    await tester.enterText(find.byType(TextField).last, '고친 본문');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('고친 제목'), findsOneWidget);
    expect(find.text('고친 본문'), findsOneWidget);
    expect(diaryStore.saved['2026-10-02']!.body, '고친 본문');

    // 다시 열어도 저장된 내용이 편집 폼에 채워진다.
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '고친 제목'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
