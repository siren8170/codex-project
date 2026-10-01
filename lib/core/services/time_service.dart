/// 화면과 정책에서 사용하는 현재 시각을 주입 가능한 계약으로 분리한다.
abstract class TimeService {
  DateTime now();
}

class SystemTimeService implements TimeService {
  @override
  DateTime now() => DateTime.now();
}

/// 테스트에서 시각을 직접 지정하거나 흘려보낼 수 있는 구현체.
class FakeTimeService implements TimeService {
  FakeTimeService(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void setNow(DateTime value) => _now = value;

  void advance(Duration duration) => _now = _now.add(duration);
}
