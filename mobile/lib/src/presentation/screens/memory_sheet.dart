import 'package:flutter/material.dart';

import '../../domain/entities/curated_response.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/source_icon.dart';

class MemorySheet extends StatelessWidget {
  const MemorySheet({
    super.key,
    required this.record,
    required this.onAskWithRecord,
  });

  final SupportingRecord record;
  final VoidCallback onAskWithRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final mood = _memoryMoodLabel(record.metadata['mood']?.toString());
    final location = record.metadata['location']?.toString();
    final tags = record.tags;
    final content = record.content ?? record.excerpt;

    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.64,
      initialChildSize: 0.82,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, -14),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: PaperGrain(
                  opacity: 0.16,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.ink4.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.terra.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SourceIcon(
                                source: _memorySourceId(
                                  record.importSource ?? record.source,
                                ),
                                size: 12,
                                color: palette.terraDeep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                record.source,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  fontWeight: FontWeight.w600,
                                  color: palette.terraDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.of(context).pop(),
                          child: Ink(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: palette.ink.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: palette.ink2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                      children: [
                        Row(
                          children: [
                            Text(
                              _memoryDate(record.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'IBMPlexSansKR',
                                color: palette.ink3,
                              ),
                            ),
                            if (location != null && location.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: palette.ink4,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  location,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'IBMPlexSansKR',
                                    color: palette.ink3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          record.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 26,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (mood != null) _TagChip(label: mood, accent: true),
                            for (final tag in tags) _TagChip(label: '#$tag'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.line2),
                            gradient: LinearGradient(
                              colors: [palette.paper2, palette.paper3],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Attached record',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  color: palette.ink3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatMemoryShortDate(record.createdAt),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  fontSize: 10,
                                  color: palette.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            height: 1.8,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: onAskWithRecord,
                          child: const Text('이 기록으로 질문하기'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.accent = false,
  });

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? palette.terra.withValues(alpha: 0.1)
            : palette.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent
              ? palette.terra.withValues(alpha: 0.18)
              : palette.line2,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontFamily: 'IBMPlexSansKR',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: accent ? palette.terraDeep : palette.ink2,
        ),
      ),
    );
  }
}

String _memorySourceId(String source) {
  return switch (source.toLowerCase()) {
    '일기' => 'diary',
    '캘린더' => 'calendar',
    '메모' => 'memo',
    '음성 메모' => 'voice_memo',
    'note' => 'memo',
    'file' => 'memo',
    _ => source.toLowerCase(),
  };
}

String? _memoryMoodLabel(String? mood) {
  if (mood == null || mood.isEmpty) {
    return null;
  }
  return switch (mood.toLowerCase()) {
    'drained' => '지침',
    'steady' => '안정',
    'hopeful' => '희망',
    'foggy' => '멍함',
    'pressured' => '압박',
    'fragile' => '예민',
    'lighter' => '가벼움',
    'relieved' => '안도',
    'softer' => '누그러짐',
    'engaged' => '몰입',
    'depleted' => '소진',
    'focused' => '집중',
    'clearer' => '맑아짐',
    _ => mood,
  };
}

String _memoryDate(DateTime value) {
  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${value.year}년 ${value.month}월 ${value.day}일 ${weekdays[value.weekday - 1]}요일';
}

String _formatMemoryShortDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}.$month.$day';
}
