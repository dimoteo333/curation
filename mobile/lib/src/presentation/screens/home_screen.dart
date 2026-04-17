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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '나 요즘 왜 이렇게 무기력하지?');
  }

  @override
  void dispose() {
    _controller.dispose();
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
                      const SizedBox(height: 44),
                      const _HomeHero(),
                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      const SizedBox(height: 28),
                      _QuestionComposer(
                        controller: _controller,
                        isLoading: state.isLoading,
                        errorMessage: state.errorMessage,
                        onSubmit: () =>
                            controller.submitQuestion(_controller.text),
                      ),
                      const SizedBox(height: 42),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: state.response == null
                            ? const _EmptyInsightSection(
                                key: ValueKey('empty-insight'),
                              )
                            : _ResponseInsightSection(
                                key: ValueKey(state.response!.insightTitle),
                                response: state.response!,
                                lastQuestion: state.lastQuestion,
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
    return Row(
      children: [
        const Spacer(),
        _PressScaleButton(
          key: const Key('openSettingsButton'),
          label: '설정',
          tooltip: '설정 열기',
          onTap: onOpenSettings,
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
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final TextEditingController controller;
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
                isLoading ? '당신의 기록을 조용히 다시 읽는 중입니다.' : '짧은 문장 하나면 충분합니다.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 16),
            _PressScaleButton(
              key: const Key('submitQuestionButton'),
              label: isLoading ? '읽는 중...' : '읽어보기',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 인사이트', style: theme.textTheme.labelSmall),
        const SizedBox(height: 22),
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
    );
  }
}

class _ResponseInsightSection extends StatelessWidget {
  const _ResponseInsightSection({
    super.key,
    required this.response,
    required this.lastQuestion,
  });

  final CuratedResponse response;
  final String lastQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final firstRecord = response.supportingRecords.isEmpty
        ? null
        : response.supportingRecords.first;

    return Column(
      key: const Key('responseSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 인사이트', style: theme.textTheme.labelSmall),
        const SizedBox(height: 22),
        if (lastQuestion.isNotEmpty) ...[
          Text(
            '질문  $lastQuestion',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          '“${response.answer}”',
          style: theme.textTheme.headlineMedium?.copyWith(height: 1.55),
        ),
        const SizedBox(height: 18),
        Text(
          '── ${firstRecord?.title ?? response.insightTitle}',
          style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
        ),
        const SizedBox(height: 12),
        Text(
          response.summary,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
        ),
        if (response.suggestedFollowUp.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '다음에는 ${response.suggestedFollowUp}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
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
    this.tooltip,
  });

  final String label;
  final VoidCallback? onTap;
  final String? tooltip;

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
            message: widget.tooltip ?? widget.label,
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
