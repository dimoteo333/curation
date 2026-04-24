import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/input_sanitizer.dart';
import '../../domain/entities/curation_query_scope.dart';
import '../../providers.dart';
import '../../state/curation_controller.dart';
import '../../state/app_shell_controller.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import 'answer_screen.dart';

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  static const List<({String category, String question})> _samples =
      <({String category, String question})>[
        (category: '감정', question: '나 요즘 왜 이렇게 무기력하지?'),
        (category: '회상', question: '3년 전 봄에 뭐 하면서 즐거웠지?'),
        (category: '패턴', question: '이직 후에 늘 이런 기분이 드나?'),
        (category: '루틴', question: '책 읽기 가장 잘 지켜진 달이 언제였지?'),
      ];

  static const List<({String label, CurationTimeScope scope})> _timeScopeChips =
      <({String label, CurationTimeScope scope})>[
        (label: '전체 기간', scope: CurationTimeScope.allTime),
        (label: '지난 1년', scope: CurationTimeScope.pastYear),
        (label: '지난 한 달', scope: CurationTimeScope.pastMonth),
      ];

  static const String _allSourcesLabel = '모든 소스';

  static const Map<CurationTimeScope, String> _timeScopeLabels =
      <CurationTimeScope, String>{
        CurationTimeScope.allTime: '전체 기간',
        CurationTimeScope.pastYear: '지난 1년',
        CurationTimeScope.pastMonth: '지난 한 달',
      };

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  CurationTimeScope _selectedTimeScope = CurationTimeScope.allTime;
  bool _focused = false;
  String? _inputError;

  String _timeScopeKey(CurationTimeScope scope) {
    return switch (scope) {
      CurationTimeScope.allTime => 'allTime',
      CurationTimeScope.pastYear => 'pastYear',
      CurationTimeScope.pastMonth => 'pastMonth',
    };
  }

  CurationQueryScope get _selectedScope {
    final excludedRecordIds = ref.read(excludedRecordIdsProvider);
    return CurationQueryScope(
      timeScope: _selectedTimeScope,
      excludedRecordIds: excludedRecordIds,
    );
  }

  String get _activeScopeSummary {
    return _timeScopeLabels[_selectedTimeScope]!;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) {
          setState(() => _focused = _focusNode.hasFocus);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final curationState = ref.watch(curationControllerProvider);
    final excludedRecordIds = ref.watch(excludedRecordIdsProvider);

    ref.listen<CuratorAppShellState>(curatorAppShellProvider, (previous, next) {
      final tabChangedToAsk =
          previous?.currentTab != CuratorTab.ask &&
          next.currentTab == CuratorTab.ask;
      final requestChanged = previous?.askRequestId != next.askRequestId;

      if (!tabChangedToAsk && !requestChanged) {
        return;
      }
      if (requestChanged && next.askPrefill != null) {
        _controller.text = next.askPrefill!;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
      setState(() => _inputError = null);
      _focusLater();
    });

    return CuratorBackdrop(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 112),
          children: [
            Row(
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    ref
                        .read(curatorAppShellProvider.notifier)
                        .selectTab(CuratorTab.home);
                  },
                ),
                const Spacer(),
                Text(
                  '질문하기',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    fontSize: 13,
                    color: palette.ink3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '무엇이',
                    style: TextStyle(color: palette.terraDeep),
                  ),
                  const TextSpan(text: ' 궁금하세요?\n'),
                  TextSpan(
                    text: '당신의 기록에서만 답을 찾아드립니다.',
                    style: TextStyle(
                      color: palette.ink3,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'IBMPlexSansKR',
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focused
                      ? palette.terra.withValues(alpha: 0.42)
                      : palette.line2,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: palette.ink.withValues(alpha: 0.08),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: palette.terra.withValues(alpha: 0.08),
                          blurRadius: 0,
                          spreadRadius: 1.5,
                        ),
                      ]
                    : palette.shadowSoft,
              ),
              child: Column(
                children: [
                  CupertinoTextField(
                    key: const Key('questionTextField'),
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 3,
                    maxLines: 8,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'IBMPlexSansKR',
                      fontSize: 16,
                      height: 1.55,
                      color: palette.ink,
                    ),
                    placeholder: '예) 지난 겨울엔 뭘 하면서 기분이 풀렸지?',
                    placeholderStyle: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'IBMPlexSansKR',
                      fontSize: 16,
                      height: 1.55,
                      color: palette.ink3,
                    ),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    decoration: BoxDecoration(
                      color: palette.paper.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _focused
                            ? palette.terra.withValues(alpha: 0.28)
                            : palette.line,
                      ),
                    ),
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) {
                      if (_inputError != null) {
                        setState(() => _inputError = null);
                      } else {
                        setState(() {});
                      }
                    },
                    onSubmitted: (_) => _submit(),
                    onTapOutside: (_) => _focusNode.unfocus(),
                    onEditingComplete: () {},
                    keyboardType: TextInputType.multiline,
                    onTap: () {
                      if (!_focused) {
                        setState(() => _focused = true);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: palette.line),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.mic_none_rounded,
                        filled: true,
                        onTap: _showVoiceComingSoon,
                      ),
                      const SizedBox(width: 8),
                      _CircleIconButton(
                        icon: Icons.photo_camera_outlined,
                        filled: true,
                        onTap: _showPhotoComingSoon,
                      ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('submitQuestionButton'),
                        onPressed: curationState.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(curationState.isLoading ? '생각 중...' : '묻기'),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_inputError != null || curationState.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _inputError ?? curationState.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              '검색 범위',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: palette.ink3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in _timeScopeChips)
                  _ScopeChip(
                    key: Key('scopeChip-${_timeScopeKey(chip.scope)}'),
                    label: chip.label,
                    active: _selectedTimeScope == chip.scope,
                    onTap: () {
                      setState(() => _selectedTimeScope = chip.scope);
                    },
                  ),
                const _ScopeChip(
                  key: Key('scopeChip-allSources'),
                  label: _allSourcesLabel,
                  active: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '현재 범위: $_activeScopeSummary · $_allSourcesLabel'
              '${excludedRecordIds.isEmpty ? '' : ' · 제외 ${excludedRecordIds.length}개'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                color: palette.ink3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '이렇게 물어보세요',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: palette.ink3,
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < _samples.length; index += 1) ...[
              _SamplePromptCard(
                category: _samples[index].category,
                question: _samples[index].question,
                onTap: () {
                  _controller.text = _samples[index].question;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                  setState(() => _inputError = null);
                  _focusLater();
                },
              ),
              if (index != _samples.length - 1) const SizedBox(height: 6),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: palette.sage),
                const SizedBox(width: 6),
                Text(
                  'Gemma-4-E2B · 기기 안에서 처리됨',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final rawQuestion = _controller.text;
    final normalizedQuestion = _validateQuestion(rawQuestion);
    if (normalizedQuestion == null) {
      return;
    }

    setState(() => _inputError = null);
    unawaited(
      ref
          .read(curationControllerProvider.notifier)
          .submitQuestion(normalizedQuestion, scope: _selectedScope),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnswerScreen(question: normalizedQuestion),
      ),
    );
  }

  String? _validateQuestion(String rawQuestion) {
    try {
      return InputSanitizer.sanitizeQuestion(rawQuestion);
    } on InputValidationException catch (error) {
      setState(() => _inputError = error.message);
      return null;
    } catch (error) {
      setState(() => _inputError = error.toString());
      return null;
    }
  }

  void _focusLater() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _showVoiceComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('음성 입력은 곧 지원됩니다.')));
  }

  void _showPhotoComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('사진 첨부는 곧 지원됩니다.')));
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? palette.paper2 : Colors.white.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: palette.line),
        ),
        child: Icon(icon, size: 18, color: palette.ink2),
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    super.key,
    required this.label,
    required this.active,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

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
          border: Border.all(color: active ? palette.terraDeep : palette.line),
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

class _SamplePromptCard extends StatelessWidget {
  const _SamplePromptCard({
    required this.category,
    required this.question,
    required this.onTap,
  });

  final String category;
  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: palette.terra.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.terra.withValues(alpha: 0.2)),
              ),
              child: Text(
                category,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: palette.terraDeep,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'IBMPlexSansKR',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
