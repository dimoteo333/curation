import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../data/ondevice/litert_method_channel_bridge.dart';
import '../../providers.dart';
import '../../theme/curator_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _llmPathController;
  late final TextEditingController _embedderPathController;
  bool _pathsInitialized = false;

  @override
  void initState() {
    super.initState();
    _llmPathController = TextEditingController();
    _embedderPathController = TextEditingController();
  }

  @override
  void dispose() {
    _llmPathController.dispose();
    _embedderPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final settings = ref.watch(appSettingsProvider);
    final runtimeStatus = ref.watch(onDeviceRuntimeStatusProvider);
    final dataStats = ref.watch(localDataStatsProvider);
    final buildInfo = ref.watch(appBuildInfoProvider);
    final config = ref.watch(appConfigProvider);

    if (!_pathsInitialized) {
      _llmPathController.text = settings.llmModelPath ?? '';
      _embedderPathController.text = settings.embedderModelPath ?? '';
      _pathsInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
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
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _SectionCard(
                    title: '런타임 모드',
                    subtitle: '기본값은 온디바이스입니다. 원격 모드는 개발자 테스트용으로만 사용하세요.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<CurationRuntimeMode>(
                          segments: const [
                            ButtonSegment<CurationRuntimeMode>(
                              value: CurationRuntimeMode.onDevice,
                              icon: Icon(Icons.phone_android_rounded),
                              label: Text('온디바이스'),
                            ),
                            ButtonSegment<CurationRuntimeMode>(
                              value: CurationRuntimeMode.remote,
                              icon: Icon(Icons.cloud_queue_rounded),
                              label: Text('원격'),
                            ),
                          ],
                          selected: <CurationRuntimeMode>{settings.runtimeMode},
                          onSelectionChanged:
                              (Set<CurationRuntimeMode> selection) async {
                                final nextMode = selection.first;
                                await ref
                                    .read(appSettingsProvider.notifier)
                                    .setRuntimeMode(nextMode);
                                ref.invalidate(onDeviceRuntimeStatusProvider);
                              },
                        ),
                        const SizedBox(height: 18),
                        _RuntimeSummary(runtimeStatus: runtimeStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: '데이터 관리',
                    subtitle: '로컬 기록과 벡터 인덱스 상태를 확인하고 가져오기/초기화 작업을 수행합니다.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dataStats.when(
                          data: (stats) => Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _DataPill(label: '저장된 기록 ${stats.recordCount}건'),
                              _DataPill(
                                label:
                                    '벡터 DB ${_formatBytes(stats.databaseSizeBytes)}',
                              ),
                            ],
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) => Text(
                            '데이터 상태를 읽지 못했습니다: $error',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              key: const Key('settingsImportButton'),
                              onPressed: _importFiles,
                              icon: const Icon(Icons.file_open_rounded),
                              label: const Text('파일 가져오기'),
                            ),
                            OutlinedButton.icon(
                              key: const Key('settingsResetSeedButton'),
                              onPressed: _resetToSeedRecords,
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text('기본 시드 복원'),
                            ),
                            OutlinedButton.icon(
                              key: const Key('settingsClearDataButton'),
                              onPressed: _clearAllData,
                              icon: const Icon(Icons.delete_sweep_rounded),
                              label: const Text('전체 데이터 삭제'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: '개발자 모델 경로',
                    subtitle:
                        '네이티브 LiteRT 모델 위치를 로컬 설정으로 덮어씁니다. 비워 두면 환경변수 기본값을 사용합니다.',
                    child: Column(
                      children: [
                        TextField(
                          key: const Key('llmModelPathField'),
                          controller: _llmPathController,
                          decoration: const InputDecoration(
                            labelText: 'LLM 모델 경로',
                            hintText: '/path/to/gemma.task',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('embedderModelPathField'),
                          controller: _embedderPathController,
                          decoration: const InputDecoration(
                            labelText: '임베딩 모델 경로',
                            hintText: '/path/to/embedder.tflite',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            key: const Key('saveModelPathsButton'),
                            onPressed: _saveModelPaths,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('모델 경로 저장'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: '프라이버시',
                    subtitle: '현재 저장과 전송 정책을 한국어로 명확히 안내합니다.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PrivacyLine(
                          title: '데이터 저장 위치',
                          body:
                              '기록과 벡터 인덱스는 앱 로컬 SQLite 파일 `${config.vectorDbName}`에 저장됩니다.',
                        ),
                        const SizedBox(height: 10),
                        const _PrivacyLine(
                          title: '외부 전송 정책',
                          body:
                              '온디바이스 모드에서는 기록과 임베딩을 외부로 보내지 않습니다. 원격 모드는 개발자 하네스 검증용입니다.',
                        ),
                        const SizedBox(height: 10),
                        const _PrivacyLine(
                          title: '데이터 삭제',
                          body: '전체 데이터 삭제를 누르면 로컬 기록과 벡터 인덱스가 앱 안에서 제거됩니다.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: '앱 정보',
                    subtitle: '버전, 패키지 정보, 라이선스를 확인합니다.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: '앱 이름', value: buildInfo.appName),
                        _InfoRow(label: '버전', value: buildInfo.versionLabel),
                        _InfoRow(label: '패키지', value: buildInfo.packageName),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          key: const Key('showLicenseButton'),
                          onPressed: () {
                            showLicensePage(
                              context: context,
                              applicationName: buildInfo.appName,
                              applicationVersion: buildInfo.versionLabel,
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('오픈소스 라이선스 보기'),
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

  Future<void> _importFiles() async {
    final service = ref.read(fileRecordImportServiceProvider);
    final result = await service.pickAndImport();
    ref.read(localDataRevisionProvider.notifier).bump();

    if (!mounted) {
      return;
    }

    if (!result.hasImportedRecords && result.skippedFiles.isEmpty) {
      _showMessage('선택한 파일이 없습니다.');
      return;
    }

    final skippedSummary = result.skippedFiles.isEmpty
        ? ''
        : ' 건너뜀 ${result.skippedFiles.length}건';
    _showMessage('파일 ${result.importedCount}건을 가져왔습니다.$skippedSummary');
  }

  Future<void> _resetToSeedRecords() async {
    await ref.read(lifeRecordStoreProvider).resetToSeedRecords();
    ref.read(localDataRevisionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    _showMessage('기본 시드 데이터로 초기화했습니다.');
  }

  Future<void> _clearAllData() async {
    await ref.read(lifeRecordStoreProvider).clearAllRecords();
    ref.read(localDataRevisionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    _showMessage('로컬 데이터를 모두 삭제했습니다.');
  }

  Future<void> _saveModelPaths() async {
    await ref
        .read(appSettingsProvider.notifier)
        .saveModelPaths(
          llmModelPath: _llmPathController.text,
          embedderModelPath: _embedderPathController.text,
        );
    ref.invalidate(onDeviceRuntimeStatusProvider);
    if (!mounted) {
      return;
    }
    _showMessage('모델 경로를 저장했습니다.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }
    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(2)} MB';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _RuntimeSummary extends StatelessWidget {
  const _RuntimeSummary({required this.runtimeStatus});

  final AsyncValue<OnDeviceRuntimeStatus> runtimeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return runtimeStatus.when(
      data: (OnDeviceRuntimeStatus status) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.outline.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DataPill(
                    label: status.runtime == 'remote-harness'
                        ? '원격 하네스'
                        : status.usingNativeLlm
                        ? 'LLM 네이티브 준비'
                        : 'LLM 폴백',
                  ),
                  _DataPill(
                    label: status.usingNativeEmbedder
                        ? '임베딩 네이티브 준비'
                        : '임베딩 폴백',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (Object error, StackTrace _) => Text(
        '런타임 상태를 읽지 못했습니다: $error',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
        ),
      ],
    );
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.outline.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: theme.textTheme.labelLarge),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.label),
            ),
          ),
        ],
      ),
    );
  }
}
