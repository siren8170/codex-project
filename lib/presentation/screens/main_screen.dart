import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/audio_recorder_service.dart';
import '../../core/services/time_service.dart';
import '../../data/diary_store.dart';
import '../../data/mock_diary_generator.dart';
import '../../data/recording_store.dart';
import '../../data/settings_store.dart';
import '../../domain/services/logical_date_service.dart';
import '../widgets/settings_sheet.dart';
import 'calendar_tab.dart';
import 'record_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.timeService,
    required this.recorder,
    required this.player,
    required this.exporter,
    required this.recordingStore,
    required this.settingsStore,
    required this.diaryStore,
    required this.initialSettings,
    required this.initialDiaries,
  });

  final TimeService timeService;
  final AudioRecorderService recorder;
  final AudioPlayerService player;
  final AudioExportService exporter;
  final RecordingStore recordingStore;
  final SettingsStore settingsStore;
  final DiaryStore diaryStore;
  final AppSettings initialSettings;
  final Map<String, Diary> initialDiaries;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;
  late AppSettings _settings = widget.initialSettings;
  late final Map<String, Diary> _diaries = {...widget.initialDiaries};

  LogicalDateService get _dates =>
      LogicalDateService(dayTurnoverHour: _settings.turnoverHour);

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _changeSettings(AppSettings settings) async {
    setState(() => _settings = settings);
    try {
      await widget.settingsStore.save(settings);
    } catch (error) {
      debugPrint('설정 저장 실패: $error');
    }
  }

  /// 저장에 성공했을 때만 화면에 반영해, 화면과 저장된 일기가 어긋나지 않게 한다.
  Future<bool> _saveDiary(Diary diary) async {
    try {
      await widget.diaryStore.save(diary);
    } catch (error) {
      debugPrint('일기 저장 실패: $error');
      if (mounted) _showMessage('일기를 저장하지 못했어요.');
      return false;
    }
    if (mounted) setState(() => _diaries[diaryKey(diary.date)] = diary);
    return true;
  }

  /// 오늘(논리적 날짜) 녹음이 있으면 가상 일기 초안을 만들어 저장하고 캘린더로 이동한다.
  /// 이미 오늘 일기가 있으면 고친 내용을 덮어쓰지 않고 캘린더로만 이동한다.
  Future<void> _createTodayDiary() async {
    final today = _dates.today(widget.timeService);
    if (!_diaries.containsKey(diaryKey(today))) {
      var recordings = const <Recording>[];
      try {
        recordings = await widget.recordingStore.list();
      } catch (error) {
        debugPrint('녹음 목록을 읽지 못했습니다: $error');
      }
      final hasTodayRecording = recordings.any(
        (r) => LogicalDateService.isSameDate(
          _dates.logicalDateOf(r.recordedAt),
          today,
        ),
      );
      if (!mounted) return;
      if (!hasTodayRecording) {
        _showMessage('오늘 녹음이 있어야 일기를 만들 수 있어요.');
        return;
      }
      final draft = const MockDiaryGenerator().forDate(today);
      final saved = await _saveDiary(
        Diary(date: today, title: draft.title, body: draft.body),
      );
      if (!saved || !mounted) return;
    }
    setState(() => _selectedTab = 1);
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) => SettingsSheet(
        turnoverHour: _settings.turnoverHour,
        retentionDays: _settings.retentionDays,
        onTurnoverChanged: (hour) =>
            _changeSettings(_settings.copyWith(turnoverHour: hour)),
        onRetentionChanged: (days) =>
            _changeSettings(_settings.copyWith(retentionDays: days)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logicalToday = _dates.today(widget.timeService);
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
              retentionDays: _settings.retentionDays,
              turnoverHour: _settings.turnoverHour,
              recorder: widget.recorder,
              player: widget.player,
              exporter: widget.exporter,
              recordingStore: widget.recordingStore,
              onCreateDiary: _createTodayDiary,
            ),
            CalendarTab(
              logicalToday: logicalToday,
              diaries: _diaries,
              onSaveDiary: _saveDiary,
            ),
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
