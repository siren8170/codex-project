import 'dart:convert';
import 'dart:io';

/// 논리적 날짜 하나에 일기 하나가 저장된다.
class Diary {
  const Diary({required this.date, required this.title, required this.body});

  final DateTime date;
  final String title;
  final String body;

  Map<String, Object> toJson() => {
    'date': diaryKey(date),
    'title': title,
    'body': body,
  };

  static Diary fromJson(Map<String, dynamic> json) {
    final parts = (json['date'] as String).split('-').map(int.parse).toList();
    return Diary(
      date: DateTime(parts[0], parts[1], parts[2]),
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

/// 일기 저장 키: 논리적 날짜의 `yyyy-MM-dd`.
String diaryKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// 일기를 기기 안에 영구 보존한다. 오디오 보관 기간과 관계없이 지우지 않는다.
abstract class DiaryStore {
  /// [diaryKey]로 찾을 수 있는 저장된 일기 전체.
  Future<Map<String, Diary>> loadAll();

  /// 같은 날짜의 일기가 있으면 바꾼다.
  Future<void> save(Diary diary);
}

/// 앱 내부 저장소의 JSON 파일 한 개에 일기를 저장한다.
class FileDiaryStore implements DiaryStore {
  FileDiaryStore({required this._filePath});

  final Future<String> Function() _filePath;

  @override
  Future<Map<String, Diary>> loadAll() async {
    final file = File(await _filePath());
    if (!await file.exists()) return {};
    // 파일이 손상되었으면 예외를 그대로 올려, 빈 목록으로 덮어쓰지 않게 한다.
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    final diaries = decoded
        .map((item) => Diary.fromJson(item as Map<String, dynamic>))
        .toList();
    return {for (final diary in diaries) diaryKey(diary.date): diary};
  }

  @override
  Future<void> save(Diary diary) async {
    final diaries = await loadAll();
    diaries[diaryKey(diary.date)] = diary;
    final file = File(await _filePath());
    await file.parent.create(recursive: true);
    // 임시 파일에 다 쓴 뒤 바꿔치기해, 쓰는 도중 앱이 꺼져도 기존 일기가 깨지지 않게 한다.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode(diaries.values.map((d) => d.toJson()).toList()),
    );
    await temp.rename(file.path);
  }
}
