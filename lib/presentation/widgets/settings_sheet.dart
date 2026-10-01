import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/logical_date_service.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.turnoverHour,
    required this.retentionDays,
    required this.onTurnoverChanged,
    required this.onRetentionChanged,
  });

  final int turnoverHour;
  final int retentionDays;
  final ValueChanged<int> onTurnoverChanged;
  final ValueChanged<int> onRetentionChanged;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late int _hour = widget.turnoverHour;
  late int _days = widget.retentionDays;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('나에게 맞는 하루', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            '생활 리듬에 맞게 기록 기준을 정해 보세요.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          Text('하루 전환 시각', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            '이 시각에 새로운 논리적 날짜가 시작돼요.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _hour,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: LogicalDateService.allowedTurnoverHours
                .map(
                  (hour) => DropdownMenuItem(
                    value: hour,
                    child: Text(turnoverLabel(hour)),
                  ),
                )
                .toList(),
            onChanged: (hour) {
              if (hour == null) return;
              setState(() => _hour = hour);
              widget.onTurnoverChanged(hour);
            },
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('오디오 보관 기간', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '$_days일',
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: _days.toDouble(),
            min: 1,
            max: 14,
            divisions: 13,
            label: '$_days일',
            onChanged: (value) {
              final days = value.round();
              setState(() => _days = days);
              widget.onRetentionChanged(days);
            },
          ),
          const Text(
            '설정값은 이 미리보기 화면에 즉시 반영돼요.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('완료'),
          ),
        ],
      ),
    ),
  );
}
