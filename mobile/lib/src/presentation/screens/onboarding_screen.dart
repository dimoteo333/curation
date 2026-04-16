import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../theme/curator_theme.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              palette.backdropTop,
              palette.backdropAccent,
              palette.backdropBottom,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: palette.surfaceStrong.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: palette.outline.withValues(alpha: 0.55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 36,
                          offset: const Offset(0, 22),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Image.asset(
                            'assets/branding/curator_mark.png',
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '큐레이터에 오신 것을 환영합니다',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '큐레이터는 메모, 일기, 일정 같은 사적인 한국어 기록을 기기 안에서 다시 엮어 읽는 개인 큐레이션 도구입니다.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: palette.label,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _OnboardingFact(
                          icon: Icons.file_open_rounded,
                          title: '데이터 입력',
                          body:
                              '설정 화면에서 `.txt`, `.md` 파일을 가져오면 기록이 로컬 벡터 DB에 저장되고 바로 검색에 반영됩니다.',
                        ),
                        const SizedBox(height: 14),
                        const _OnboardingFact(
                          icon: Icons.privacy_tip_rounded,
                          title: '프라이버시',
                          body:
                              '온디바이스 모드에서는 기록과 검색 인덱스가 기기 안에만 저장됩니다. 원격 모드는 개발자 테스트용입니다.',
                        ),
                        const SizedBox(height: 14),
                        const _OnboardingFact(
                          icon: Icons.settings_suggest_rounded,
                          title: '다음 단계',
                          body:
                              '시작 후 홈 화면 오른쪽 위 설정 버튼에서 런타임 모드, 모델 경로, 데이터 초기화와 파일 가져오기를 관리할 수 있습니다.',
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          key: const Key('completeOnboardingButton'),
                          onPressed: () async {
                            await ref
                                .read(appSettingsProvider.notifier)
                                .completeOnboarding();
                          },
                          child: const Text('시작하기'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFact extends StatelessWidget {
  const _OnboardingFact({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.accentSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: palette.accentStrong),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
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
