import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/input_sanitizer.dart';
import '../../domain/entities/curated_response.dart';
import '../../state/curation_controller.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/source_icon.dart';
import 'memory_sheet.dart';

class AnswerScreen extends ConsumerStatefulWidget {
  const AnswerScreen({super.key, required this.question});

  final String question;

  @override
  ConsumerState<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends ConsumerState<AnswerScreen> {
  late final TextEditingController _followUpController;
  Timer? _streamTimer;
  String? _activeAnswer;
  int _revealedParagraphs = 0;
  bool _streaming = true;
  bool? _helpful;
  String? _followUpError;

  @override
  void initState() {
    super.initState();
    _followUpController = TextEditingController();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(curationControllerProvider);
    final response = state.response;
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    if (response != null && response.answer != _activeAnswer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && response.answer != _activeAnswer) {
          _startStreaming(response.answer);
        }
      });
    }
    if (response == null) {
      _activeAnswer = null;
      _revealedParagraphs = 0;
      _streaming = true;
    }

    final paragraphs = _paragraphsFrom(response?.answer);
    final citedRecords = _orderedCitedRecords(response, paragraphs);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CuratorBackdrop(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 138),
                children: [
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: (state.isLoading || _streaming)
                            ? Row(
                                key: const ValueKey('thinking'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _ThinkingDots(),
                                  const SizedBox(width: 6),
                                  Text(
                                    '생각 중…',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'IBMPlexSansKR',
                                      color: palette.ink3,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '${citedRecords.length}개의 기록을 참고함',
                                key: const ValueKey('supporting-count'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  color: palette.ink3,
                                ),
                              ),
                      ),
                      const Spacer(),
                      _CircleButton(
                        icon: Icons.share_outlined,
                        onTap: _shareComingSoon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _QueryCard(question: widget.question),
                  const SizedBox(height: 24),
                  if (state.isLoading && response == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 42),
                      child: Column(
                        children: [
                          const _ThinkingDots(large: true),
                          const SizedBox(height: 12),
                          Text(
                            '기록을 다시 읽고 있습니다',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'IBMPlexSansKR',
                              color: palette.ink3,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (response == null && state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.line),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          color: theme.colorScheme.error,
                        ),
                      ),
                    )
                  else if (response != null) ...[
                    if (paragraphs.isNotEmpty)
                      for (var index = 0; index < _revealedParagraphs; index += 1) ...[
                        _AnimatedEssayParagraph(
                          key: ValueKey('paragraph-$index-${paragraphs[index]}'),
                          textSpans: _buildParagraphSpans(
                            context,
                            paragraph: paragraphs[index],
                            citedRecords: response.supportingRecords,
                          ),
                          showCaret: _streaming && index == _revealedParagraphs - 1,
                        ),
                        if (index != _revealedParagraphs - 1)
                          const SizedBox(height: 18),
                      ],
                    if (!_streaming) ...[
                      const SizedBox(height: 28),
                      _SupportingRecordsSection(
                        records: citedRecords,
                        onOpenRecord: _openRecord,
                      ),
                      const SizedBox(height: 20),
                      _FeedbackCard(
                        helpful: _helpful,
                        onSelect: (value) => setState(() => _helpful = value),
                      ),
                    ],
                  ],
                ],
              ),
              _FollowUpBar(
                controller: _followUpController,
                errorText: _followUpError,
                onVoiceTap: _showVoiceComingSoon,
                onSend: _submitFollowUp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startStreaming(String answer) {
    _streamTimer?.cancel();
    _activeAnswer = answer;
    final paragraphs = _paragraphsFrom(answer);
    if (paragraphs.isEmpty) {
      setState(() {
        _revealedParagraphs = 0;
        _streaming = false;
      });
      return;
    }
    setState(() {
      _revealedParagraphs = 1;
      _streaming = paragraphs.length > 1;
    });
    if (paragraphs.length == 1) {
      return;
    }
    _streamTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_revealedParagraphs >= paragraphs.length) {
          _streaming = false;
          timer.cancel();
          return;
        }
        _revealedParagraphs += 1;
        _streaming = _revealedParagraphs < paragraphs.length;
      });
    });
  }

  List<String> _paragraphsFrom(String? rawAnswer) {
    if (rawAnswer == null || rawAnswer.trim().isEmpty) {
      return const <String>[];
    }
    return rawAnswer
        .split(RegExp(r'\n\s*\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<InlineSpan> _buildParagraphSpans(
    BuildContext context, {
    required String paragraph,
    required List<SupportingRecord> citedRecords,
  }) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final result = <InlineSpan>[];
    final citationPattern = RegExp(r'\{\{CITE:([a-zA-Z0-9_\-]+)\}\}');
    var lastEnd = 0;
    for (final match in citationPattern.allMatches(paragraph)) {
      if (match.start > lastEnd) {
        result.add(
          TextSpan(
            text: paragraph.substring(lastEnd, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              height: 1.85,
              color: palette.ink,
            ),
          ),
        );
      }
      final recordId = match.group(1)!;
      final citationIndex = citedRecords.indexWhere((record) => record.id == recordId);
      if (citationIndex >= 0) {
        final record = citedRecords[citationIndex];
        result.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: _CitationChip(
                number: citationIndex + 1,
                onTap: () => _openRecord(record),
              ),
            ),
          ),
        );
      }
      lastEnd = match.end;
    }
    if (lastEnd < paragraph.length) {
      result.add(
        TextSpan(
          text: paragraph.substring(lastEnd),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.85,
            color: palette.ink,
          ),
        ),
      );
    }
    return result;
  }

  List<SupportingRecord> _orderedCitedRecords(
    CuratedResponse? response,
    List<String> paragraphs,
  ) {
    if (response == null) {
      return const <SupportingRecord>[];
    }
    final byId = {
      for (final record in response.supportingRecords) record.id: record,
    };
    final ordered = <SupportingRecord>[];
    final seen = <String>{};
    final citationPattern = RegExp(r'\{\{CITE:([a-zA-Z0-9_\-]+)\}\}');
    for (final paragraph in paragraphs) {
      for (final match in citationPattern.allMatches(paragraph)) {
        final id = match.group(1)!;
        if (seen.add(id) && byId.containsKey(id)) {
          ordered.add(byId[id]!);
        }
      }
    }
    for (final record in response.supportingRecords) {
      if (seen.add(record.id)) {
        ordered.add(record);
      }
    }
    return ordered;
  }

  void _openRecord(SupportingRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x802A1F17),
      builder: (_) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: MemorySheet(
            record: MemorySheetRecord.fromSupportingRecord(record),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFollowUp() async {
    final normalizedQuestion = _validateQuestion(_followUpController.text);
    if (normalizedQuestion == null) {
      return;
    }
    setState(() => _followUpError = null);
    unawaited(
      ref.read(curationControllerProvider.notifier).submitQuestion(
            normalizedQuestion,
          ),
    );
    if (!mounted) {
      return;
    }
    _followUpController.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AnswerScreen(question: normalizedQuestion),
      ),
    );
  }

  String? _validateQuestion(String rawQuestion) {
    try {
      return InputSanitizer.sanitizeQuestion(rawQuestion);
    } on InputValidationException catch (error) {
      setState(() => _followUpError = error.message);
      return null;
    } catch (error) {
      setState(() => _followUpError = error.toString());
      return null;
    }
  }

  void _showVoiceComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('음성 입력은 곧 지원됩니다.')),
    );
  }

  void _shareComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능은 곧 지원됩니다.')),
    );
  }
}

class _QueryCard extends StatelessWidget {
  const _QueryCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.terra.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.terra.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '질문',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexSansKR',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: palette.terraDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEssayParagraph extends StatelessWidget {
  const _AnimatedEssayParagraph({
    super.key,
    required this.textSpans,
    required this.showCaret,
  });

  final List<InlineSpan> textSpans;
  final bool showCaret;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: RichText(
        text: TextSpan(
          children: [
            ...textSpans,
            if (showCaret)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _BlinkingCaret(color: palette.terra),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret({required this.color});

  final Color color;

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: Container(
        width: 6,
        height: 18,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots({this.large = false});

  final bool large;

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    final width = widget.large ? 6.0 : 4.0;
    final minHeight = widget.large ? 8.0 : 4.0;
    final maxHeight = widget.large ? 14.0 : 8.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (index) {
            final phase = ((_controller.value + index * 0.18) % 1.0);
            final pulse = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            final height = minHeight + (maxHeight - minHeight) * pulse;
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 3),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: palette.terra,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({
    required this.number,
    required this.onTap,
  });

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: palette.terra.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.terra.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 11,
              color: palette.terraDeep,
            ),
            const SizedBox(width: 4),
            Text(
              '$number',
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                fontWeight: FontWeight.w700,
                color: palette.terraDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportingRecordsSection extends StatelessWidget {
  const _SupportingRecordsSection({
    required this.records,
    required this.onOpenRecord,
  });

  final List<SupportingRecord> records;
  final ValueChanged<SupportingRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '참고한 기록',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: palette.ink3,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette.paper2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${records.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  color: palette.ink3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < records.length; index += 1) ...[
          _SupportingRecordCard(
            number: index + 1,
            record: records[index],
            onTap: () => onOpenRecord(records[index]),
          ),
          if (index != records.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SupportingRecordCard extends StatelessWidget {
  const _SupportingRecordCard({
    required this.number,
    required this.record,
    required this.onTap,
  });

  final int number;
  final SupportingRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final sourceId = _normalizeSourceId(record.importSource ?? record.source);
    final mood = _memoryMoodLabel(record.metadata['mood']?.toString());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.line),
          boxShadow: palette.shadowSoft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.terra,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFFDF6EC),
                  fontFamily: 'GowunBatang',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SourceIcon(
                        source: sourceId,
                        size: 12,
                        color: palette.ink3,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${record.source} · ${_formatShortDate(record.createdAt)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          color: palette.ink3,
                        ),
                      ),
                      const Spacer(),
                      if (mood != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.paper2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            mood,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFamily: 'IBMPlexSansKR',
                              fontSize: 10,
                              color: palette.ink3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'IBMPlexSansKR',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.content ?? record.excerpt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'IBMPlexSansKR',
                      fontSize: 12,
                      color: palette.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.helpful,
    required this.onSelect,
  });

  final bool? helpful;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    Widget option({
      required bool value,
      required IconData icon,
    }) {
      final active = helpful == value;
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelect(value),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active ? palette.terra : palette.paper2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? palette.terraDeep : palette.line),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? const Color(0xFFFDF6EC) : palette.ink2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '답변이 도움이 되었나요?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '기록 검색 품질을 개선하는 데 사용됩니다',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    color: palette.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          option(value: true, icon: Icons.thumb_up_alt_outlined),
          const SizedBox(width: 6),
          option(value: false, icon: Icons.thumb_down_alt_outlined),
        ],
      ),
    );
  }
}

class _FollowUpBar extends StatelessWidget {
  const _FollowUpBar({
    required this.controller,
    required this.errorText,
    required this.onVoiceTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onVoiceTap;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.line2),
                boxShadow: palette.shadowCard,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => onSend(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'IBMPlexSansKR',
                        fontSize: 14,
                        color: palette.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: '더 물어보기…',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          fontSize: 14,
                          color: palette.ink3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.mic_none_rounded,
                    filled: true,
                    onTap: onVoiceTap,
                  ),
                  const SizedBox(width: 6),
                  _CircleButton(
                    icon: Icons.arrow_upward_rounded,
                    filled: true,
                    accent: true,
                    onTap: () => onSend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    final background = accent
        ? palette.terra
        : filled
        ? palette.paper2
        : Colors.white.withValues(alpha: 0.7);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: accent ? palette.terraDeep : palette.line,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: accent ? const Color(0xFFFDF6EC) : palette.ink2,
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}.$month.$day';
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
