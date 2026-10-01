import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/data/diary_store.dart';

void main() {
  late Directory dir;
  late File file;
  late FileDiaryStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('one_day_diaries_');
    file = File('${dir.path}/diaries.json');
    store = FileDiaryStore(filePath: () async => file.path);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('저장된 일기가 없으면 빈 목록이다', () async {
    expect(await store.loadAll(), isEmpty);
  });

  test('일기를 날짜별로 저장하고, 같은 날짜는 덮어쓴다', () async {
    await store.save(
      Diary(date: DateTime(2030, 3, 13), title: '13일', body: '본문 13'),
    );
    await store.save(
      Diary(date: DateTime(2030, 3, 14), title: '초안', body: '초안 본문'),
    );
    await store.save(
      Diary(
        date: DateTime(2030, 3, 14),
        title: '초안',
        body: '초안 본문 산책 후 차를 마셨다',
      ),
    );

    final reopened = await FileDiaryStore(
      filePath: () async => file.path,
    ).loadAll();

    expect(reopened.keys, unorderedEquals(['2030-03-13', '2030-03-14']));
    expect(reopened['2030-03-14']!.body, '초안 본문 산책 후 차를 마셨다');
    expect(reopened['2030-03-13']!.date, DateTime(2030, 3, 13));
  });

  test('파일이 손상되면 예외를 내고 기존 내용을 덮어쓰지 않는다', () async {
    file.writeAsStringSync('broken');
    await expectLater(store.loadAll(), throwsA(isA<FormatException>()));
    await expectLater(
      store.save(Diary(date: DateTime(2030, 3, 14), title: 't', body: 'b')),
      throwsA(isA<FormatException>()),
    );
    expect(file.readAsStringSync(), 'broken');
  });
}
