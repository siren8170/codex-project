import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/domain/services/logical_date_service.dart';

void main() {
  DateTime logical(int turnoverHour, DateTime moment) =>
      LogicalDateService(dayTurnoverHour: turnoverHour).logicalDateOf(moment);

  group('새벽 전환 시각(0~9시)', () {
    test('04:00 전환: 10월 2일 03:30은 10월 1일이다', () {
      expect(logical(4, DateTime(2026, 10, 2, 3, 30)), DateTime(2026, 10, 1));
    });

    test('04:00 전환: 03:59까지 전날, 04:00부터 당일이다', () {
      expect(
        logical(4, DateTime(2026, 10, 2, 3, 59, 59)),
        DateTime(2026, 10, 1),
      );
      expect(logical(4, DateTime(2026, 10, 2, 4)), DateTime(2026, 10, 2));
    });

    test('04:00 전환: 자정 직전과 직후는 같은 논리적 날짜다', () {
      expect(logical(4, DateTime(2026, 10, 1, 23, 59)), DateTime(2026, 10, 1));
      expect(logical(4, DateTime(2026, 10, 2, 0, 1)), DateTime(2026, 10, 1));
    });

    test('09:00 전환: 08:59는 전날, 09:00은 당일이다', () {
      expect(logical(9, DateTime(2026, 10, 2, 8, 59)), DateTime(2026, 10, 1));
      expect(logical(9, DateTime(2026, 10, 2, 9)), DateTime(2026, 10, 2));
    });

    test('00:00 전환: 달력 날짜와 같다', () {
      expect(logical(0, DateTime(2026, 10, 1, 23, 59)), DateTime(2026, 10, 1));
      expect(logical(0, DateTime(2026, 10, 2, 0)), DateTime(2026, 10, 2));
    });

    test('24시는 0시와 같게 취급한다', () {
      final service = LogicalDateService(dayTurnoverHour: 24);
      expect(service.dayTurnoverHour, 0);
      expect(
        service.logicalDateOf(DateTime(2026, 10, 2, 0, 30)),
        DateTime(2026, 10, 2),
      );
    });
  });

  group('저녁 전환 시각(21~23시)', () {
    test('21:00 전환: 20:59는 당일, 21:00부터 다음 날이다', () {
      expect(logical(21, DateTime(2026, 10, 1, 20, 59)), DateTime(2026, 10, 1));
      expect(logical(21, DateTime(2026, 10, 1, 21)), DateTime(2026, 10, 2));
    });

    test('21:00 전환: 자정 직전과 직후는 같은 논리적 날짜다', () {
      expect(logical(21, DateTime(2026, 10, 1, 23, 59)), DateTime(2026, 10, 2));
      expect(logical(21, DateTime(2026, 10, 2, 0, 30)), DateTime(2026, 10, 2));
    });

    test('23:00 전환: 22:59는 당일, 23:00은 다음 날이다', () {
      expect(logical(23, DateTime(2026, 10, 1, 22, 59)), DateTime(2026, 10, 1));
      expect(logical(23, DateTime(2026, 10, 1, 23)), DateTime(2026, 10, 2));
    });
  });

  group('월·연 경계', () {
    test('04:00 전환: 1월 1일 새벽은 전년 12월 31일이다', () {
      expect(logical(4, DateTime(2027, 1, 1, 2)), DateTime(2026, 12, 31));
    });

    test('21:00 전환: 12월 31일 밤은 다음 해 1월 1일이다', () {
      expect(logical(21, DateTime(2026, 12, 31, 22)), DateTime(2027, 1, 1));
    });

    test('04:00 전환: 윤년 3월 1일 새벽은 2월 29일이다', () {
      expect(logical(4, DateTime(2028, 3, 1, 1)), DateTime(2028, 2, 29));
    });
  });

  test('반환값은 시각이 00:00:00인 날짜다', () {
    final date = logical(4, DateTime(2026, 10, 2, 15, 42, 7, 123));
    expect(
      [date.hour, date.minute, date.second, date.millisecond],
      [0, 0, 0, 0],
    );
  });

  test('today는 TimeService의 현재 시각을 따른다', () {
    final clock = FakeTimeService(DateTime(2026, 10, 2, 3, 30));
    final service = LogicalDateService(dayTurnoverHour: 4);
    expect(service.today(clock), DateTime(2026, 10, 1));
    clock.advance(const Duration(minutes: 30));
    expect(service.today(clock), DateTime(2026, 10, 2));
  });

  test('21~24시, 0~9시 외의 전환 시각은 거부한다', () {
    for (final hour in [-1, 10, 15, 20, 25]) {
      expect(
        () => LogicalDateService(dayTurnoverHour: hour),
        throwsArgumentError,
        reason: '$hour시',
      );
    }
  });
}
