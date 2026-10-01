import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/core/services/time_service.dart';
import 'package:one_day/domain/policies/diary_policy.dart';
import 'package:one_day/domain/services/logical_date_service.dart';

void main() {
  const policy = DiaryPolicy();

  test('논리적 당일 일기는 수정할 수 있다', () {
    expect(
      policy.canEdit(
        diaryLogicalDate: DateTime(2026, 10, 2),
        currentLogicalDate: DateTime(2026, 10, 2),
      ),
      isTrue,
    );
  });

  test('어제 일기는 수정할 수 없다', () {
    expect(
      policy.canEdit(
        diaryLogicalDate: DateTime(2026, 10, 1),
        currentLogicalDate: DateTime(2026, 10, 2),
      ),
      isFalse,
    );
  });

  test('미래 날짜 일기도 수정할 수 없다', () {
    expect(
      policy.canEdit(
        diaryLogicalDate: DateTime(2026, 10, 3),
        currentLogicalDate: DateTime(2026, 10, 2),
      ),
      isFalse,
    );
  });

  test('04:00 전환: 새벽까지는 수정 가능하고 전환 시각이 지나면 잠긴다', () {
    final clock = FakeTimeService(DateTime(2026, 10, 1, 22));
    final dates = LogicalDateService(dayTurnoverHour: 4);
    final diaryDate = dates.today(clock);

    clock.setNow(DateTime(2026, 10, 2, 3, 59));
    expect(
      policy.canEdit(
        diaryLogicalDate: diaryDate,
        currentLogicalDate: dates.today(clock),
      ),
      isTrue,
    );

    clock.setNow(DateTime(2026, 10, 2, 4));
    expect(
      policy.canEdit(
        diaryLogicalDate: diaryDate,
        currentLogicalDate: dates.today(clock),
      ),
      isFalse,
    );
  });

  test('21:00 전환: 당일 저녁 전환 시각에 잠긴다', () {
    final clock = FakeTimeService(DateTime(2026, 10, 1, 9));
    final dates = LogicalDateService(dayTurnoverHour: 21);
    final diaryDate = dates.today(clock);

    clock.setNow(DateTime(2026, 10, 1, 20, 59));
    expect(
      policy.canEdit(
        diaryLogicalDate: diaryDate,
        currentLogicalDate: dates.today(clock),
      ),
      isTrue,
    );

    clock.setNow(DateTime(2026, 10, 1, 21));
    expect(
      policy.canEdit(
        diaryLogicalDate: diaryDate,
        currentLogicalDate: dates.today(clock),
      ),
      isFalse,
    );
  });
}
