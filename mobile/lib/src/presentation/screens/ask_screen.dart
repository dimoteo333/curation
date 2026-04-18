import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/curation_controller.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/nav_dock.dart';
import 'answer_screen.dart';
import 'settings_screen.dart';

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.initialQuery});

  final String? initialQuery;

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

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) {
          return;
        }
        _focusNode.requestFocus();
      });
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
    final state = ref.watch(curationControllerProvider);
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: CuratorBackdrop(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 134),
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      Text(
                        '질문하기',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          fontSize: 13,
                          color: palette.ink3,
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
                          text: '무엇이 ',
                          style: TextStyle(color: palette.terraDeep),
                        ),
                        const TextSpan(text: '궁금하세요?\n'),
                        TextSpan(
                          text: '당신의 기록에서만 답을 찾아드립니다.',
                          style: TextStyle(
                            color: palette.ink3,
                            fontSize: 15,
                            fontFamily: 'IBMPlexSansKR',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _focused ? palette.terra : palette.line2,
                      ),
                      boxShadow: _focused ? palette.shadowCard : palette.shadowSoft,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          key: const Key('questionTextField'),
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 4,
                          maxLines: 8,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'IBMPlexSansKR',
                            fontSize: 16,
                            color: palette.ink,
                            height: 1.55,
                          ),
                          decoration: InputDecoration(
                            hintText: '예) 지난 겨울엔 뭘 하면서 기분이 풀렸지?',
                            fillColor: Colors.transparent,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'IBMPlexSansKR',
                              fontSize: 16,
                              color: palette.ink3,
                            ),
                          ),
                          onTap: () => setState(() => _focused = true),
                          onChanged: (_) {
                            if (!_focused) {
                              setState(() => _focused = true);
                            } else {
                              setState(() {});
                            }
                          },
                          onTapOutside: (_) {
                            _focusNode.unfocus();
                            setState(() => _focused = false);
                          },
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 10),
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
                            Text(
                              '음성 입력은 곧 지원됩니다',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontFamily: 'IBMPlexSansKR',
                                color: palette.ink3,
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              key: const Key('submitQuestionButton'),
                              onPressed: state.isLoading ? null : _submit,
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
                                  Text(state.isLoading ? '생각 중...' : '묻기'),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'IBMPlexSansKR',
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _FilterChip(label: '전체 기간', active: true),
                      _FilterChip(label: '지난 1년'),
                      _FilterChip(label: '지난 한 달'),
                      _FilterChip(label: '모든 소스', active: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(title: '이렇게 물어보세요'),
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
                        _focusNode.requestFocus();
                        setState(() => _focused = true);
                      },
                    ),
                    if (index != _samples.length - 1) const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: palette.sage,
                      ),
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
              Align(
                alignment: Alignment.bottomCenter,
                child: NavDock(
                  activeDestination: CuratorNavDestination.ask,
                  onSelected: (destination) {
                    switch (destination) {
                      case CuratorNavDestination.home:
                        Navigator.of(context).maybePop();
                        break;
                      case CuratorNavDestination.ask:
                        break;
                      case CuratorNavDestination.settings:
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final notifier = ref.read(curationControllerProvider.notifier);
    await notifier.submitQuestion(_controller.text);
    if (!mounted) {
      return;
    }

    final state = ref.read(curationControllerProvider);
    if (state.response == null && state.errorMessage != null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnswerScreen(question: state.lastQuestion),
      ),
    );
  }

  void _showVoiceComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('음성 입력은 곧 지원됩니다.')),
    );
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
          color: filled ? palette.paper2 : Colors.white.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: palette.line),
        ),
        child: Icon(
          icon,
          size: 18,
          color: palette.ink2,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.active = false,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          fontWeight: FontWeight.w500,
          color: active ? const Color(0xFFFDF6EC) : palette.ink2,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontFamily: 'IBMPlexSansKR',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: palette.ink3,
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
          color: Colors.white.withValues(alpha: 0.46),
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
                border: Border.all(
                  color: palette.terra.withValues(alpha: 0.2),
                ),
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
