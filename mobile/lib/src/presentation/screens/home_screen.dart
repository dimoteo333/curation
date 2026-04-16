import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ondevice/litert_method_channel_bridge.dart';
import '../../providers.dart';
import '../../domain/entities/curated_response.dart';
import '../../state/curation_controller.dart';
import '../../theme/curator_theme.dart';

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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              palette.backdropTop,
              palette.backdropAccent,
              palette.backdropBottom,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              left: -20,
              child: _AmbientGlow(
                color: palette.ambientGlow.withValues(alpha: 0.26),
                diameter: 300,
              ),
            ),
            Positioned(
              top: 180,
              right: -80,
              child: _AmbientGlow(
                color: palette.accent.withValues(alpha: 0.16),
                diameter: 260,
              ),
            ),
            Positioned(
              bottom: -100,
              left: 40,
              child: _AmbientGlow(
                color: palette.accentSoft.withValues(alpha: 0.18),
                diameter: 240,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      _HeroHeader(palette: palette),
                      const SizedBox(height: 22),
                      _RuntimeStatusCard(
                        runtimeStatus: runtimeStatus,
                        onRefresh: () =>
                            ref.invalidate(onDeviceRuntimeStatusProvider),
                      ),
                      const SizedBox(height: 18),
                      _QuestionPanel(
                        controller: _controller,
                        isLoading: state.isLoading,
                        errorMessage: state.errorMessage,
                        runtimeStatus: runtimeStatus,
                        onSubmit: () =>
                            controller.submitQuestion(_controller.text),
                      ),
                      const SizedBox(height: 18),
                      if (state.response == null)
                        const _PreviewPanel()
                      else
                        _ResultSection(
                          response: state.response!,
                          lastQuestion: state.lastQuestion,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.palette});

  final CuratorPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.cardTheme.color ?? palette.surfaceStrong,
            palette.surface.withValues(alpha: 0.84),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: palette.outline.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceStrong,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: palette.ambientGlow.withValues(alpha: 0.28),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset('assets/branding/curator_mark.png'),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('큐레이터', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      '흩어진 한국어 기록을 감정의 결로 다시 읽는 개인 큐레이션.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: palette.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _SignalChip(icon: Icons.auto_awesome_rounded, label: '감정 흐름 추적'),
              _SignalChip(icon: Icons.import_contacts_rounded, label: '기록 재배열'),
              _SignalChip(icon: Icons.nightlight_round, label: '사적인 아카이브'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.surfaceStrong.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: palette.outline.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '완성된 문장보다 망설이는 질문에 더 잘 반응하도록 설계했습니다. 짧은 감정, 메모 한 줄, 애매한 불안도 그대로 적어 보세요.',
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
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
    final runtimeLabel = _runtimeLabel();
    final runtimeHint = _runtimeHint();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? palette.surfaceStrong,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.outline.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘의 질문', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '지금 붙잡히는 감정과 문장을 적으면 기록 속 맥락을 다시 엮어 드립니다.',
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('questionTextField'),
            controller: controller,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '요즘 떠오르는 고민이나 감정을 적어 주세요.',
            ),
          ),
          const SizedBox(height: 14),
          Text(runtimeHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          Text(
            '예시: 일이 밀릴수록 더 멍해지고, 쉬는 시간도 죄책감이 들어요.',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('submitQuestionButton'),
            onPressed: isLoading ? null : onSubmit,
            icon: Icon(
              isLoading
                  ? Icons.hourglass_top_rounded
                  : runtimeLabel.contains('네이티브')
                  ? Icons.memory_rounded
                  : Icons.travel_explore_rounded,
            ),
            label: Text(isLoading ? '기록을 찾는 중...' : runtimeLabel),
          ),
        ],
      ),
    );
  }

  String _runtimeLabel() {
    final status = runtimeStatus.asData?.value;
    if (status == null) {
      return '런타임 확인 후 기록 연결하기';
    }
    if (status.runtime == 'remote-harness') {
      return '원격 하네스로 기록 연결하기';
    }
    if (status.usingNativeLlm) {
      return '네이티브로 기록 연결하기';
    }
    return '템플릿으로 기록 연결하기';
  }

  String _runtimeHint() {
    final status = runtimeStatus.asData?.value;
    if (status == null) {
      return '런타임 준비 상태를 확인하는 중입니다. 확인 전에도 기본 폴백 경로로 질문을 보낼 수 있습니다.';
    }
    if (status.runtime == 'remote-harness') {
      return '현재는 FastAPI 개발 하네스를 사용합니다.';
    }
    if (status.usingNativeLlm && status.usingNativeEmbedder) {
      return '현재 네이티브 LLM과 임베더가 모두 준비되어 있습니다.';
    }
    if (status.usingNativeLlm) {
      return '현재 LLM은 네이티브지만 검색 일부는 폴백일 수 있습니다.';
    }
    return '현재는 템플릿 폴백으로 응답하며, 검색과 기록 조합은 기기 안에서 계속 처리합니다.';
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
    final title = _titleFor(status);
    final message = status?.message ?? '네이티브 런타임 준비 상태를 확인하고 있습니다.';
    final accentColor = _accentFor(theme, status);

    return Container(
      key: const Key('runtimeStatusCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.outline.withValues(alpha: 0.5)),
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
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconFor(status), color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.label,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('runtimeRefreshButton'),
                onPressed: onRefresh,
                tooltip: '런타임 상태 다시 확인',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RuntimePill(
                label: status == null ? '확인 중' : _runtimeKind(status),
                color: accentColor,
              ),
              if (status != null)
                _RuntimePill(
                  label: '플랫폼 ${status.platform}',
                  color: palette.accentStrong,
                ),
              if (status?.lastPrepareDurationMs != null)
                _RuntimePill(
                  label: '초기화 ${status!.lastPrepareDurationMs}ms',
                  color: palette.label,
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
              title: Text('개발자 정보', style: theme.textTheme.titleMedium),
              subtitle: Text(
                status?.lastError == null
                    ? '모델 준비 상태와 마지막 오류를 확인합니다.'
                    : '마지막 오류: ${status!.lastError}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.label,
                ),
              ),
              children: [
                _RuntimeFact(
                  label: 'LLM 모델',
                  value: _modelState(
                    configured: status?.llmModelConfigured ?? false,
                    available: status?.llmModelAvailable ?? false,
                    ready: status?.llmReady ?? false,
                  ),
                ),
                _RuntimeFact(
                  label: '임베더 모델',
                  value: _modelState(
                    configured: status?.embedderModelConfigured ?? false,
                    available: status?.embedderModelAvailable ?? false,
                    ready: status?.embedderReady ?? false,
                  ),
                ),
                _RuntimeFact(
                  label: '런타임 코드',
                  value: status?.runtime ?? 'loading',
                ),
                _RuntimeFact(
                  label: '폴백 활성화',
                  value: status == null
                      ? '확인 중'
                      : status.fallbackActive
                      ? '예'
                      : '아니오',
                ),
                _RuntimeFact(label: '마지막 오류', value: status?.lastError ?? '없음'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _titleFor(OnDeviceRuntimeStatus? status) {
    if (status == null) {
      return '런타임 상태 확인 중';
    }
    if (status.runtime == 'remote-harness') {
      return '원격 API 하네스 사용 중';
    }
    if (status.usingNativeLlm && status.usingNativeEmbedder) {
      return '네이티브 LLM 사용 가능';
    }
    if (status.usingNativeLlm) {
      return '네이티브 LLM 부분 준비';
    }
    return '템플릿 폴백 사용 중';
  }

  static String _runtimeKind(OnDeviceRuntimeStatus status) {
    if (status.runtime == 'remote-harness') {
      return '원격 하네스';
    }
    if (status.usingNativeLlm && status.usingNativeEmbedder) {
      return '온디바이스 네이티브';
    }
    if (status.usingNativeLlm) {
      return '온디바이스 부분 준비';
    }
    return '온디바이스 폴백';
  }

  static IconData _iconFor(OnDeviceRuntimeStatus? status) {
    if (status == null) {
      return Icons.hourglass_top_rounded;
    }
    if (status.runtime == 'remote-harness') {
      return Icons.cloud_sync_rounded;
    }
    if (status.usingNativeLlm && status.usingNativeEmbedder) {
      return Icons.memory_rounded;
    }
    if (status.lastError != null) {
      return Icons.warning_amber_rounded;
    }
    return Icons.layers_clear_rounded;
  }

  static Color _accentFor(ThemeData theme, OnDeviceRuntimeStatus? status) {
    if (status == null) {
      return theme.colorScheme.primary;
    }
    if (status.runtime == 'remote-harness') {
      return theme.colorScheme.secondary;
    }
    if (status.usingNativeLlm && status.usingNativeEmbedder) {
      return Colors.teal.shade700;
    }
    if (status.lastError != null) {
      return theme.colorScheme.error;
    }
    return Colors.orange.shade700;
  }

  static String _modelState({
    required bool configured,
    required bool available,
    required bool ready,
  }) {
    if (ready) {
      return '준비 완료';
    }
    if (configured && !available) {
      return '경로 설정됨, 파일 없음';
    }
    if (configured) {
      return '경로 설정됨, 초기화 대기';
    }
    return '미설정';
  }
}

class _RuntimePill extends StatelessWidget {
  const _RuntimePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(color: color),
      ),
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
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이런 방식으로 엮습니다', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          const _PreviewStep(
            index: '01',
            title: '표현의 반복을 읽습니다',
            description: '기분, 행동, 회피 패턴처럼 자주 되돌아오는 문장을 먼저 찾아냅니다.',
          ),
          const _PreviewStep(
            index: '02',
            title: '기록 사이의 간격을 연결합니다',
            description: '한 번의 메모가 아니라 시간에 따라 어떻게 감정이 이동했는지 보여줍니다.',
          ),
          const _PreviewStep(
            index: '03',
            title: '지금 필요한 질문을 남깁니다',
            description: '답을 단정하기보다 다음 기록을 위한 후속 질문을 건네는 방식입니다.',
          ),
        ],
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.index,
    required this.title,
    required this.description,
  });

  final String index;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(index, style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
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

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.response, required this.lastQuestion});

  final CuratedResponse response;
  final String lastQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Column(
      key: const Key('responseSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
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
            border: Border.all(color: palette.outline.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset('assets/branding/curator_mark.png'),
                  ),
                  const SizedBox(width: 12),
                  Text('오늘의 큐레이션', style: theme.textTheme.titleLarge),
                ],
              ),
              if (response.runtimeInfo != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: response.runtimeInfo!.isFallback
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 응답: ${response.runtimeInfo!.label}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        response.runtimeInfo!.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(
                '질문',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.label,
                ),
              ),
              const SizedBox(height: 6),
              Text(lastQuestion, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surfaceStrong.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: palette.outline.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.insightTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(response.summary, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Text(
                      response.answer,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.accentSoft.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  response.suggestedFollowUp,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.accentStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('연결된 기록', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final record in response.supportingRecords) ...[
          _SupportingRecordCard(record: record),
          const SizedBox(height: 12),
        ],
      ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? palette.surfaceStrong,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(record.source, style: theme.textTheme.labelLarge),
              ),
              const Spacer(),
              Text(
                _formatDate(record.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(record.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(record.excerpt, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceMuted.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              record.relevanceReason,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.label),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
