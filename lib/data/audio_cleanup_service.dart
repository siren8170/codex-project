import 'package:flutter/foundation.dart';

import '../core/services/time_service.dart';
import '../domain/policies/audio_retention_policy.dart';
import '../domain/services/logical_date_service.dart';
import 'recording_store.dart';

/// 앱 실행 시 오디오 보관 기간이 지난 녹음 파일을 영구 삭제한다.
///
/// 녹음 시각과 현재 시각을 하루 전환 시각 기준 논리적 날짜로 바꾼 뒤
/// `AudioRetentionPolicy.isExpired`가 참인 파일만 지운다.
class AudioCleanupService {
  const AudioCleanupService({
    required this.store,
    required this.timeService,
    this.policy = const AudioRetentionPolicy(),
  });

  final RecordingStore store;
  final TimeService timeService;
  final AudioRetentionPolicy policy;

  /// 삭제한 녹음 목록을 반환한다. 한 파일 삭제에 실패해도 나머지는 계속 정리한다.
  Future<List<Recording>> deleteExpired({
    required int retentionDays,
    required int turnoverHour,
  }) async {
    final dates = LogicalDateService(dayTurnoverHour: turnoverHour);
    final today = dates.today(timeService);
    final deleted = <Recording>[];
    for (final recording in await store.list()) {
      final expired = policy.isExpired(
        audioLogicalDate: dates.logicalDateOf(recording.recordedAt),
        currentLogicalDate: today,
        retentionDays: retentionDays,
      );
      if (!expired) continue;
      try {
        await store.delete(recording);
        deleted.add(recording);
      } catch (error) {
        debugPrint('만료 녹음 삭제 실패: ${recording.path} $error');
      }
    }
    return deleted;
  }
}
