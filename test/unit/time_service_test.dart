import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/time/time_service.dart';

void main() {
  test('04:00 전 기록은 전날 논리적 날짜에 속한다', () {
    final clock = FixedTimeService(DateTime(2026, 10, 2, 3, 30));
    expect(LogicalDate.today(clock, 4), DateTime(2026, 10, 1));
    expect(
      LogicalDate.forMoment(DateTime(2026, 10, 2, 4), 4),
      DateTime(2026, 10, 2),
    );
  });

  test('21:00에 다음 논리적 날짜로 전환되고 자정 후에도 유지된다', () {
    expect(
      LogicalDate.forMoment(DateTime(2026, 10, 1, 20, 59), 21),
      DateTime(2026, 10, 1),
    );
    expect(
      LogicalDate.forMoment(DateTime(2026, 10, 1, 21), 21),
      DateTime(2026, 10, 2),
    );
    expect(
      LogicalDate.forMoment(DateTime(2026, 10, 2, 0, 30), 21),
      DateTime(2026, 10, 2),
    );
  });

  test('전환 시각은 21:00~익일 09:00 정시만 허용한다', () {
    expect(
      () => LogicalDate.forMoment(DateTime(2026), 10),
      throwsArgumentError,
    );
  });
}
