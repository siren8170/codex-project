import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/data/audio_cleanup_service.dart';
import 'package:one_day/data/recording_store.dart';
import 'package:one_day/data/diary_store.dart';
import 'package:one_day/data/settings_store.dart';
import 'package:one_day/main.dart';

void main() {
  late Directory dir;
  late FakeTimeService clock;
  late LocalRecordingStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('one_day_cleanup_');
    clock = FakeTimeService(DateTime(2030, 3, 14, 12));
    store = LocalRecordingStore(
      directoryPath: () async => '${dir.path}/recordings',
      timeService: clock,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// [at] 시각에 녹음한 파일을 만든다.
  Future<String> recordAt(DateTime at) async {
    clock.setNow(at);
    final path = await store.newRecordingPath();
    await File(path).writeAsBytes([1, 2, 3]);
    return path;
  }

  Future<List<String>> remaining() async =>
      (await store.list()).map((r) => r.path).toList();

  test('보관 기간 1일: 03-14 녹음은 03-15에 남고 03-16 실행 시 삭제된다', () async {
    final path = await recordAt(DateTime(2030, 3, 14, 12));
    final cleanup = AudioCleanupService(store: store, timeService: clock);

    clock.setNow(DateTime(2030, 3, 15, 12));
    expect(
      await cleanup.deleteExpired(retentionDays: 1, turnoverHour: 4),
      isEmpty,
    );
    expect(await remaining(), [path]);

    clock.setNow(DateTime(2030, 3, 16, 12));
    final deleted = await cleanup.deleteExpired(
      retentionDays: 1,
      turnoverHour: 4,
    );
    expect(deleted.map((r) => r.path), [path]);
    expect(File(path).existsSync(), isFalse);
    expect(await remaining(), isEmpty);
  });

  test('보관 기간을 넘긴 녹음만 지우고 기간 안의 녹음은 남긴다', () async {
    final old = await recordAt(DateTime(2030, 3, 1, 10));
    final kept = await recordAt(DateTime(2030, 3, 8, 10));
    clock.setNow(DateTime(2030, 3, 15, 10));

    await AudioCleanupService(
      store: store,
      timeService: clock,
    ).deleteExpired(retentionDays: 7, turnoverHour: 4);

    expect(await remaining(), [kept]);
    expect(File(old).existsSync(), isFalse);
  });

  test('하루 전환 시각 전 새벽 녹음은 전날 논리적 날짜로 계산한다', () async {
    // 04:00 전환: 03-15 03:30 녹음은 논리적 03-14.
    final path = await recordAt(DateTime(2030, 3, 15, 3, 30));
    final cleanup = AudioCleanupService(store: store, timeService: clock);

    clock.setNow(DateTime(2030, 3, 16, 12)); // 논리적 03-16, 2일 경과
    await cleanup.deleteExpired(retentionDays: 1, turnoverHour: 4);
    expect(await remaining(), isEmpty, reason: path);
  });

  test('앱 실행(launchApp) 시 저장된 전환 시각·보관 기간으로 만료 녹음을 지운다', () async {
    final settings = FileSettingsStore(
      filePath: () async => '${dir.path}/settings.json',
    );
    await settings.save(const AppSettings(turnoverHour: 9, retentionDays: 7));
    final old = await recordAt(DateTime(2030, 3, 1, 10));
    // 09:00 전환: 03-08 08:30 녹음은 논리적 03-07 → 03-15에 8일 경과로 만료.
    final beforeTurnover = await recordAt(DateTime(2030, 3, 8, 8, 30));
    final kept = await recordAt(DateTime(2030, 3, 8, 9, 30));
    clock.setNow(DateTime(2030, 3, 15, 10));

    final app = await launchApp(
      timeService: clock,
      recordingStore: store,
      settingsStore: settings,
      diaryStore: FileDiaryStore(
        filePath: () async => '${dir.path}/diaries.json',
      ),
    );

    expect(app.initialSettings.turnoverHour, 9);
    expect(app.initialSettings.retentionDays, 7);
    expect(await remaining(), [kept]);
    expect(File(old).existsSync(), isFalse);
    expect(File(beforeTurnover).existsSync(), isFalse);
  });
}
