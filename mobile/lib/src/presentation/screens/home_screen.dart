import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ondevice/litert_method_channel_bridge.dart';
import '../../domain/entities/curated_response.dart';
import '../../providers.dart';
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
    final runtimeStatus = ref.watch(onDeviceRuntimeStatusProvider);
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Scaffold(
      body: CuratorBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 260),
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
                      const SizedBox(height: 18),
                      _HeroCard(runtimeStatus: runtimeStatus),
                      const SizedBox(height: 18),
                      _FeatureStrip(
                        cards: const [
                          _FeatureCardData(
                            icon: Icons.auto_awesome_rounded,
                            title: '온디바이스 AI 큐레이션',
                            body: '흩어진 메모와 일기의 결을 다시 묶어 개인적인 흐름으로 정리합니다.',
                          ),
                          _FeatureCardData(
                            icon: Icons.lock_rounded,
                            title: '프라이버시 우선',
                            body: '질문, 검색, 인사이트는 기본적으로 기기 안에서만 머무르도록 설계했습니다.',
                          ),
                          _FeatureCardData(
                            icon: Icons.timeline_rounded,
                            title: '기록 기반 맞춤 인사이트',
                            body: '한 번의 감정이 아니라 최근의 반복과 맥락을 함께 읽어 드립니다.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _RuntimeStatusCard(
                        runtimeStatus: runtimeStatus,
                        onRefresh: () =>
                            ref.invalidate(onDeviceRuntimeStatusProvider),
                      ),
                      const SizedBox(height: 18),
                      if (state.response != null)
                        _ResultSection(
                          response: state.response!,
                          lastQuestion: state.lastQuestion,
                        )
                      else
                        const _EmptyResultSection(),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: palette.surfaceStrong.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: palette.outline.withValues(alpha: 0.24),
                          ),
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
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: palette.accentStrong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '큐레이터는 일상 기록을 정리하고 질문을 돕는 도구이며, 의학적 또는 심리 진단을 제공하지 않습니다.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _FloatingQuestionComposer(
                            controller: _controller,
                            isLoading: state.isLoading,
                            errorMessage: state.errorMessage,
                            runtimeStatus: runtimeStatus,
                            onSubmit: () =>
                                controller.submitQuestion(_controller.text),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: palette.surfaceStrong.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.outline.withValues(alpha: 0.22)),
          ),
          child: Image.asset('assets/branding/curator_mark.png'),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('큐레이터', style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('당신의 일상을 큐레이션합니다', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        IconButton.filledTonal(
          key: const Key('openSettingsButton'),
          onPressed: onOpenSettings,
          tooltip: '설정 열기',
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.runtimeStatus});

  final AsyncValue<OnDeviceRuntimeStatus> runtimeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final statusTone = _runtimePresentation(runtimeStatus.asData?.value);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            palette.surfaceStrong.withValues(alpha: 0.92),
            palette.surface.withValues(alpha: 0.7),
            palette.accentSoft.withValues(alpha: 0.34),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: palette.outline.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor.withValues(alpha: 0.1),
            blurRadius: 36,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                label: statusTone.badge,
                icon: statusTone.icon,
                backgroundColor: statusTone.tint.withValues(alpha: 0.14),
                foregroundColor: statusTone.tint,
              ),
              _Pill(
                label: '기록과 질문은 기본적으로 기기 안에',
                icon: Icons.verified_user_rounded,
                backgroundColor: palette.highlight.withValues(alpha: 0.18),
                foregroundColor: palette.accentStrong,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '당신의 일상을\n큐레이션합니다',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '메모, 일기, 일정에 흩어진 감정의 조각을 한데 모아 지금의 질문에 맞는 맥락으로 다시 읽어 드립니다.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: palette.label,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surfaceStrong.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: palette.outline.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        '짧은 메모, 애매한 감정, 설명하기 어려운 무드도 그대로 적어 보세요. 완성된 문장보다 살아 있는 흔적에 더 민감하게 반응하도록 설계했습니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.label,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              const CuratorOrbitArtwork(size: 196),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.cards});

  final List<_FeatureCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: _FeatureCard(card: cards[i])),
                if (i != cards.length - 1) const SizedBox(width: 14),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              _FeatureCard(card: cards[i]),
              if (i != cards.length - 1) const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.card});

  final _FeatureCardData card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  palette.highlight.withValues(alpha: 0.86),
                  palette.accent.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(card.icon, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 16),
          Text(card.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            card.body,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
        ],
      ),
    );
  }
}

class _RuntimeStatusCard extends StatelessWidget {
  const _RuntimeStatusCard({
    required this.runtimeStatus,
    required this.onRefresh,
  });

  final AsyncValue<OnDeviceRuntimeStatus> runtimeStatus;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final status = runtimeStatus.asData?.value;
    final presentation = _runtimePresentation(status);

    return Container(
      key: const Key('runtimeStatusCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: presentation.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(presentation.icon, color: presentation.tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('현재 상태', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      presentation.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.label,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: '상태 새로고침',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(
                label: presentation.badge,
                icon: presentation.icon,
                backgroundColor: presentation.tint.withValues(alpha: 0.12),
                foregroundColor: presentation.tint,
              ),
              _Pill(
                label: status == null
                    ? '상태 확인 중'
                    : status.runtime == 'remote-harness'
                    ? '개발용 연결'
                    : '온디바이스 우선',
                icon: Icons.radar_rounded,
                backgroundColor: palette.highlight.withValues(alpha: 0.14),
                foregroundColor: palette.accentStrong,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const Key('runtimeDeveloperPanel'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: Text('세부 상태 보기', style: theme.textTheme.titleMedium),
              subtitle: Text(
                '너무 기술적인 내용은 접어 두고, 필요할 때만 확인할 수 있습니다.',
                style: theme.textTheme.bodySmall,
              ),
              children: [
                _RuntimeFact(
                  label: '생성 엔진',
                  value: status == null
                      ? '확인 중'
                      : status.usingNativeLlm
                      ? '네이티브'
                      : status.runtime == 'remote-harness'
                      ? '원격 개발 하네스'
                      : '로컬 폴백',
                ),
                _RuntimeFact(
                  label: '검색 엔진',
                  value: status == null
                      ? '확인 중'
                      : status.usingNativeEmbedder
                      ? '네이티브'
                      : '의미 임베딩 폴백',
                ),
                _RuntimeFact(label: '플랫폼', value: status?.platform ?? '확인 중'),
                _RuntimeFact(
                  label: '초기화 시간',
                  value: status?.lastPrepareDurationMs == null
                      ? '기록 없음'
                      : '${status!.lastPrepareDurationMs}ms',
                ),
                _RuntimeFact(
                  label: '상태 메시지',
                  value: status?.message ?? '런타임을 확인하고 있습니다.',
                ),
                if (status?.lastError != null)
                  _RuntimeFact(label: '마지막 오류', value: status!.lastError!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultSection extends StatelessWidget {
  const _EmptyResultSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('최근 큐레이션', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '아직 첫 질문이 없습니다. 아래 플로팅 바에 지금 떠오르는 고민을 적으면, 최근 기록의 흐름을 바로 묶어서 보여 드립니다.',
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _ExampleChip('퇴근 후에도 머리가 안 쉬어요'),
              _ExampleChip('요즘 사람 만나는 게 왜 버겁지'),
              _ExampleChip('이번 주 감정 기복이 커진 이유가 뭘까'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.response, required this.lastQuestion});

  final CuratedResponse response;
  final String lastQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      key: const Key('responseSection'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.outline.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최근 큐레이션', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      lastQuestion.isEmpty
                          ? '방금 남긴 질문을 바탕으로 정리했습니다.'
                          : '질문: $lastQuestion',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (response.runtimeInfo != null)
                _Pill(
                  label: response.runtimeInfo!.label,
                  icon: response.runtimeInfo!.isFallback
                      ? Icons.layers_clear_rounded
                      : Icons.auto_awesome_rounded,
                  backgroundColor: response.runtimeInfo!.isFallback
                      ? Colors.orange.withValues(alpha: 0.12)
                      : palette.highlight.withValues(alpha: 0.14),
                  foregroundColor: response.runtimeInfo!.isFallback
                      ? Colors.orange.shade800
                      : palette.accentStrong,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(response.insightTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            response.summary,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  palette.surface.withValues(alpha: 0.9),
                  palette.accentSoft.withValues(alpha: 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(response.answer, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 18),
          if (response.supportingRecords.isNotEmpty) ...[
            Text('이렇게 읽었습니다', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final record in response.supportingRecords.take(2)) ...[
              _SupportingRecordCard(record: record),
              if (record != response.supportingRecords.take(2).last)
                const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.highlight.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              '다음 질문: ${response.suggestedFollowUp}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportingRecordCard extends StatelessWidget {
  const _SupportingRecordCard({required this.record});

  final SupportingRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallTag(record.source),
              _SmallTag(_formatDate(record.createdAt)),
            ],
          ),
          const SizedBox(height: 10),
          Text(record.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            record.excerpt,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
          const SizedBox(height: 8),
          Text(
            record.relevanceReason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.accentStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingQuestionComposer extends StatelessWidget {
  const _FloatingQuestionComposer({
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
    required this.runtimeStatus,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
  final AsyncValue<OnDeviceRuntimeStatus> runtimeStatus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final presentation = _runtimePresentation(runtimeStatus.asData?.value);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.outline.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor.withValues(alpha: 0.16),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지금 떠오른 질문', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '길게 설명하지 않아도 괜찮습니다. 한 문장만 남겨도 시작할 수 있습니다.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Pill(
                label: presentation.badge,
                icon: presentation.icon,
                backgroundColor: presentation.tint.withValues(alpha: 0.12),
                foregroundColor: presentation.tint,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('questionTextField'),
            controller: controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '예: 일이 밀릴수록 쉬는 시간에도 죄책감이 들어요.',
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '의학·심리 진단이 아닌 개인 기록 해석 도구입니다.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                key: const Key('submitQuestionButton'),
                onPressed: isLoading ? null : onSubmit,
                icon: Icon(
                  isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.arrow_upward_rounded,
                ),
                label: Text(isLoading ? '읽는 중...' : '큐레이션 시작'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

class _RuntimeFact extends StatelessWidget {
  const _RuntimeFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}.$month.$day';
}

_RuntimePresentation _runtimePresentation(OnDeviceRuntimeStatus? status) {
  if (status == null) {
    return const _RuntimePresentation(
      badge: '준비 상태 확인 중',
      summary: '기기 안 큐레이션 준비 상태를 확인하고 있습니다.',
      icon: Icons.motion_photos_on_rounded,
      tint: Color(0xFFC1784E),
    );
  }
  if (status.runtime == 'remote-harness') {
    return const _RuntimePresentation(
      badge: '개발용 원격 연결',
      summary: '현재는 개발 하네스로 응답을 확인하고 있습니다.',
      icon: Icons.cloud_queue_rounded,
      tint: Color(0xFFB26147),
    );
  }
  if (status.usingNativeLlm && status.usingNativeEmbedder) {
    return const _RuntimePresentation(
      badge: '기기 안에서 분석 중',
      summary: '질문과 검색 흐름이 모두 기기 안에서 정리됩니다.',
      icon: Icons.phone_android_rounded,
      tint: Color(0xFFB45F43),
    );
  }
  if (status.usingNativeLlm) {
    return const _RuntimePresentation(
      badge: '대부분 기기 안에서 처리',
      summary: '생성은 네이티브, 검색은 로컬 보조 경로로 이어집니다.',
      icon: Icons.memory_rounded,
      tint: Color(0xFFC1724A),
    );
  }
  return const _RuntimePresentation(
    badge: '가벼운 큐레이션 모드',
    summary: '네이티브 모델 없이도 기록의 흐름을 계속 읽어 드립니다.',
    icon: Icons.auto_fix_high_rounded,
    tint: Color(0xFFCE8B49),
  );
}

class _RuntimePresentation {
  const _RuntimePresentation({
    required this.badge,
    required this.summary,
    required this.icon,
    required this.tint,
  });

  final String badge;
  final String summary;
  final IconData icon;
  final Color tint;
}
