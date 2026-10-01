import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/data/settings_store.dart';

void main() {
  late Directory dir;
  late File file;
  late FileSettingsStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('one_day_settings_');
    file = File('${dir.path}/settings.json');
    store = FileSettingsStore(filePath: () async => file.path);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('저장된 값이 없으면 기본값(04:00, 1일)을 쓴다', () async {
    final settings = await store.load();
    expect(settings.turnoverHour, 4);
    expect(settings.retentionDays, 1);
  });

  test('하루 전환 시각과 오디오 보관 기간을 저장하고 다시 읽는다', () async {
    await store.save(const AppSettings(turnoverHour: 22, retentionDays: 14));
    final settings = await store.load();
    expect(settings.turnoverHour, 22);
    expect(settings.retentionDays, 14);
  });

  test('허용 범위 밖이거나 손상된 값은 항목별로 기본값을 쓴다', () async {
    file.writeAsStringSync('{"turnoverHour": 12, "retentionDays": 7}');
    var settings = await store.load();
    expect(settings.turnoverHour, 4);
    expect(settings.retentionDays, 7);

    file.writeAsStringSync('{"turnoverHour": 6, "retentionDays": 30}');
    settings = await store.load();
    expect(settings.turnoverHour, 6);
    expect(settings.retentionDays, 1);

    file.writeAsStringSync('not json');
    settings = await store.load();
    expect(settings.turnoverHour, 4);
    expect(settings.retentionDays, 1);
  });
}
