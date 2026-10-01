import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/logical_date_service.dart';
import '../../data/diary_store.dart';
import '../../domain/policies/diary_policy.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({
    super.key,
    required this.logicalToday,
    required this.diaries,
    required this.onSaveDiary,
  });

  final DateTime logicalToday;

  /// [diaryKey]로 찾는 저장된 일기.
  final Map<String, Diary> diaries;
  final Future<bool> Function(Diary diary) onSaveDiary;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _visibleMonth = DateTime(
    widget.logicalToday.year,
    widget.logicalToday.month,
  );
  late DateTime _selectedDate = widget.logicalToday;
  final _policy = const DiaryPolicy();

  @override
  void didUpdateWidget(covariant CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!LogicalDateService.isSameDate(
          oldWidget.logicalToday,
          widget.logicalToday,
        ) &&
        LogicalDateService.isSameDate(_selectedDate, oldWidget.logicalToday)) {
      _selectedDate = widget.logicalToday;
      _visibleMonth = DateTime(
        widget.logicalToday.year,
        widget.logicalToday.month,
      );
    }
  }

  bool _hasDiary(DateTime date) => widget.diaries.containsKey(diaryKey(date));

  void _changeMonth(int direction) => setState(() {
    _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + direction,
    );
    _selectedDate = _visibleMonth;
  });

  Future<void> _editDiary(Diary diary) async {
    final edited = await showDialog<Diary>(
      context: context,
      builder: (context) => _DiaryEditDialog(diary: diary),
    );
    if (edited != null &&
        mounted &&
        _policy.canEdit(
          diaryLogicalDate: diary.date,
          currentLogicalDate: widget.logicalToday,
        )) {
      await widget.onSaveDiary(edited);
    }
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
    final diary = widget.diaries[diaryKey(_selectedDate)];
    final canEdit =
        diary != null &&
        _policy.canEdit(
          diaryLogicalDate: _selectedDate,
          currentLogicalDate: widget.logicalToday,
        );
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
                  final selected = LogicalDateService.isSameDate(
                    date,
                    _selectedDate,
                  );
                  final today = LogicalDateService.isSameDate(
                    date,
                    widget.logicalToday,
                  );
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
                    '점 표시는 일기가 있는 날이에요.',
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
                '일기는 이 기기에만 저장돼요.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 입력 컨트롤러를 다이얼로그 수명에 묶어, 닫힘 애니메이션 중 해제되지 않게 한다.
class _DiaryEditDialog extends StatefulWidget {
  const _DiaryEditDialog({required this.diary});

  final Diary diary;

  @override
  State<_DiaryEditDialog> createState() => _DiaryEditDialogState();
}

class _DiaryEditDialogState extends State<_DiaryEditDialog> {
  late final _titleController = TextEditingController(text: widget.diary.title);
  late final _bodyController = TextEditingController(text: widget.diary.body);

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('오늘의 일기 수정'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
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
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          Diary(
            date: widget.diary.date,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
          ),
        ),
        child: const Text('저장'),
      ),
    ],
  );
}
