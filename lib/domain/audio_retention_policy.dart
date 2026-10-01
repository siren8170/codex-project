class AudioItem {
  const AudioItem({required this.id, required this.recordedAt});

  final String id;
  final DateTime recordedAt;
}

/// 삭제 대상만 선별한다. 실제 파일 삭제는 저장소 연동 단계의 책임이다.
class AudioRetentionPolicy {
  const AudioRetentionPolicy();

  List<AudioItem> expiredItems(
    Iterable<AudioItem> items, {
    required DateTime now,
    required int retentionDays,
  }) {
    if (retentionDays < 1 || retentionDays > 14) {
      throw ArgumentError.value(retentionDays, 'retentionDays');
    }
    final cutoff = now.subtract(Duration(days: retentionDays));
    return items.where((item) => item.recordedAt.isBefore(cutoff)).toList();
  }
}
