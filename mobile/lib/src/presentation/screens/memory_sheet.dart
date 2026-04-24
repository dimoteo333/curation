import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/curated_response.dart';
import '../../domain/entities/life_record.dart';
import '../../providers.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/source_icon.dart';

class MemorySheetRecord {
  const MemorySheetRecord({
    required this.id,
    required this.sourceId,
    required this.sourceLabel,
    required this.importSource,
    required this.createdAt,
    required this.title,
    required this.content,
    required this.tags,
    this.metadata = const <String, dynamic>{},
    this.location,
    this.mood,
  });

  factory MemorySheetRecord.fromSupportingRecord(SupportingRecord record) {
    return MemorySheetRecord(
      id: record.id,
      sourceId: _normalizeSourceId(record.importSource ?? record.source),
      sourceLabel: record.source,
      importSource: _normalizeImportSource(
        record.importSource ?? record.source,
      ),
      createdAt: record.createdAt,
      title: record.title,
      content: record.content ?? record.excerpt,
      tags: record.tags,
      metadata: record.metadata,
      location: record.metadata['location']?.toString(),
      mood: _memoryMoodLabel(record.metadata['mood']?.toString()),
    );
  }

  factory MemorySheetRecord.fromLifeRecord(LifeRecord record) {
    return MemorySheetRecord(
      id: record.id,
      sourceId: _normalizeSourceId(record.importSource),
      sourceLabel: record.source,
      importSource: _normalizeImportSource(record.importSource),
      createdAt: record.createdAt,
      title: record.title,
      content: record.content,
      tags: record.tags,
      metadata: record.metadata,
      location: record.metadata['location']?.toString(),
      mood: _memoryMoodLabel(record.metadata['mood']?.toString()),
    );
  }

  final String id;
  final String sourceId;
  final String sourceLabel;
  final String importSource;
  final DateTime createdAt;
  final String title;
  final String content;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? location;
  final String? mood;

  Map<String, dynamic> toExportJson() {
    return <String, dynamic>{
      'id': id,
      'source_type': sourceId,
      'source_label': sourceLabel,
      'import_source': importSource,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'content': content,
      'tags': tags,
      if (location != null) 'location': location,
      if (mood != null) 'mood': mood,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  String toExportText() {
    final lines = <String>[
      title,
      '${_memoryDate(createdAt)} · $sourceLabel',
      if (location != null && location!.isNotEmpty) '장소: $location',
      if (mood != null && mood!.isNotEmpty) '기분: $mood',
      if (tags.isNotEmpty) '태그: ${tags.map((tag) => '#$tag').join(' ')}',
      '',
      content,
    ];
    if (metadata.isNotEmpty) {
      lines
        ..add('')
        ..add('[메타데이터]');
      for (final entry in _sortedMetadataEntries(metadata)) {
        lines.add(
          '${_metadataLabel(entry.key)}: ${_metadataValue(entry.value)}',
        );
      }
    }
    return lines.join('\n');
  }
}

class MemorySheet extends ConsumerWidget {
  const MemorySheet({super.key, required this.record});

  final MemorySheetRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final excludedRecordIds = ref.watch(excludedRecordIdsProvider);
    final isExcluded = excludedRecordIds.contains(record.id);

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
                                onTap: () {
                                  _showExportOptions(context);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MemoryActionButton(
                                label: isExcluded ? '이미 제외됨' : '이 기록 제외',
                                icon: Icons.remove_circle_outline_rounded,
                                onTap: isExcluded
                                    ? null
                                    : () {
                                        unawaited(_excludeRecord(context, ref));
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MemoryActionButton(
                                label: '원문 열기',
                                accent: true,
                                onTap: () => _openOriginalSource(context),
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

  Future<void> _excludeRecord(BuildContext context, WidgetRef ref) async {
    final didExclude = await ref
        .read(excludedRecordIdsProvider.notifier)
        .excludeRecord(record.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    _showActionMessage(
      context,
      didExclude ? '이 기록은 다음 검색부터 제외됩니다.' : '이미 제외된 기록입니다.',
    );
  }

  Future<void> _showExportOptions(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('기록 내보내기'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_copyExportText(context));
              },
              child: const Text('텍스트 복사'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_copyExportJson(context));
              },
              child: const Text('JSON 복사'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyExportText(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: record.toExportText()));
    if (!context.mounted) {
      return;
    }
    _showActionMessage(context, '기록 텍스트를 클립보드에 복사했습니다.');
  }

  Future<void> _copyExportJson(BuildContext context) async {
    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(record.toExportJson());
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!context.mounted) {
      return;
    }
    _showActionMessage(context, '기록 JSON을 클립보드에 복사했습니다.');
  }

  Future<void> _openOriginalSource(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _SourceDetailDialog(record: record),
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
  final VoidCallback? onTap;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final isEnabled = onTap != null;
    final backgroundColor = accent
        ? palette.terra
        : Colors.white.withValues(alpha: 0.55);
    final foregroundColor = accent ? const Color(0xFFFDF6EC) : palette.ink2;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? backgroundColor
              : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? (accent ? palette.terraDeep : palette.line)
                : palette.line2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isEnabled
                    ? foregroundColor
                    : palette.ink3.withValues(alpha: 0.8),
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
                  color: isEnabled
                      ? foregroundColor
                      : palette.ink3.withValues(alpha: 0.9),
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

class _SourceDetailDialog extends StatelessWidget {
  const _SourceDetailDialog({required this.record});

  final MemorySheetRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadataEntries = _sortedMetadataEntries(record.metadata);
    return AlertDialog(
      title: Text(record.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '직접 열 수 있는 원본 링크가 없어 저장된 상세 정보와 본문을 표시합니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: '출처', value: record.sourceLabel),
              _DetailRow(
                label: '가져온 경로',
                value: _importSourceLabel(record.importSource),
              ),
              _DetailRow(label: '날짜', value: _memoryDate(record.createdAt)),
              if (record.location != null && record.location!.isNotEmpty)
                _DetailRow(label: '장소', value: record.location!),
              if (record.mood != null && record.mood!.isNotEmpty)
                _DetailRow(label: '기분', value: record.mood!),
              if (record.tags.isNotEmpty)
                _DetailRow(
                  label: '태그',
                  value: record.tags.map((tag) => '#$tag').join(' '),
                ),
              if (metadataEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '메타데이터',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final entry in metadataEntries)
                  _DetailRow(
                    label: _metadataLabel(entry.key),
                    value: _metadataValue(entry.value),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                '본문',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                record.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexSansKR',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'IBMPlexSansKR',
              height: 1.5,
            ),
          ),
        ],
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

String _normalizeImportSource(String source) {
  return switch (source.toLowerCase()) {
    '일기' => 'diary',
    '캘린더' => 'calendar',
    '메모' => 'note',
    '음성 메모' => 'voice_memo',
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

List<MapEntry<String, dynamic>> _sortedMetadataEntries(
  Map<String, dynamic> metadata,
) {
  final entries = metadata.entries
      .where((entry) => _metadataValue(entry.value).isNotEmpty)
      .toList(growable: false);
  entries.sort((left, right) => left.key.compareTo(right.key));
  return entries;
}

String _metadataLabel(String key) {
  return switch (key) {
    'calendar_id' => '캘린더 ID',
    'calendar_name' => '캘린더 이름',
    'content_hash' => '콘텐츠 해시',
    'end_time' => '종료 시각',
    'event_id' => '이벤트 ID',
    'file_extension' => '파일 형식',
    'imported_at' => '가져온 시각',
    'is_all_day' => '종일 일정',
    'location' => '장소',
    'modified_at' => '수정 시각',
    'original_file_name' => '원본 파일명',
    'original_file_path' => '원본 파일 경로',
    'parser' => '파서',
    'start_time' => '시작 시각',
    'tag_count' => '태그 수',
    'time_zone' => '시간대',
    _ => key,
  };
}

String _metadataValue(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is bool) {
    return value ? '예' : '아니오';
  }
  if (value is List<dynamic>) {
    return value
        .map(_metadataValue)
        .where((item) => item.isNotEmpty)
        .join(', ');
  }
  final text = value.toString().trim();
  return text;
}

String _importSourceLabel(String importSource) {
  return switch (importSource) {
    'calendar' => '캘린더',
    'diary' => '일기',
    'file' => '파일 가져오기',
    'note' => '메모',
    'voice_memo' => '음성 메모',
    _ => importSource,
  };
}
