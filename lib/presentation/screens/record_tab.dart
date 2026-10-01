import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/theme/app_theme.dart';

class RecordTab extends StatefulWidget {
  const RecordTab({
    super.key,
    required this.logicalToday,
    required this.retentionDays,
    required this.onCreateDiary,
  });

  final DateTime logicalToday;
  final int retentionDays;
  final VoidCallback onCreateDiary;

  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab> {
  bool _recordingPreview = false;

  void _showMockNotice(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );

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
                  _recordingPreview ? '녹음 화면 미리보기 중' : '녹음할 준비가 되었어요',
                  style: const TextStyle(
                    color: Color(0xFFC8E1D4),
                    fontSize: 13,
                  ),
                ),
                const Text(
                  '00:00',
                  style: TextStyle(
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
                    onPressed: _recordingPreview
                        ? null
                        : () => setState(() => _recordingPreview = true),
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
                    onPressed: _recordingPreview
                        ? () => setState(() => _recordingPreview = false)
                        : null,
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
              '화면 미리보기입니다. 실제 오디오는 녹음되지 않아요.',
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
              Text('오늘의 보관함', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 5),
              Text('저장된 녹음 2', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          Text(
            '보관 기간 ${widget.retentionDays}일',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _AudioPreviewCard(
        title: '아침의 메모',
        time: '오전 09:42 · 00:38',
        onPlay: () => _showMockNotice('예시 오디오입니다. 재생 기능은 아직 연결되지 않았어요.'),
        onExport: () => _showMockNotice('예시 오디오입니다. 내보내기 기능은 아직 연결되지 않았어요.'),
      ),
      const SizedBox(height: 10),
      _AudioPreviewCard(
        title: '퇴근길 생각',
        time: '오후 06:15 · 01:12',
        onPlay: () => _showMockNotice('예시 오디오입니다. 재생 기능은 아직 연결되지 않았어요.'),
        onExport: () => _showMockNotice('예시 오디오입니다. 내보내기 기능은 아직 연결되지 않았어요.'),
      ),
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
    required this.onPlay,
    required this.onExport,
  });

  final String title;
  final String time;
  final VoidCallback onPlay;
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
          tooltip: '$title 재생',
          icon: const Icon(Icons.play_arrow_rounded),
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
                child: const LinearProgressIndicator(
                  value: 0,
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
