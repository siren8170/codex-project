import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/domain/audio_retention_policy.dart';

void main() {
  test('3일 보관 기간 초과 파일만 선별한다', () {
    final now = DateTime(2026, 10, 2, 12);
    final items = [
      AudioItem(id: 'old', recordedAt: now.subtract(const Duration(days: 4))),
      AudioItem(
        id: 'boundary',
        recordedAt: now.subtract(const Duration(days: 3)),
      ),
      AudioItem(
        id: 'recent',
        recordedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    expect(
      const AudioRetentionPolicy()
          .expiredItems(items, now: now, retentionDays: 3)
          .map((e) => e.id),
      ['old'],
    );
  });

  test('보관 기간은 1~14일만 허용한다', () {
    expect(
      () => const AudioRetentionPolicy().expiredItems(
        [],
        now: DateTime(2026),
        retentionDays: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => const AudioRetentionPolicy().expiredItems(
        [],
        now: DateTime(2026),
        retentionDays: 15,
      ),
      throwsArgumentError,
    );
  });
}
