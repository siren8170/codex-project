import '../services/logical_date_service.dart';

/// 오디오 보관 기간 초과 여부를 논리적 날짜 기준으로 판정한다.
///
/// 녹음 날짜로부터 지난 일수가 보관 기간을 **초과**하면 만료된다.
/// 예) 보관 기간 3일: 3일 지난 오디오는 유지, 4일 지난 오디오는 만료.
class AudioRetentionPolicy {
  const AudioRetentionPolicy();

  static const minRetentionDays = 1;
  static const maxRetentionDays = 14;
  static const defaultRetentionDays = 1;

  bool isExpired({
    required DateTime audioLogicalDate,
    required DateTime currentLogicalDate,
    required int retentionDays,
  }) {
    if (retentionDays < minRetentionDays || retentionDays > maxRetentionDays) {
      throw ArgumentError.value(retentionDays, 'retentionDays', '1~14일만 허용');
    }
    final elapsedDays = LogicalDateService.daysBetween(
      audioLogicalDate,
      currentLogicalDate,
    );
    return elapsedDays > retentionDays;
  }
}
