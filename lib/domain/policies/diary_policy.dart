import '../services/logical_date_service.dart';

/// 일기는 생성된 논리적 당일에만 수정할 수 있다.
class DiaryPolicy {
  const DiaryPolicy();

  bool canEdit({
    required DateTime diaryLogicalDate,
    required DateTime currentLogicalDate,
  }) => LogicalDateService.isSameDate(diaryLogicalDate, currentLogicalDate);
}
