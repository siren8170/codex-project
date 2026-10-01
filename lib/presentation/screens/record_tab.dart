import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/audio_recorder_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/recording_store.dart';
import '../../domain/services/logical_date_service.dart';

class RecordTab extends StatefulWidget {
  const RecordTab({
    super.key,
    required this.logicalToday,
    required this.retentionDays,
    required this.turnoverHour,
    required this.recorder,
    required this.player,
    required this.exporter,
    required this.recordingStore,
    required this.onCreateDiary,
  });

  final DateTime logicalToday;
  final int retentionDays;

  /// 녹음을 논리적 날짜별로 묶을 때 쓰는 하루 전환 시각.
  final int turnoverHour;
  final AudioRecorderService recorder;
  final AudioPlayerService player;
  final AudioExportService exporter;
  final RecordingStore recordingStore;
  final VoidCallback onCreateDiary;

  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab> {
  bool _recording = false;
  bool _busy = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  List<Recording> _recordings = const [];
  String? _playingPath;
  PlaybackStatus? _playback;
  Timer? _playbackTicker;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_playbackTicker != null) {
      _playbackTicker!.cancel();
      widget.player.stop().catchError((Object _) {});
    }
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    try {
      final recordings = await widget.recordingStore.list();
      if (mounted) setState(() => _recordings = recordings);
    } catch (error) {
      debugPrint('녹음 목록을 읽지 못했습니다: $error');
    }
  }

  /// 새 안내는 이전 안내를 바로 대신한다.
  void _showNotice(String message) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );

  /// 같은 녹음을 다시 누르면 멈추고, 다른 녹음을 누르면 바꿔서 처음부터 재생한다.
  Future<void> _togglePlayback(Recording recording) async {
    final wasPlaying = _playingPath == recording.path;
    await _stopPlayback();
    if (wasPlaying) return;
    try {
      await widget.player.play(recording.path);
    } catch (error) {
      _showNotice('녹음을 재생하지 못했어요.');
      debugPrint('재생 실패: $error');
      return;
    }
    if (!mounted) return;
    setState(() {
      _playingPath = recording.path;
      _playback = null;
    });
    _playbackTicker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _pollPlayback(),
    );
  }

  Future<void> _pollPlayback() async {
    final path = _playingPath;
    if (path == null) return;
    try {
      final status = await widget.player.status();
      if (!mounted || _playingPath != path) return;
      if (!status.playing) {
        _finishPlayback();
      } else {
        setState(() => _playback = status);
      }
    } catch (error) {
      debugPrint('재생 상태 확인 실패: $error');
      _finishPlayback();
    }
  }

  void _finishPlayback() {
    _playbackTicker?.cancel();
    _playbackTicker = null;
    if (mounted) {
      setState(() {
        _playingPath = null;
        _playback = null;
      });
    }
  }

  Future<void> _stopPlayback() async {
    if (_playingPath == null) return;
    _finishPlayback();
    try {
      await widget.player.stop();
    } catch (error) {
      debugPrint('재생 중지 실패: $error');
    }
  }

  Future<void> _export(Recording recording) async {
    try {
      final saved = await widget.exporter.export(
        recording.path,
        recording.path.split('/').last,
      );
      _showNotice(saved ? '녹음 파일을 저장했어요.' : '저장을 취소했어요.');
    } catch (error) {
      _showNotice('녹음 파일을 내보내지 못했어요.');
      debugPrint('내보내기 실패: $error');
    }
  }

  Future<void> _startRecording() async {
    await _stopPlayback();
    setState(() => _busy = true);
    try {
      if (!await widget.recorder.requestPermission()) {
        _showNotice('마이크 권한이 없어 녹음할 수 없어요. 설정에서 권한을 허용해 주세요.');
        return;
      }
      await widget.recorder.start(
        await widget.recordingStore.newRecordingPath(),
      );
      _elapsedSeconds = 0;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
      if (mounted) setState(() => _recording = true);
    } catch (error) {
      _showNotice('녹음을 시작하지 못했어요.');
      debugPrint('녹음 시작 실패: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    _ticker = null;
    setState(() => _busy = true);
    try {
      await widget.recorder.stop();
      _showNotice('녹음을 보관함에 저장했어요.');
    } catch (error) {
      _showNotice('녹음이 너무 짧아 저장하지 못했어요.');
      debugPrint('녹음 중지 실패: $error');
    } finally {
      if (mounted) {
        setState(() {
          _recording = false;
          _busy = false;
        });
      }
    }
    await _loadRecordings();
  }

  String _clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  String _recordingTitle(DateTime time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$period ${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} 녹음';
  }

  String _recordingDetail(Recording recording) {
    final kb = (recording.sizeBytes / 1024).ceil();
    final status = _playingPath == recording.path ? _playback : null;
    if (status == null) return '${kb}KB';
    return '${_clock(status.position.inSeconds)} / '
        '${_clock(status.duration.inSeconds)} · ${kb}KB';
  }

  double _progressOf(Recording recording) {
    final status = _playingPath == recording.path ? _playback : null;
    if (status == null || status.duration.inMilliseconds == 0) return 0;
    return (status.position.inMilliseconds / status.duration.inMilliseconds)
        .clamp(0, 1)
        .toDouble();
  }

  /// 녹음을 논리적 날짜별로 묶는다. 날짜와 녹음 모두 최신순이다.
  Map<DateTime, List<Recording>> _groupByLogicalDate() {
    final dates = LogicalDateService(dayTurnoverHour: widget.turnoverHour);
    final sorted = [..._recordings]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final groups = <DateTime, List<Recording>>{};
    for (final recording in sorted) {
      final date = dates.logicalDateOf(recording.recordedAt);
      groups.putIfAbsent(date, () => []).add(recording);
    }
    return groups;
  }

  String _groupLabel(DateTime date) =>
      LogicalDateService.isSameDate(date, widget.logicalToday)
      ? '오늘 · ${koreanDate(date)}'
      : koreanDate(date);

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    children: [
      Row(
        children: [
          const Icon(Icons.circle, size: 9, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            '논리적 오늘 · ${koreanDate(widget.logicalToday)}',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        '말로 남기는\n오늘의 기록.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      const Text(
        '바쁜 하루도 잠깐의 목소리로 남겨 보세요.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 26),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.forest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22183B32),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '나의 하루 기록',
              style: TextStyle(
                color: AppColors.mint,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '지금 떠오르는 이야기를 해주세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _SoundBars(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _recording ? '녹음 중' : '녹음할 준비가 되었어요',
                  style: const TextStyle(
                    color: Color(0xFFC8E1D4),
                    fontSize: 13,
                  ),
                ),
                Text(
                  _clock(_elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0x44FFFFFF), height: 28),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _recording || _busy ? null : _startRecording,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: AppColors.forest,
                      disabledBackgroundColor: const Color(0x77BDEAAC),
                    ),
                    icon: const Icon(Icons.fiber_manual_record, size: 18),
                    label: const Text('녹음 시작'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recording && !_busy ? _stopRecording : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0x88FFFFFF),
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: Color(0x66FFFFFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('녹음 중지'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '녹음은 앱 저장소에 보관 기간 동안 보관돼요.',
              style: TextStyle(color: Color(0xFFBAD0C4), fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: widget.onCreateDiary,
        icon: const Icon(Icons.auto_stories_outlined),
        label: const Text('오늘의 일기 만들기'),
      ),
      const SizedBox(height: 34),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('녹음 보관함', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 5),
              Text(
                '저장된 녹음 ${_recordings.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          Text(
            '보관 기간 ${widget.retentionDays}일',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_recordings.isEmpty)
        const Text('아직 저장된 녹음이 없어요.', style: TextStyle(color: AppColors.muted)),
      for (final group in _groupByLogicalDate().entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(
            _groupLabel(group.key),
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final recording in group.value) ...[
          _AudioPreviewCard(
            title: _recordingTitle(recording.recordedAt),
            time: _recordingDetail(recording),
            playing: _playingPath == recording.path,
            progress: _progressOf(recording),
            onPlay: _recording ? null : () => _togglePlayback(recording),
            onExport: () => _export(recording),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ],
  );
}

class _SoundBars extends StatelessWidget {
  const _SoundBars();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(25, (index) {
        final height = <double>[
          24,
          35,
          54,
          74,
          26,
          16,
          35,
          54,
          26,
          74,
          24,
          35,
          54,
          16,
          26,
          74,
          35,
          54,
          24,
          16,
          35,
          74,
          54,
          26,
          16,
        ][index];
        return Flexible(
          child: Container(
            width: 5,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      }),
    ),
  );
}

class _AudioPreviewCard extends StatelessWidget {
  const _AudioPreviewCard({
    required this.title,
    required this.time,
    required this.playing,
    required this.progress,
    required this.onPlay,
    required this.onExport,
  });

  final String title;
  final String time;
  final bool playing;
  final double progress;

  /// 녹음 중에는 null이라 재생 버튼이 비활성화된다.
  final VoidCallback? onPlay;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        IconButton.filledTonal(
          onPressed: onPlay,
          tooltip: playing ? '$title 정지' : '$title 재생',
          icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.border,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onExport,
          tooltip: '$title 다운로드/내보내기',
          icon: const Icon(
            Icons.file_download_outlined,
            color: AppColors.forest,
          ),
        ),
      ],
    ),
  );
}
