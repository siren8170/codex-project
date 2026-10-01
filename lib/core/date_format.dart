const weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];

String koreanDate(DateTime date) =>
    '${date.year}년 ${date.month}월 ${date.day}일 ${weekdaysKo[date.weekday - 1]}요일';

String turnoverLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';
