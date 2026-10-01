import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';

void main() {
  test('FakeTimeService는 지정한 시각을 반환하고 수동으로 바꿀 수 있다', () {
    final clock = FakeTimeService(DateTime(2026, 10, 1, 23, 50));
    expect(clock.now(), DateTime(2026, 10, 1, 23, 50));

    clock.advance(const Duration(minutes: 20));
    expect(clock.now(), DateTime(2026, 10, 2, 0, 10));

    clock.setNow(DateTime(2026, 10, 5, 9));
    expect(clock.now(), DateTime(2026, 10, 5, 9));
  });
}
