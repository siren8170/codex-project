import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/time/time_service.dart';
import '../../data/mock_diary_generator.dart';
import '../../domain/diary_policy.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key, required this.logicalToday});

  final DateTime logicalToday;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _visibleMonth = DateTime(
    widget.logicalToday.year,
    widget.logicalToday.month,
  );
  late DateTime _selectedDate = widget.logicalToday;
  final Map<String, MockDiary> _editedDiaries = {};
  final _generator = const MockDiaryGenerator();
  final _policy = const DiaryPolicy();

  @override
  void didUpdateWidget(covariant CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!LogicalDate.sameDay(oldWidget.logicalToday, widget.logicalToday) &&
        LogicalDate.sameDay(_selectedDate, oldWidget.logicalToday)) {
      _selectedDate = widget.logicalToday;
      _visibleMonth = DateTime(
        widget.logicalToday.year,
        widget.logicalToday.month,
      );
    }
  }

  String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';

  bool _hasDiary(DateTime date) =>
      LogicalDate.sameDay(date, widget.logicalToday) ||
      date.day % 4 == 1 ||
      _editedDiaries.containsKey(_key(date));

  void _changeMonth(int direction) => setState(() {
    _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + direction,
    );
    _selectedDate = _visibleMonth;
  });

  Future<void> _editDiary(MockDiary diary) async {
    final titleController = TextEditingController(text: diary.title);
    final bodyController = TextEditingController(text: diary.body);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오늘의 일기 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '본문',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (saved == true &&
        mounted &&
        _policy.canEdit(diary.date, widget.logicalToday)) {
      setState(
        () => _editedDiaries[_key(diary.date)] = MockDiary(
          date: diary.date,
          title: titleController.text.trim(),
          body: bodyController.text.trim(),
        ),
      );
    }
    titleController.dispose();
    bodyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month).weekday % 7;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final diary = _hasDiary(_selectedDate)
        ? (_editedDiaries[_key(_selectedDate)] ??
              _generator.forDate(_selectedDate))
        : null;
    final canEdit =
        diary != null && _policy.canEdit(_selectedDate, widget.logicalToday);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('하루씩 돌아보기', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Text(
          '하루의 조각을\n다시 꺼내 봐요.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          '날짜를 누르면 그날의 일기를 볼 수 있어요.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_visibleMonth.year}년 ${_visibleMonth.month}월',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '이전 달',
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: '다음 달',
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: ['일', '월', '화', '수', '목', '금', '토']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childAspectRatio: 0.95,
                ),
                itemCount: firstWeekday + daysInMonth,
                itemBuilder: (context, index) {
                  final day = index - firstWeekday + 1;
                  if (day < 1) return const SizedBox.shrink();
                  final date = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month,
                    day,
                  );
                  final selected = LogicalDate.sameDay(date, _selectedDate);
                  final today = LogicalDate.sameDay(date, widget.logicalToday);
                  return Semantics(
                    label:
                        '${date.month}월 $day일${_hasDiary(date) ? ', 일기 있음' : ''}',
                    child: InkWell(
                      key: Key('calendar-day-$day'),
                      onTap: () => setState(() => _selectedDate = date),
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? AppColors.mint : null,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                color: today ? AppColors.green : AppColors.ink,
                                fontWeight: selected || today
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (_hasDiary(date))
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.circle, color: AppColors.green, size: 7),
                  SizedBox(width: 6),
                  Text(
                    '점 표시는 예시 일기가 있는 날이에요.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            border: Border.all(color: const Color(0xFFE2EEDC)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('그날의 일기', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              Text(
                koreanDate(_selectedDate),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (diary == null)
                const Text(
                  '이 날짜에는 일기가 없어요.',
                  style: TextStyle(color: AppColors.muted),
                )
              else ...[
                Text(
                  diary.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  diary.body,
                  style: const TextStyle(color: AppColors.muted, height: 1.8),
                ),
                const SizedBox(height: 22),
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: () => _editDiary(diary),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('수정'),
                  )
                else
                  const Chip(
                    avatar: Icon(Icons.lock_outline, size: 16),
                    label: Text('읽기 전용'),
                  ),
              ],
              const SizedBox(height: 8),
              const Text(
                '예시 일기 · 변경 내용은 앱을 닫으면 사라져요.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
