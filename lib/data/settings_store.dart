import 'dart:convert';
import 'dart:io';

import '../domain/policies/audio_retention_policy.dart';
import '../domain/services/logical_date_service.dart';

/// 앱을 처음 실행했을 때의 하루 전환 시각.
const defaultTurnoverHour = 4;

class AppSettings {
  const AppSettings({
    this.turnoverHour = defaultTurnoverHour,
    this.retentionDays = AudioRetentionPolicy.defaultRetentionDays,
  });

  final int turnoverHour;
  final int retentionDays;

  AppSettings copyWith({int? turnoverHour, int? retentionDays}) => AppSettings(
    turnoverHour: turnoverHour ?? this.turnoverHour,
    retentionDays: retentionDays ?? this.retentionDays,
  );
}

/// 하루 전환 시각과 오디오 보관 기간을 앱을 다시 실행해도 유지한다.
abstract class SettingsStore {
  /// 저장된 값이 없거나 허용 범위 밖이면 그 항목은 기본값을 쓴다.
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

/// 앱 내부 저장소의 JSON 파일 한 개에 설정을 저장한다.
class FileSettingsStore implements SettingsStore {
  FileSettingsStore({required this._filePath});

  final Future<String> Function() _filePath;

  @override
  Future<AppSettings> load() async {
    final file = File(await _filePath());
    if (!await file.exists()) return const AppSettings();
    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException {
      return const AppSettings();
    }
    if (decoded is! Map) return const AppSettings();
    final hour = decoded['turnoverHour'];
    final days = decoded['retentionDays'];
    return AppSettings(
      turnoverHour:
          hour is int && LogicalDateService.allowedTurnoverHours.contains(hour)
          ? hour
          : defaultTurnoverHour,
      retentionDays:
          days is int &&
              days >= AudioRetentionPolicy.minRetentionDays &&
              days <= AudioRetentionPolicy.maxRetentionDays
          ? days
          : AudioRetentionPolicy.defaultRetentionDays,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final file = File(await _filePath());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'turnoverHour': settings.turnoverHour,
        'retentionDays': settings.retentionDays,
      }),
    );
  }
}
