import 'package:flutter/material.dart';

import '../../domain/entities/curated_response.dart';
import '../../domain/entities/life_record.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/source_icon.dart';

class MemorySheetRecord {
  const MemorySheetRecord({
    required this.id,
    required this.sourceId,
    required this.sourceLabel,
    required this.createdAt,
    required this.title,
    required this.content,
    required this.tags,
    this.location,
    this.mood,
  });

  factory MemorySheetRecord.fromSupportingRecord(SupportingRecord record) {
    return MemorySheetRecord(
      id: record.id,
      sourceId: _normalizeSourceId(record.importSource ?? record.source),
      sourceLabel: record.source,
      createdAt: record.createdAt,
      title: record.title,
      content: record.content ?? record.excerpt,
      tags: record.tags,
      location: record.metadata['location']?.toString(),
      mood: _memoryMoodLabel(record.metadata['mood']?.toString()),
    );
  }

  factory MemorySheetRecord.fromLifeRecord(LifeRecord record) {
    return MemorySheetRecord(
      id: record.id,
      sourceId: _normalizeSourceId(record.importSource),
      sourceLabel: record.source,
      createdAt: record.createdAt,
      title: record.title,
      content: record.content,
      tags: record.tags,
      location: record.metadata['location']?.toString(),
      mood: _memoryMoodLabel(record.metadata['mood']?.toString()),
    );
  }

  final String id;
  final String sourceId;
  final String sourceLabel;
  final DateTime createdAt;
  final String title;
  final String content;
  final List<String> tags;
  final String? location;
  final String? mood;
}

class MemorySheet extends StatelessWidget {
  const MemorySheet({super.key, required this.record});

  final MemorySheetRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.64,
      initialChildSize: 0.82,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 48,
                offset: const Offset(0, -18),
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
                            border: Border.all(
                              color: palette.terra.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SourceIcon(
                                source: record.sourceId,
                                size: 12,
                                color: palette.terraDeep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                record.sourceLabel,
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
                              color: palette.ink.withValues(alpha: 0.08),
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
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              _memoryDate(record.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'IBMPlexSansKR',
                                color: palette.ink3,
                              ),
                            ),
                            if (record.location != null &&
                                record.location!.isNotEmpty) ...[
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: palette.ink4,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              Text(
                                record.location!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  color: palette.ink3,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (record.mood != null)
                              _TagChip(label: record.mood!, accent: true),
                            for (final tag in record.tags)
                              _TagChip(label: '#$tag'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          record.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            height: 1.8,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _MemoryActionButton(
                                label: '내보내기',
                                icon: Icons.download_rounded,
                                onTap: () => _showActionMessage(
                                  context,
                                  '내보내기 기능은 곧 지원됩니다.',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MemoryActionButton(
                                label: '이 기록 제외',
                                icon: Icons.remove_circle_outline_rounded,
                                onTap: () => _showActionMessage(
                                  context,
                                  '기록 제외 기능은 곧 지원됩니다.',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MemoryActionButton(
                                label: '원문 열기',
                                accent: true,
                                onTap: () => _showActionMessage(
                                  context,
                                  '원문 열기 기능은 곧 지원됩니다.',
                                ),
                              ),
                            ),
                          ],
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

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MemoryActionButton extends StatelessWidget {
  const _MemoryActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent ? palette.terra : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent ? palette.terraDeep : palette.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: accent ? const Color(0xFFFDF6EC) : palette.ink2,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  fontSize: 13,
                  color: accent ? const Color(0xFFFDF6EC) : palette.ink2,
                  fontWeight: accent ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.accent = false});

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
          color: accent ? palette.terra.withValues(alpha: 0.18) : palette.line2,
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

String _normalizeSourceId(String source) {
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
  return '${value.year}년 ${value.month}월 ${value.day}일';
}
