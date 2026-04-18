import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/life_record.dart';
import '../../providers.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/source_icon.dart';
import 'memory_sheet.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final Set<String> _selectedSources = <String>{'diary', 'calendar', 'memo'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final records = ref.watch(localLifeRecordsProvider);

    return CuratorBackdrop(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.terra,
          onRefresh: () async {
            ref.invalidate(localLifeRecordsProvider);
            await ref.read(localLifeRecordsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 112),
            children: [
              Row(
                children: [
                  Text(
                    '타임라인',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('필터 옵션은 아래 칩에서 조절할 수 있습니다.')),
                      );
                    },
                    child: Ink(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.line),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: palette.ink2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SourceFilterChip(
                    label: '일기',
                    active: _selectedSources.contains('diary'),
                    onTap: () => _toggleSource('diary'),
                  ),
                  _SourceFilterChip(
                    label: '캘린더',
                    active: _selectedSources.contains('calendar'),
                    onTap: () => _toggleSource('calendar'),
                  ),
                  _SourceFilterChip(
                    label: '메모',
                    active: _selectedSources.contains('memo'),
                    onTap: () => _toggleSource('memo'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              records.when(
                data: (value) => _TimelineBody(
                  records: _applyFilter(value),
                  onOpenRecord: _openRecord,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    '기록을 불러오지 못했습니다: $error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LifeRecord> _applyFilter(List<LifeRecord> records) {
    return records.where((record) {
      return _selectedSources.contains(_timelineSourceId(record.importSource));
    }).toList(growable: false);
  }

  void _toggleSource(String source) {
    setState(() {
      if (_selectedSources.contains(source)) {
        if (_selectedSources.length > 1) {
          _selectedSources.remove(source);
        }
      } else {
        _selectedSources.add(source);
      }
    });
  }

  void _openRecord(LifeRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x802A1F17),
      builder: (_) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: MemorySheet(record: MemorySheetRecord.fromLifeRecord(record)),
        ),
      ),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.records,
    required this.onOpenRecord,
  });

  final List<LifeRecord> records;
  final ValueChanged<LifeRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.line),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 28,
              color: palette.ink3,
            ),
            const SizedBox(height: 12),
            Text(
              '아직 기록이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              '설정 탭에서 파일이나 캘린더를 가져오면 타임라인에 바로 나타납니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                color: palette.ink3,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupRecords(records);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in grouped.entries) ...[
          Text(
            section.key,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexSansKR',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: palette.ink3,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < section.value.length; index += 1) ...[
            _TimelineRecordCard(
              record: section.value[index],
              onTap: () => onOpenRecord(section.value[index]),
            ),
            if (index != section.value.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _TimelineRecordCard extends StatelessWidget {
  const _TimelineRecordCard({
    required this.record,
    required this.onTap,
  });

  final LifeRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final mood = _timelineMood(record.metadata['mood']?.toString());
    final sourceId = _timelineSourceId(record.importSource);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.line),
          boxShadow: palette.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.paper2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SourceIcon(
                      source: sourceId,
                      size: 14,
                      color: palette.terraDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  record.source,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    color: palette.ink3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              record.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                fontSize: 13.5,
                height: 1.45,
                color: palette.ink2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Text(
                  _timelineDate(record.createdAt),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    color: palette.ink3,
                  ),
                ),
                if (mood != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.terra.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: palette.terra.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      mood,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontFamily: 'IBMPlexSansKR',
                        fontSize: 10,
                        color: palette.terraDeep,
                      ),
                    ),
                  ),
              ],
            ),
            if (record.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in record.tags.take(4))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.ink.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.line2),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          fontSize: 10,
                          color: palette.ink2,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceFilterChip extends StatelessWidget {
  const _SourceFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? palette.terra : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? palette.terraDeep : palette.line,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'IBMPlexSansKR',
            color: active ? const Color(0xFFFDF6EC) : palette.ink2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

Map<String, List<LifeRecord>> _groupRecords(List<LifeRecord> records) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final result = <String, List<LifeRecord>>{
    '오늘': <LifeRecord>[],
    '어제': <LifeRecord>[],
    '이번 주': <LifeRecord>[],
    '이번 달': <LifeRecord>[],
    '더 오래 전': <LifeRecord>[],
  };

  for (final record in records) {
    final date = DateTime(record.createdAt.year, record.createdAt.month, record.createdAt.day);
    final difference = today.difference(date).inDays;
    if (difference <= 0) {
      result['오늘']!.add(record);
    } else if (difference == 1) {
      result['어제']!.add(record);
    } else if (difference < 7) {
      result['이번 주']!.add(record);
    } else if (record.createdAt.year == now.year &&
        record.createdAt.month == now.month) {
      result['이번 달']!.add(record);
    } else {
      result['더 오래 전']!.add(record);
    }
  }

  return Map<String, List<LifeRecord>>.fromEntries(
    result.entries.where((entry) => entry.value.isNotEmpty),
  );
}

String _timelineSourceId(String source) {
  return switch (source.toLowerCase()) {
    'file' => 'memo',
    'note' => 'memo',
    _ => source.toLowerCase(),
  };
}

String? _timelineMood(String? mood) {
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

String _timelineDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}.$month.$day';
}
