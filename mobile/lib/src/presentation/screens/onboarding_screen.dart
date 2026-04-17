import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      headline: '큐\n레이터',
      body: '당신의 일상을\n조용히 지켜봅니다',
      detail: '흩어진 하루의 결을 모아, 당신만의 흐름으로 읽어 드립니다.',
      showMark: true,
    ),
    _OnboardingPageData(
      headline: '모든 건\n당신 기기 안에서',
      body: '외부 전송 없음',
      detail: '온디바이스 모드에서는 질문과 기록이 기본적으로 기기 밖으로 나가지 않습니다.',
    ),
    _OnboardingPageData(
      headline: '시작하기',
      body: '파일을 불러와주세요',
      detail: '설정에서 `.txt`와 `.md` 기록을 가져오면 첫 인사이트를 바로 읽을 수 있습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CuratorBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: _OnboardingPageView(
                          key: ValueKey(_currentPage),
                          data: page,
                          isFirstPage: _currentPage == 0,
                          isLastPage: isLastPage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        for (var i = 0; i < _pages.length; i++) ...[
                          _PageDot(isActive: i == _currentPage),
                          if (i != _pages.length - 1) const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        if (!isLastPage)
                          _PressScaleTextButton(
                            key: const Key('onboardingSkipButton'),
                            label: '건너뛰기 →',
                            onTap: _skipToLastPage,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          _PressScaleTextButton(
                            label: '이전',
                            onTap: _goToPreviousPage,
                          ),
                        const Spacer(),
                        _PressScaleTextButton(
                          key: isLastPage
                              ? const Key('completeOnboardingButton')
                              : const Key('onboardingNextButton'),
                          label: isLastPage ? '시작하기' : '다음 →',
                          onTap: isLastPage
                              ? _completeOnboarding
                              : _goToNextPage,
                          large: isLastPage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '의학·심리 진단이 아닌 기록 해석 도구입니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToNextPage() {
    setState(() => _currentPage += 1);
  }

  void _goToPreviousPage() {
    setState(() => _currentPage -= 1);
  }

  void _skipToLastPage() {
    setState(() => _currentPage = _pages.length - 1);
  }

  Future<void> _completeOnboarding() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.headline,
    required this.body,
    required this.detail,
    this.showMark = false,
  });

  final String headline;
  final String body;
  final String detail;
  final bool showMark;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    super.key,
    required this.data,
    required this.isFirstPage,
    required this.isLastPage,
  });

  final _OnboardingPageData data;
  final bool isFirstPage;
  final bool isLastPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final size = MediaQuery.of(context).size;
    final headlineStyle = isFirstPage
        ? theme.textTheme.displayLarge?.copyWith(
            fontSize: size.width < 380 ? 92 : 118,
          )
        : theme.textTheme.displayMedium;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (size.height * 0.62).clamp(420.0, 680.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            if (data.showMark) ...[
              const CuratorMarkArtwork(size: 88, opacity: 0.96),
              const SizedBox(height: 28),
            ] else ...[
              const SizedBox(height: 64),
            ],
            Text(data.headline, style: headlineStyle),
            const SizedBox(height: 24),
            Text(
              data.body,
              style: theme.textTheme.bodyLarge?.copyWith(color: palette.label),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                data.detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.label.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (isLastPage) ...[
              const SizedBox(height: 28),
              Text(
                '첫 질문은 홈 화면에서 바로 남길 수 있습니다.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 16 : 5,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isActive
            ? palette.accentStrong
            : palette.outline.withValues(alpha: 0.42),
      ),
    );
  }
}

class _PressScaleTextButton extends StatefulWidget {
  const _PressScaleTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool large;

  @override
  State<_PressScaleTextButton> createState() => _PressScaleTextButtonState();
}

class _PressScaleTextButtonState extends State<_PressScaleTextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            setState(() => _pressed = value);
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              widget.label,
              style:
                  (widget.large
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: palette.accentStrong,
                        decoration: TextDecoration.underline,
                        decorationColor: palette.accentStrong.withValues(
                          alpha: 0.5,
                        ),
                        decorationThickness: 0.7,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
