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
      icon: Icons.auto_awesome_rounded,
      title: '당신의 일상,\nAI가 큐레이션합니다',
      body: '메모, 일기, 일정에 남긴 한국어 기록을 다시 엮어 지금의 질문과 연결해 드립니다.',
      highlights: ['흩어진 기록을 하나의 흐름으로 정리', '짧은 메모 한 줄로도 바로 시작 가능'],
    ),
    _OnboardingPageData(
      icon: Icons.lock_rounded,
      title: '모든 건 기기 안에서',
      body: '온디바이스 모드에서는 질문과 기록, 검색 인덱스가 기본적으로 기기 안에만 머무릅니다.',
      highlights: ['외부 전송 없이 개인 기록 기반 인사이트 제공', '원격 모드는 개발 점검용으로만 분리'],
    ),
    _OnboardingPageData(
      icon: Icons.file_open_rounded,
      title: '시작하기 전에\n기록을 불러오세요',
      body: '설정에서 `.txt` 또는 `.md` 파일을 가져오면, 홈 화면에서 바로 첫 큐레이션을 시작할 수 있습니다.',
      highlights: ['설정 화면에서 파일 가져오기 지원', '의학·심리 진단이 아닌 기록 해석 도구'],
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
      body: CuratorBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: palette.surfaceStrong.withValues(
                              alpha: 0.82,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: palette.outline.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Image.asset(
                            'assets/branding/curator_mark.png',
                          ),
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
                            child: const Text('스킵'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          final isActive = index == _currentPage;
                          return _OnboardingPage(
                            data: page,
                            isActive: isActive,
                            pageIndex: index,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
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
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToPreviousPage() async {
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLastPage() async {
    await _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
    required this.highlights,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> highlights;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.pageIndex,
  });

  final _OnboardingPageData data;
  final bool isActive;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return AnimatedScale(
      duration: const Duration(milliseconds: 260),
      scale: isActive ? 1 : 0.97,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: isActive ? 1 : 0.76,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: palette.surfaceStrong.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: palette.outline.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 34,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CuratorOrbitArtwork(
                    size: 220,
                    icon: data.icon,
                    showBrandMark: pageIndex == 0,
                  ),
                ),
                const SizedBox(height: 24),
                _PageLabel(page: pageIndex + 1, total: 3),
                const SizedBox(height: 10),
                Text(data.title, style: theme.textTheme.displaySmall),
                const SizedBox(height: 12),
                Text(
                  data.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.label,
                  ),
                ),
                const SizedBox(height: 20),
                for (final highlight in data.highlights) ...[
                  _HighlightCard(
                    icon: data.icon,
                    body: highlight,
                    isPrimary: highlight == data.highlights.first,
                  ),
                  if (highlight != data.highlights.last)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
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
        color: palette.highlight.withValues(alpha: 0.14),
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

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.body,
    required this.isPrimary,
  });

  final IconData icon;
  final String body;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: <Color>[
                  palette.surface.withValues(alpha: 0.92),
                  palette.accentSoft.withValues(alpha: 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : palette.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.highlight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.accentStrong),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(body, style: theme.textTheme.bodyMedium)),
        ],
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
      duration: const Duration(milliseconds: 220),
      width: isActive ? 26 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? palette.accent
            : palette.outline.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
