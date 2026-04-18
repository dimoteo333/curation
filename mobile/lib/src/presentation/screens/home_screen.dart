import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/life_record_store.dart';
import '../../providers.dart';
import '../../state/recent_conversations_controller.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';
import '../widgets/nav_dock.dart';
import '../widgets/source_icon.dart';
import 'ask_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<String> _suggestedPrompts = <String>[
    '나 요즘 왜 이렇게 무기력하지?',
    '작년 봄에 뭐 하면서 즐거웠지?',
    '지난달 내 루틴은 어땠을까?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final stats = ref.watch(localDataStatsProvider);
    final recentConversations = ref.watch(recentConversationsProvider);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: CuratorBackdrop(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 132),
                children: [
                  _HomeTopBar(
                    onOpenSettings: () => _openSettings(context),
                  ),
                  const SizedBox(height: 22),
                  _GreetingSection(now: DateTime.now()),
                  const SizedBox(height: 22),
                  _AskCard(
                    onTap: () => _openAsk(context),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(title: '추천 질문'),
                  const SizedBox(height: 10),
                  for (var index = 0; index < _suggestedPrompts.length; index += 1) ...[
                    _SuggestedPromptTile(
                      prompt: _suggestedPrompts[index],
                      hint: switch (index) {
                        0 => '감정 · 패턴',
                        1 => '시간 · 회상',
                        _ => '행동 · 요약',
                      },
                      onTap: () => _openAsk(
                        context,
                        initialQuery: _suggestedPrompts[index],
                      ),
                    ),
                    if (index != _suggestedPrompts.length - 1)
                      const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),
                  _RecentConversationSection(
                    conversations: recentConversations.isEmpty
                        ? _fallbackRecentConversations()
                        : recentConversations,
                    onTapConversation: (question) =>
                        _openAsk(context, initialQuery: question),
                  ),
                  const SizedBox(height: 24),
                  _ConnectedSourcesSection(stats: stats),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: NavDock(
                  activeDestination: CuratorNavDestination.home,
                  onSelected: (destination) {
                    switch (destination) {
                      case CuratorNavDestination.home:
                        break;
                      case CuratorNavDestination.ask:
                        _openAsk(context);
                        break;
                      case CuratorNavDestination.settings:
                        _openSettings(context);
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

  void _openAsk(BuildContext context, {String? initialQuery}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AskScreen(initialQuery: initialQuery),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
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

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Row(
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
          onTap: onOpenSettings,
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
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            height: 1.4,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return InkWell(
      key: const Key('todayAskCard'),
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: palette.paper.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.line2),
          boxShadow: palette.shadowSoft,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -42,
              right: -34,
              child: Container(
                width: 116,
                height: 116,
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
            Column(
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
                        color: palette.terraDeep,
                        fontFamily: 'IBMPlexSansKR',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '내 기록에 물어보세요.\n'),
                      TextSpan(
                        text: '오늘의 감정, 과거의 나, 반복되는 패턴까지.',
                        style: TextStyle(color: palette.ink2),
                      ),
                    ],
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    height: 1.56,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
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
                          borderRadius: BorderRadius.circular(999),
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
          ],
        ),
      ),
    );
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
        color: palette.ink3,
        fontFamily: 'IBMPlexSansKR',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SuggestedPromptTile extends StatelessWidget {
  const _SuggestedPromptTile({
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
                Icons.done_rounded,
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
                      fontWeight: FontWeight.w500,
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

class _RecentConversationSection extends StatelessWidget {
  const _RecentConversationSection({
    required this.conversations,
    required this.onTapConversation,
  });

  final List<RecentConversation> conversations;
  final ValueChanged<String> onTapConversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: '최근 대화')),
            Text(
              '전체 보기',
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                color: palette.terraDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.line),
            boxShadow: palette.shadowSoft,
          ),
          child: Column(
            children: [
              for (var index = 0; index < conversations.length; index += 1)
                InkWell(
                  onTap: () => onTapConversation(conversations[index].question),
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(18) : Radius.zero,
                    bottom: index == conversations.length - 1
                        ? const Radius.circular(18)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                conversations[index].question,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'IBMPlexSansKR',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatRelativeTime(conversations[index].askedAt),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontFamily: 'IBMPlexSansKR',
                                color: palette.ink3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            conversations[index].preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFamily: 'IBMPlexSansKR',
                              fontSize: 12,
                              color: palette.ink2,
                            ),
                          ),
                        ),
                        if (index != conversations.length - 1) ...[
                          const SizedBox(height: 13),
                          Divider(height: 1, color: palette.line),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectedSourcesSection extends StatelessWidget {
  const _ConnectedSourcesSection({required this.stats});

  final AsyncValue<LocalDataStats> stats;

  @override
  Widget build(BuildContext context) {
    final counts = stats.maybeWhen(
      data: (value) => _SourceCounts.fromStats(value.sourceCounts),
      orElse: _SourceCounts.empty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '연결된 기록'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _SourceCountCard(
              source: 'diary',
              label: '일기',
              count: counts.diary,
            ),
            _SourceCountCard(
              source: 'calendar',
              label: '캘린더',
              count: counts.calendar,
            ),
            _SourceCountCard(
              source: 'memo',
              label: '메모',
              count: counts.memo,
            ),
            _SourceCountCard(
              source: 'voice_memo',
              label: '음성 메모',
              count: counts.voiceMemo,
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceCountCard extends StatelessWidget {
  const _SourceCountCard({
    required this.source,
    required this.label,
    required this.count,
  });

  final String source;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: palette.paper2,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: SourceIcon(
              source: source,
              size: 15,
              color: palette.terraDeep,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'IBMPlexSansKR',
                    color: palette.ink3,
                  ),
                ),
                const SizedBox(height: 1),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                    children: [
                      TextSpan(text: '$count'),
                      TextSpan(
                        text: '개',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          fontSize: 10,
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
    );
  }
}

class _SourceCounts {
  const _SourceCounts({
    required this.diary,
    required this.calendar,
    required this.memo,
    required this.voiceMemo,
  });

  const _SourceCounts.empty()
      : diary = 0,
        calendar = 0,
        memo = 0,
        voiceMemo = 0;

  factory _SourceCounts.fromStats(Map<String, int> sourceCounts) {
    return _SourceCounts(
      diary: sourceCounts['diary'] ?? 0,
      calendar: sourceCounts['calendar'] ?? 0,
      memo:
          (sourceCounts['memo'] ?? 0) +
          (sourceCounts['note'] ?? 0) +
          (sourceCounts['file'] ?? 0),
      voiceMemo: sourceCounts['voice_memo'] ?? 0,
    );
  }

  final int diary;
  final int calendar;
  final int memo;
  final int voiceMemo;
}

String _formatKoreanDate(DateTime now) {
  const weekdays = <String>['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${now.year}년 ${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}';
}

String _formatRelativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inDays >= 14) {
    return '${difference.inDays ~/ 7}주 전';
  }
  if (difference.inDays >= 1) {
    return '${difference.inDays}일 전';
  }
  if (difference.inHours >= 1) {
    return '${difference.inHours}시간 전';
  }
  final minutes = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
  return '$minutes분 전';
}
