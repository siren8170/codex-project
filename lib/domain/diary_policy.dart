import '../core/time/time_service.dart';

class DiaryPolicy {
  const DiaryPolicy();

  bool canEdit(DateTime diaryDate, DateTime logicalToday) =>
      LogicalDate.sameDay(diaryDate, logicalToday);
}
