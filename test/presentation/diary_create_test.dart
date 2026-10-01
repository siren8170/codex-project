import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/data/settings_store.dart';
import 'package:one_day/main.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeTimeService clock;
  late FakeRecorder recorder;
  late MemoryRecordingStore recordings;
  late MemoryDiaryStore diaries;
  late MemorySettingsStore settings;

  setUp(() {
    // 04:00 전환: 2030-03-15 03:50은 논리적 2030-03-14.
    clock = FakeTimeService(DateTime(2030, 3, 15, 3, 50));
    recorder = FakeRecorder();
    recordings = MemoryRecordingStore(recorder, clock);
    diaries = MemoryDiaryStore();
    settings = MemorySettingsStore();
  });

  /// 앱 실행과 같이 저장소에서 설정과 일기를 읽어 화면을 띄운다.
  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await launchApp(
      timeService: clock,
      recorder: recorder,
      recordingStore: recordings,
      settingsStore: settings,
      diaryStore: diaries,
    );
    await tester.pumpWidget(SizedBox(key: UniqueKey()));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  Future<void> tapCreateDiary(WidgetTester tester) async {
    await tester.ensureVisible(find.text('오늘의 일기 만들기'));
    await tester.tap(find.text('오늘의 일기 만들기'));
    await tester.pumpAndSettle();
  }

  testWidgets('오늘 녹음이 없으면 일기를 만들지 않는다', (tester) async {
    // 논리적 전날(03-13) 녹음은 오늘 녹음이 아니다.
    recordings.seed(DateTime(2030, 3, 14, 3, 0));
    await launch(tester);

    await tapCreateDiary(tester);

    expect(find.text('오늘 녹음이 있어야 일기를 만들 수 있어요.'), findsOneWidget);
    expect(diaries.saved, isEmpty);
    expect(find.text('그날의 일기'), findsNothing);
  });

  testWidgets('오늘 녹음으로 일기를 저장하고, 마커가 있는 날짜만 일기를 연다', (tester) async {
    recordings.seed(DateTime(2030, 3, 14, 23, 30));
    await launch(tester);
    final semantics = tester.ensureSemantics();

    await tapCreateDiary(tester);

    expect(diaries.saved.keys, ['2030-03-14']);
    expect(find.text('그날의 일기'), findsOneWidget);
    expect(find.text('2030년 3월 14일 목요일'), findsOneWidget);
    expect(find.text(diaries.saved['2030-03-14']!.body), findsOneWidget);
    expect(find.text('수정'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^3월 14일, 일기 있음')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('일기 있음')), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-day-10')));
    await tester.pumpAndSettle();
    expect(find.text('이 날짜에는 일기가 없어요.'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('앱을 다시 실행해도 일기와 설정이 남고, 전환 시각이 지나면 읽기 전용이다', (tester) async {
    recordings.seed(DateTime(2030, 3, 14, 23, 30));
    await launch(tester);
    await tapCreateDiary(tester);

    // 다시 실행: 전환 시각 04:00이 지난 03-15 04:30.
    clock.setNow(DateTime(2030, 3, 15, 4, 30));
    await launch(tester);
    await tester.tap(find.text('캘린더'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar-day-14')));
    await tester.pumpAndSettle();

    expect(find.text(diaries.saved['2030-03-14']!.title), findsOneWidget);
    expect(find.text('읽기 전용'), findsOneWidget);
    expect(find.text('수정'), findsNothing);
  });

  testWidgets('저장된 하루 전환 시각으로 시작하고, 바꾼 값은 저장된다', (tester) async {
    settings.saved = const AppSettings(turnoverHour: 5, retentionDays: 7);
    // 05:00 전환: 03-15 04:30은 논리적 03-14.
    clock.setNow(DateTime(2030, 3, 15, 4, 30));
    await launch(tester);

    expect(find.text('논리적 오늘 · 2030년 3월 14일 목요일'), findsOneWidget);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('7일'), findsOneWidget);

    await tester.tap(find.text('05:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('04:00').last);
    await tester.pumpAndSettle();

    expect(settings.saved.turnoverHour, 4);
    expect(settings.saved.retentionDays, 7);
  });
}
