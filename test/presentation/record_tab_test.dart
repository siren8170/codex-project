import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/main.dart';

import '../helpers/fakes.dart';

final player = FakePlayer();
final exporter = FakeExporter();

/// 하루 전환 시각 04:00 기본 설정으로 앱을 띄운다. [seeds] 시각의 녹음이 미리 저장된다.
Future<FakeRecorder> pumpApp(
  WidgetTester tester, {
  bool granted = true,
  DateTime? now,
  List<DateTime> seeds = const [],
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final clock = FakeTimeService(now ?? DateTime(2030, 3, 14, 9, 42));
  final recorder = FakeRecorder(granted: granted);
  final store = MemoryRecordingStore(recorder, clock);
  seeds.forEach(store.seed);
  await tester.pumpWidget(
    OneDayApp(
      timeService: clock,
      recorder: recorder,
      player: player,
      exporter: exporter,
      recordingStore: store,
      settingsStore: MemorySettingsStore(),
      diaryStore: MemoryDiaryStore(),
    ),
  );
  await tester.pumpAndSettle();
  return recorder;
}

void main() {
  testWidgets('녹음 시작 → 녹음 진행 → 녹음 중지 시 보관함에 저장된다', (tester) async {
    final recorder = await pumpApp(tester);
    expect(find.text('저장된 녹음 0'), findsOneWidget);

    await tester.tap(find.text('녹음 시작'));
    await tester.pump();
    expect(recorder.permissionRequests, 1);
    expect(recorder.calls, ['start']);
    expect(find.text('녹음 중'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:03'), findsOneWidget);

    await tester.tap(find.text('녹음 중지'));
    await tester.pumpAndSettle();
    expect(recorder.calls, ['start', 'stop']);
    expect(find.text('녹음할 준비가 되었어요'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('오전 09:42 녹음'), 180);
    expect(find.text('저장된 녹음 1'), findsOneWidget);
    expect(find.text('오늘 · 2030년 3월 14일 목요일'), findsOneWidget);
    expect(find.text('4KB'), findsOneWidget);
  });

  testWidgets('마이크 권한을 거부하면 녹음을 시작하지 않는다', (tester) async {
    final recorder = await pumpApp(tester, granted: false);

    await tester.tap(find.text('녹음 시작'));
    await tester.pump();

    expect(recorder.permissionRequests, 1);
    expect(recorder.calls, isEmpty);
    expect(find.text('녹음할 준비가 되었어요'), findsOneWidget);
    expect(find.textContaining('마이크 권한이 없어'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('보관함 녹음을 재생하면 진행 상태가 보이고, 끝나면 재생 버튼으로 돌아온다', (tester) async {
    await pumpApp(tester, seeds: [DateTime(2030, 3, 14, 8, 0)]);
    const title = '오전 08:00 녹음';

    await tester.tap(find.byTooltip('$title 재생'));
    await tester.pump();
    expect(player.played.last, '/fake/seeded/0.m4a');
    expect(find.byTooltip('$title 정지'), findsOneWidget);

    player.position = const Duration(seconds: 2);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('00:02 / 00:05 · 4KB'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.4, 0.001));

    player.finish();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byTooltip('$title 재생'), findsOneWidget);
    expect(find.text('4KB'), findsOneWidget);
  });

  testWidgets('재생 중인 녹음을 다시 누르면 멈춘다', (tester) async {
    await pumpApp(tester, seeds: [DateTime(2030, 3, 14, 8, 0)]);
    const title = '오전 08:00 녹음';

    await tester.tap(find.byTooltip('$title 재생'));
    await tester.pump();
    final stopsBefore = player.stops;
    await tester.tap(find.byTooltip('$title 정지'));
    await tester.pump();

    expect(player.stops, stopsBefore + 1);
    expect(find.byTooltip('$title 재생'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('내보내기를 누르면 녹음 파일 이름으로 시스템 저장 창을 연다', (tester) async {
    await pumpApp(tester, seeds: [DateTime(2030, 3, 14, 8, 0)]);

    exporter.result = true;
    await tester.tap(find.byTooltip('오전 08:00 녹음 다운로드/내보내기'));
    await tester.pump();
    expect(exporter.exported.last, ('/fake/seeded/0.m4a', '0.m4a'));
    expect(find.text('녹음 파일을 저장했어요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    exporter.result = false;
    await tester.tap(find.byTooltip('오전 08:00 녹음 다운로드/내보내기'));
    await tester.pump();
    expect(find.text('저장을 취소했어요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('보관함은 하루 전환 시각 기준 논리적 날짜로 녹음을 묶는다', (tester) async {
    // 04:00 전환: 23:30과 다음 날 03:30은 03-14, 04:30만 03-15.
    await pumpApp(
      tester,
      now: DateTime(2030, 3, 15, 9, 0),
      seeds: [
        DateTime(2030, 3, 14, 23, 30),
        DateTime(2030, 3, 15, 3, 30),
        DateTime(2030, 3, 15, 4, 30),
      ],
    );

    expect(find.text('저장된 녹음 3'), findsOneWidget);
    final today = tester.getTopLeft(find.text('오늘 · 2030년 3월 15일 금요일')).dy;
    final yesterday = tester.getTopLeft(find.text('2030년 3월 14일 목요일')).dy;
    double y(String title) => tester.getTopLeft(find.text(title)).dy;

    expect(today, lessThan(y('오전 04:30 녹음')));
    expect(y('오전 04:30 녹음'), lessThan(yesterday));
    expect(yesterday, lessThan(y('오전 03:30 녹음')));
    expect(yesterday, lessThan(y('오후 11:30 녹음')));
  });
}
