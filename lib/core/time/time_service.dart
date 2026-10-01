/// 화면과 정책에서 사용하는 현재 시각을 주입 가능한 계약으로 분리한다.
abstract class TimeService {
  DateTime now();
}

class SystemTimeService implements TimeService {
  @override
  DateTime now() => DateTime.now();
}

class FixedTimeService implements TimeService {
  const FixedTimeService(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

/// 21:00~09:00의 정시 중 하나를 하루 전환 시각으로 사용한다.
class LogicalDate {
  static const allowedTurnoverHours = <int>[
    21,
    22,
    23,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
  ];

  static DateTime forMoment(DateTime moment, int turnoverHour) {
    if (!allowedTurnoverHours.contains(turnoverHour)) {
      throw ArgumentError.value(turnoverHour, 'turnoverHour');
    }
    var date = DateTime(moment.year, moment.month, moment.day);
    if (turnoverHour >= 21 && moment.hour >= turnoverHour) {
      date = date.add(const Duration(days: 1));
    } else if (turnoverHour <= 9 && moment.hour < turnoverHour) {
      date = date.subtract(const Duration(days: 1));
    }
    return date;
  }

  static DateTime today(TimeService timeService, int turnoverHour) =>
      forMoment(timeService.now(), turnoverHour);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
