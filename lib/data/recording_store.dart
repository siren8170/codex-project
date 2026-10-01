import 'dart:io';

import '../core/services/time_service.dart';

class Recording {
  const Recording({
    required this.path,
    required this.recordedAt,
    required this.sizeBytes,
  });

  final String path;
  final DateTime recordedAt;
  final int sizeBytes;
}

/// 녹음 파일의 저장 위치를 정하고 저장된 목록을 읽는다.
///
/// [delete]는 `AudioCleanupService`가 오디오 보관 기간이 지난 파일을 정리할 때만 쓴다.
abstract class RecordingStore {
  Future<String> newRecordingPath();

  Future<List<Recording>> list();

  Future<void> delete(Recording recording);
}

/// 앱 내부 저장소의 `recordings` 폴더에 `rec_yyyyMMdd_HHmmss.m4a` 이름으로 보관한다.
class LocalRecordingStore implements RecordingStore {
  LocalRecordingStore({
    required this._directoryPath,
    required this._timeService,
  });

  final Future<String> Function() _directoryPath;
  final TimeService _timeService;

  static final _namePattern = RegExp(r'^rec_(\d{8})_(\d{6})\.m4a$');

  Future<Directory> _directory() async {
    final dir = Directory(await _directoryPath());
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String> newRecordingPath() async {
    final dir = await _directory();
    final now = _timeService.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final name =
        'rec_${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}.m4a';
    return '${dir.path}${Platform.pathSeparator}$name';
  }

  @override
  Future<List<Recording>> list() async {
    final dir = await _directory();
    final recordings = <Recording>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final match = _namePattern.firstMatch(name);
      if (match == null) continue;
      final date = match.group(1)!;
      final time = match.group(2)!;
      recordings.add(
        Recording(
          path: entity.path,
          recordedAt: DateTime(
            int.parse(date.substring(0, 4)),
            int.parse(date.substring(4, 6)),
            int.parse(date.substring(6, 8)),
            int.parse(time.substring(0, 2)),
            int.parse(time.substring(2, 4)),
            int.parse(time.substring(4, 6)),
          ),
          sizeBytes: await entity.length(),
        ),
      );
    }
    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return recordings;
  }

  @override
  Future<void> delete(Recording recording) async {
    final file = File(recording.path);
    if (await file.exists()) await file.delete();
  }
}
