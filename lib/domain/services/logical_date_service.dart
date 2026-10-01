import '../../core/services/time_service.dart';

/// 하루 전환 시각을 기준으로 특정 시각이 속한 논리적 날짜를 계산한다.
///
/// - 21~24시 전환: 전환 시각부터 다음 날짜가 시작된다. (21시 전환이면 10/1 21:00은 10/2)
/// - 0~9시 전환: 전환 시각 전까지는 전날 날짜에 속한다. (4시 전환이면 10/2 03:30은 10/1)
/// - 24시는 0시와 같다.
class LogicalDateService {
  LogicalDateService({required int dayTurnoverHour})
    : dayTurnoverHour = _normalize(dayTurnoverHour);

  /// 설정 화면에서 선택할 수 있는 전환 시각(정시).
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

  final int dayTurnoverHour;

  static int _normalize(int hour) {
    final normalized = hour == 24 ? 0 : hour;
    if (!allowedTurnoverHours.contains(normalized)) {
      throw ArgumentError.value(hour, 'dayTurnoverHour', '21~24시 또는 0~9시만 허용');
    }
    return normalized;
  }

  /// [moment]가 속한 논리적 날짜(해당 날짜 00:00:00)를 반환한다.
  DateTime logicalDateOf(DateTime moment) {
    final date = dateOnly(moment);
    if (dayTurnoverHour >= 21 && moment.hour >= dayTurnoverHour) {
      return DateTime(date.year, date.month, date.day + 1);
    }
    if (dayTurnoverHour <= 9 && moment.hour < dayTurnoverHour) {
      return DateTime(date.year, date.month, date.day - 1);
    }
    return date;
  }

  DateTime today(TimeService timeService) => logicalDateOf(timeService.now());

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 두 날짜 사이의 달력 일수(b - a). 시각과 서머타임 영향은 무시한다.
  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}
