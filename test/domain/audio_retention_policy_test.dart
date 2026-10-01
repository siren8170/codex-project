import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/domain/policies/audio_retention_policy.dart';

void main() {
  const policy = AudioRetentionPolicy();
  final today = DateTime(2026, 10, 15);

  bool expiredAfter(int elapsedDays, int retentionDays) => policy.isExpired(
    audioLogicalDate: DateTime(
      today.year,
      today.month,
      today.day - elapsedDays,
    ),
    currentLogicalDate: today,
    retentionDays: retentionDays,
  );

  test('보관 기간 1일: 1일 지난 오디오는 유지, 2일 지나면 만료', () {
    expect(expiredAfter(0, 1), isFalse);
    expect(expiredAfter(1, 1), isFalse);
    expect(expiredAfter(2, 1), isTrue);
  });

  test('보관 기간 3일: 3일 이내는 유지, 4일 지난 오디오만 만료', () {
    expect(expiredAfter(2, 3), isFalse);
    expect(expiredAfter(3, 3), isFalse);
    expect(expiredAfter(4, 3), isTrue);
  });

  test('보관 기간 14일: 14일 지난 오디오는 유지, 15일 지나면 만료', () {
    expect(expiredAfter(14, 14), isFalse);
    expect(expiredAfter(15, 14), isTrue);
  });

  test('날짜 안의 시각은 판정에 영향을 주지 않는다', () {
    expect(
      policy.isExpired(
        audioLogicalDate: DateTime(2026, 10, 11, 23, 59),
        currentLogicalDate: DateTime(2026, 10, 15, 0, 1),
        retentionDays: 3,
      ),
      isTrue,
    );
  });

  test('월 경계를 넘어도 일수를 정확히 센다', () {
    expect(
      policy.isExpired(
        audioLogicalDate: DateTime(2026, 9, 28),
        currentLogicalDate: DateTime(2026, 10, 2),
        retentionDays: 3,
      ),
      isTrue,
    );
    expect(
      policy.isExpired(
        audioLogicalDate: DateTime(2026, 9, 29),
        currentLogicalDate: DateTime(2026, 10, 2),
        retentionDays: 3,
      ),
      isFalse,
    );
  });

  test('보관 기간은 1~14일만 허용한다', () {
    for (final days in [0, 15]) {
      expect(
        () => policy.isExpired(
          audioLogicalDate: today,
          currentLogicalDate: today,
          retentionDays: days,
        ),
        throwsArgumentError,
        reason: '$days일',
      );
    }
  });
}
