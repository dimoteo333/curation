import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/life_record_store.dart';
import '../../providers.dart';
import '../../state/app_shell_controller.dart';
import '../../state/recent_conversations_controller.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/source_icon.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<({String prompt, String hint})> _suggestedPrompts =
      <({String prompt, String hint})>[
        (prompt: '나 요즘 왜 이렇게 무기력하지?', hint: '감정 · 패턴'),
        (prompt: '작년 봄에 뭐 하면서 즐거웠지?', hint: '시간 · 회상'),
        (prompt: '지난달 내 루틴은 어땠을까?', hint: '행동 · 요약'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final shell = ref.read(curatorAppShellProvider.notifier);
    final stats = ref.watch(localDataStatsProvider);
    final conversations = ref.watch(recentConversationsProvider);
    final recentConversations = conversations.isEmpty
        ? _fallbackRecentConversations()
        : conversations;
    final now = DateTime.now();

    return CuratorBackdrop(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 112),
          children: [
            Row(
              children: [
                const CuratorMark(size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '큐레이터',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  key: const Key('openSettingsButton'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => shell.selectTab(CuratorTab.settings),
                  child: Ink(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.paper2.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.line),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: palette.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _formatKoreanDate(now),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                color: palette.ink3,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '안녕하세요, 지원 님.\n'),
                  TextSpan(
                    text: '오늘은 어떤 마음을\n들여다보고 싶으세요?',
                    style: TextStyle(color: palette.ink3),
                  ),
                ],
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            InkWell(
              key: const Key('todayAskCard'),
              borderRadius: BorderRadius.circular(22),
              onTap: () => shell.composeQuestion(resetInput: true),
              child: Ink(
                decoration: BoxDecoration(
                  color: palette.paper,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.line2),
                  boxShadow: palette.shadowSoft,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -42,
                      right: -40,
                      child: Container(
                        width: 122,
                        height: 122,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              palette.terra.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: palette.terra,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '오늘의 질문',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  color: palette.terraDeep,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: '내 기록에 물어보세요.\n'),
                                TextSpan(
                                  text: '오늘의 감정, 과거의 나, 반복되는 패턴까지.',
                                  style: TextStyle(
                                    color: palette.ink2,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              height: 1.55,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.line),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                  color: palette.ink3,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '무엇이든 물어보세요…',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'IBMPlexSansKR',
                                      fontSize: 14,
                                      color: palette.ink3,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: palette.terra,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 14,
                                    color: Color(0xFFFDF6EC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: '추천 질문'),
            const SizedBox(height: 10),
            for (var index = 0; index < _suggestedPrompts.length; index += 1) ...[
              _SuggestionCard(
                prompt: _suggestedPrompts[index].prompt,
                hint: _suggestedPrompts[index].hint,
                onTap: () {
                  shell.composeQuestion(
                    prefill: _suggestedPrompts[index].prompt,
                  );
                },
              ),
              if (index != _suggestedPrompts.length - 1)
                const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const _SectionHeader(title: '최근 대화'),
                const Spacer(),
                Text(
                  '전체 보기',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    fontSize: 12,
                    color: palette.terraDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.line),
                boxShadow: palette.shadowSoft,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < recentConversations.length; index += 1)
                    InkWell(
                      onTap: () {
                        shell.composeQuestion(
                          prefill: recentConversations[index].question,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: index == 0
                              ? null
                              : Border(
                                  top: BorderSide(color: palette.line),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recentConversations[index].question,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'IBMPlexSansKR',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _relativeConversationTime(
                                    recentConversations[index].askedAt,
                                    now,
                                  ),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontFamily: 'IBMPlexSansKR',
                                    color: palette.ink3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recentConversations[index].preview,
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
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: '연결된 기록'),
            const SizedBox(height: 10),
            stats.when(
              data: (value) => _ConnectedSourcesGrid(stats: value),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  '기록 통계를 읽지 못했습니다: $error',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                  '모든 처리가 기기 안에서 이루어집니다',
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

  List<RecentConversation> _fallbackRecentConversations() {
    final now = DateTime.now();
    return <RecentConversation>[
      RecentConversation(
        question: '지난 겨울엔 뭘 하면서 기분이 풀렸지?',
        preview: '그때는 한강 산책과 작은 프로젝트가 도움이 됐어요.',
        askedAt: now.subtract(const Duration(days: 4)),
      ),
      RecentConversation(
        question: '이직하고 나서 한 달 동안 어땠지?',
        preview: '적응에 시간이 걸렸지만, 3주차에 변화가 있었어요.',
        askedAt: now.subtract(const Duration(days: 7)),
      ),
      RecentConversation(
        question: '책 읽기 루틴이 가장 잘 지켜진 때는?',
        preview: '2024년 9월, 출퇴근 지하철에서 매일 읽으셨네요.',
        askedAt: now.subtract(const Duration(days: 14)),
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.prompt,
    required this.hint,
    required this.onTap,
  });

  final String prompt;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: palette.paper2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: palette.terraDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt,
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
                    hint,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'IBMPlexSansKR',
                      color: palette.ink3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: palette.ink4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedSourcesGrid extends StatelessWidget {
  const _ConnectedSourcesGrid({required this.stats});

  final LocalDataStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final memoCount =
        (stats.sourceCounts['note'] ?? 0) + (stats.sourceCounts['file'] ?? 0);
    final cards = <({String source, String label, int count})>[
      (
        source: 'diary',
        label: '일기',
        count: stats.sourceCounts['diary'] ?? 0,
      ),
      (
        source: 'calendar',
        label: '캘린더',
        count: stats.sourceCounts['calendar'] ?? 0,
      ),
      (
        source: 'memo',
        label: '메모',
        count: memoCount,
      ),
      (
        source: 'voice_memo',
        label: '음성 메모',
        count: stats.sourceCounts['voice_memo'] ?? 0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.paper2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: SourceIcon(
                      source: card.source,
                      size: 15,
                      color: palette.terraDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          color: palette.ink3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${card.count}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '개',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontFamily: 'IBMPlexSansKR',
                                color: palette.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _relativeConversationTime(DateTime askedAt, DateTime now) {
  final difference = now.difference(askedAt);
  if (difference.inDays >= 14) {
    return '${difference.inDays ~/ 7}주 전';
  }
  if (difference.inDays >= 1) {
    return '${difference.inDays}일 전';
  }
  if (difference.inHours >= 1) {
    return '${difference.inHours}시간 전';
  }
  return '방금 전';
}

String _formatKoreanDate(DateTime date) {
  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}
