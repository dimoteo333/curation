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
  late final PageController _pageController;
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
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CuratorBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: palette.surfaceStrong.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: palette.outline.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Image.asset('assets/branding/curator_mark.png'),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '큐레이터 시작하기',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        if (!isLastPage)
                          TextButton(
                            key: const Key('onboardingSkipButton'),
                            onPressed: _skipToLastPage,
                            child: const Text('건너뛰기'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          final item = _pages[index];
                          return _OnboardingPage(
                            data: item,
                            isFirstPage: index == 0,
                            isLastPage: index == _pages.length - 1,
                            pageIndex: index,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        for (var i = 0; i < _pages.length; i++) ...[
                          _PageDot(isActive: i == _currentPage),
                          if (i != _pages.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _goToPreviousPage,
                              child: const Text('이전'),
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: isLastPage
                                ? const Key('completeOnboardingButton')
                                : const Key('onboardingNextButton'),
                            onPressed: isLastPage
                                ? _completeOnboarding
                                : _goToNextPage,
                            child: Text(isLastPage ? '시작하기' : '다음'),
                          ),
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

  Future<void> _goToNextPage() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToPreviousPage() async {
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLastPage() async {
    await _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isFirstPage,
    required this.isLastPage,
    required this.pageIndex,
  });

  final _OnboardingPageData data;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 620;
        final headlineStyle = (isFirstPage
                ? theme.textTheme.displayLarge
                : theme.textTheme.displayMedium)
            ?.copyWith(
              fontSize: isFirstPage
                  ? (isCompact ? 76 : 88)
                  : (isCompact ? 36 : 42),
            );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceStrong.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: palette.outline.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: palette.shadowColor.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 44).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.showMark) ...[
                      const Center(
                        child: CuratorMarkArtwork(size: 88, opacity: 0.96),
                      ),
                      SizedBox(height: isCompact ? 20 : 26),
                    ] else ...[
                      const SizedBox(height: 10),
                    ],
                    _PageLabel(page: pageIndex + 1, total: 3),
                    const SizedBox(height: 14),
                    Text(data.headline, style: headlineStyle),
                    SizedBox(height: isCompact ? 18 : 22),
                    Text(
                      data.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: palette.label,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Text(
                        data.detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.label.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 24 : 40),
                    if (isLastPage) ...[
                      Text(
                        '첫 질문은 홈 화면에서 바로 남길 수 있습니다.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageLabel extends StatelessWidget {
  const _PageLabel({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.highlight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$page / $total',
        style: theme.textTheme.labelLarge?.copyWith(
          color: palette.accentStrong,
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
