import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/data/recording_store.dart';
import 'package:one_day/domain/policies/audio_retention_policy.dart';
import 'package:one_day/domain/services/logical_date_service.dart';

void main() {
  late Directory dir;
  late FakeTimeService clock;
  late LocalRecordingStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('one_day_recordings_');
    clock = FakeTimeService(DateTime(2030, 3, 14, 23, 30, 5));
    store = LocalRecordingStore(
      directoryPath: () async => '${dir.path}/recordings',
      timeService: clock,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> saveFakeRecording() async {
    final path = await store.newRecordingPath();
    await File(path).writeAsBytes(List.filled(2048, 1));
    return path;
  }

  test('저장 경로는 앱 저장소 폴더 안에 TimeService 시각으로 이름 짓는다', () async {
    final path = await store.newRecordingPath();
    expect(path, endsWith('rec_20300314_233005.m4a'));
    expect(Directory('${dir.path}/recordings').existsSync(), isTrue);
  });

  test('저장된 녹음을 최신순으로 읽고, 다른 파일은 무시한다', () async {
    await saveFakeRecording();
    clock.advance(const Duration(hours: 4));
    await saveFakeRecording();
    File('${dir.path}/recordings/memo.txt').writeAsStringSync('x');

    final recordings = await store.list();

    expect(recordings.map((r) => r.recordedAt), [
      DateTime(2030, 3, 15, 3, 30, 5),
      DateTime(2030, 3, 14, 23, 30, 5),
    ]);
    expect(recordings.first.sizeBytes, 2048);
  });

  test('보관 기간이 지나기 전에는 녹음 파일이 그대로 남아 있다', () async {
    const policy = AudioRetentionPolicy();
    final dates = LogicalDateService(dayTurnoverHour: 4);
    final path = await saveFakeRecording();
    final recordedDate = dates.logicalDateOf(clock.now());

    for (final retentionDays in [1, 7, 14]) {
      clock.setNow(DateTime(2030, 3, 14 + retentionDays, 23, 59));
      final recordings = await store.list();

      expect(recordings.map((r) => r.path), [path]);
      expect(File(path).existsSync(), isTrue);
      expect(
        policy.isExpired(
          audioLogicalDate: recordedDate,
          currentLogicalDate: dates.today(clock),
          retentionDays: retentionDays,
        ),
        isFalse,
      );
    }
  });
}
