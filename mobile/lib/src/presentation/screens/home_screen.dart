import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/curated_response.dart';
import '../../state/curation_controller.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _controller;
  late final FocusNode _questionFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '나 요즘 왜 이렇게 무기력하지?');
    _questionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _questionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(curationControllerProvider);
    final controller = ref.read(curationControllerProvider.notifier);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CuratorBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth > 720
                  ? 720.0
                  : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 40),
                    children: [
                      _HomeTopBar(
                        onOpenSettings: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _HomeHero(),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      _QuestionComposer(
                        controller: _controller,
                        focusNode: _questionFocusNode,
                        isLoading: state.isLoading,
                        errorMessage: state.errorMessage,
                        onSubmit: () =>
                            controller.submitQuestion(_controller.text),
                      ),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: state.isLoading
                            ? const _ThinkingInsightSection(
                                key: ValueKey('thinking-insight'),
                              )
                            : state.response == null
                            ? const _EmptyInsightSection(
                                key: ValueKey('empty-insight'),
                              )
                            : _ResponseInsightSection(
                                key: ValueKey(state.response!.insightTitle),
                                response: state.response!,
                                lastQuestion: state.lastQuestion,
                                onAskAnotherQuestion: () {
                                  controller.startNewQuestion();
                                  _controller.clear();
                                  _questionFocusNode.requestFocus();
                                },
                              ),
                      ),
                      const SizedBox(height: 48),
                      const _DisclaimerLine(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.surfaceStrong.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.outline.withValues(alpha: 0.26)),
          ),
          child: Image.asset('assets/branding/curator_mark.png'),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('큐레이터', style: theme.textTheme.titleLarge)),
        Tooltip(
          message: '설정 열기',
          child: IconButton.filledTonal(
            key: const Key('openSettingsButton'),
            onPressed: onOpenSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('큐레이터', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 10),
        Text(
          '당신의 하루를 읽습니다',
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
        ),
      ],
    );
  }
}

class _QuestionComposer extends StatelessWidget {
  const _QuestionComposer({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('questionTextField'),
          controller: controller,
          focusNode: focusNode,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!isLoading) {
              onSubmit();
            }
          },
          decoration: const InputDecoration(hintText: '무엇이 궁금하신가요?'),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                isLoading ? '당신의 기록을 조용히 다시 읽고 있습니다.' : '짧은 문장 하나면 충분합니다.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 16),
            _PressScaleButton(
              key: const Key('submitQuestionButton'),
              label: isLoading ? '생각 중...' : '읽어보기',
              onTap: isLoading ? null : onSubmit,
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (!isLoading) ...[
          const SizedBox(height: 12),
          Text(
            '예: 이번 주에 왜 이렇게 쉽게 지쳤을까요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.label.withValues(alpha: 0.82),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyInsightSection extends StatelessWidget {
  const _EmptyInsightSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return _InsightCardShell(
      eyebrow: '최근 인사이트',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"야근이 많았던 3월,\n당신의 무기력함은\n당연한 것이었습니다"',
            style: theme.textTheme.headlineMedium?.copyWith(height: 1.48),
          ),
          const SizedBox(height: 18),
          Text(
            '── 3개월 전 야근 회고',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
          ),
        ],
      ),
    );
  }
}

class _ThinkingInsightSection extends StatelessWidget {
  const _ThinkingInsightSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return _InsightCardShell(
      eyebrow: '기록을 읽는 중',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.accentSoft.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(child: _ThinkingDots()),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '가장 가까운 기록과 문장을 고르고 있습니다.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.accentStrong,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '질문과 닿는 시간, 제목, 감정의 흐름을 조용히 엮는 중입니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseInsightSection extends StatelessWidget {
  const _ResponseInsightSection({
    super.key,
    required this.response,
    required this.lastQuestion,
    required this.onAskAnotherQuestion,
  });

  final CuratedResponse response;
  final String lastQuestion;
  final VoidCallback onAskAnotherQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final firstRecord = response.supportingRecords.isEmpty
        ? null
        : response.supportingRecords.first;

    return _InsightCardShell(
      key: const Key('responseSection'),
      eyebrow: '최근 인사이트',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastQuestion.isNotEmpty) ...[
            Text(
              '질문  $lastQuestion',
              style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
            ),
            const SizedBox(height: 18),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: palette.outline.withValues(alpha: 0.32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.insightTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.accentStrong,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  response.answer,
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
          if (firstRecord != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: palette.surfaceStrong.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: palette.outline.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatAbsoluteDate(firstRecord.createdAt)}  ${firstRecord.title}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.label,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    firstRecord.excerpt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            response.summary,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
          if (response.suggestedFollowUp.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              response.suggestedFollowUp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.accentStrong,
              ),
            ),
          ],
          const SizedBox(height: 26),
          OutlinedButton(
            key: const Key('askAnotherQuestionButton'),
            onPressed: onAskAnotherQuestion,
            child: const Text('다른 질문하기'),
          ),
        ],
      ),
    );
  }

  String _formatAbsoluteDate(DateTime value) {
    return '${value.year}년 ${value.month}월 ${value.day}일';
  }
}

class _InsightCardShell extends StatelessWidget {
  const _InsightCardShell({
    super.key,
    required this.eyebrow,
    required this.child,
  });

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            palette.surfaceStrong.withValues(alpha: 0.94),
            palette.surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.outline.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: theme.textTheme.labelSmall),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final distance = (phase - index * 0.16).abs();
            final opacity = (1 - distance * 2.4).clamp(0.22, 1.0);
            final size = 7.0 + (1 - distance.clamp(0.0, 0.5) * 2) * 3;
            return Container(
              width: size,
              height: size,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
              decoration: BoxDecoration(
                color: palette.accentStrong.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _DisclaimerLine extends StatelessWidget {
  const _DisclaimerLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      '의학·심리 진단이 아닌 개인 기록 해석 도구입니다.',
      style: theme.textTheme.bodySmall,
    );
  }
}

class _PressScaleButton extends StatefulWidget {
  const _PressScaleButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    final text = Text(
      widget.label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: widget.onTap == null
            ? palette.label.withValues(alpha: 0.6)
            : palette.accentStrong,
        decoration: TextDecoration.underline,
        decorationColor: widget.onTap == null
            ? palette.label.withValues(alpha: 0.4)
            : palette.accentStrong.withValues(alpha: 0.56),
        decorationThickness: 0.7,
      ),
    );

    return Semantics(
      button: true,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.98 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: Tooltip(
            message: widget.label,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                setState(() => _pressed = value);
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
