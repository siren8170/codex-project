import 'package:flutter_test/flutter_test.dart';
import 'package:one_day/domain/diary_policy.dart';

void main() {
  test('논리적 당일 일기만 수정할 수 있다', () {
    const policy = DiaryPolicy();
    final today = DateTime(2026, 10, 2);
    expect(policy.canEdit(today, today), isTrue);
    expect(policy.canEdit(DateTime(2026, 10, 1), today), isFalse);
    expect(policy.canEdit(DateTime(2026, 10, 3), today), isFalse);
  });
}
