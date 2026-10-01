import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/time/time_service.dart';
import '../widgets/settings_sheet.dart';
import 'calendar_tab.dart';
import 'record_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.timeService});

  final TimeService timeService;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;
  int _turnoverHour = 4;
  int _retentionDays = 1;

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) => SettingsSheet(
        turnoverHour: _turnoverHour,
        retentionDays: _retentionDays,
        onTurnoverChanged: (hour) => setState(() => _turnoverHour = hour),
        onRetentionChanged: (days) => setState(() => _retentionDays = days),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logicalToday = LogicalDate.today(widget.timeService, _turnoverHour);
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 하루'),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: IndexedStack(
          index: _selectedTab,
          children: [
            RecordTab(
              logicalToday: logicalToday,
              retentionDays: _retentionDays,
              onCreateDiary: () => setState(() => _selectedTab = 1),
            ),
            CalendarTab(logicalToday: logicalToday),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_rounded),
            activeIcon: Icon(Icons.mic_rounded),
            label: '녹음',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: '캘린더',
          ),
        ],
      ),
    );
  }
}
