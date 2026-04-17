import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../data/ondevice/litert_method_channel_bridge.dart';
import '../../providers.dart';
import '../../theme/curator_theme.dart';
import '../widgets/curator_scene.dart';

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
      body: CuratorBackdrop(
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _SettingsHero(runtimeStatus: runtimeStatus),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: '사용 방식',
                    subtitle: '앱이 기록을 어떻게 읽을지 선택합니다.',
                  ),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      _ModeRow(
                        title: '온디바이스',
                        subtitle: '기록과 질문을 기기 안에서 우선 처리합니다.',
                        icon: Icons.phone_android_rounded,
                        selected:
                            settings.runtimeMode ==
                            CurationRuntimeMode.onDevice,
                        onTap: () =>
                            _setRuntimeMode(CurationRuntimeMode.onDevice),
                      ),
                      _GroupDivider(),
                      _ModeRow(
                        title: '원격',
                        subtitle: '개발자 테스트용 FastAPI 하네스로 연결합니다.',
                        icon: Icons.cloud_queue_rounded,
                        selected:
                            settings.runtimeMode == CurationRuntimeMode.remote,
                        onTap: () =>
                            _setRuntimeMode(CurationRuntimeMode.remote),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: '데이터',
                    subtitle: '가져오기, 초기화, 저장 현황을 한 곳에서 관리합니다.',
                  ),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      dataStats.when(
                        data: (stats) => Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _InfoPill(label: '저장된 기록 ${stats.recordCount}건'),
                              _InfoPill(
                                label:
                                    '벡터 DB ${_formatBytes(stats.databaseSizeBytes)}',
                              ),
                            ],
                          ),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(18),
                          child: LinearProgressIndicator(),
                        ),
                        error: (error, _) => Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            '데이터 상태를 읽지 못했습니다: $error',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      _GroupDivider(),
                      _ActionRow(
                        key: const Key('settingsImportButton'),
                        title: '파일 가져오기',
                        subtitle: '`.txt`, `.md` 기록을 앱으로 불러옵니다.',
                        icon: Icons.file_open_rounded,
                        accent: palette.accentStrong,
                        onTap: _importFiles,
                      ),
                      _GroupDivider(),
                      _ActionRow(
                        key: const Key('settingsResetSeedButton'),
                        title: '기본 시드 복원',
                        subtitle: '체험용 기본 기록으로 빠르게 되돌립니다.',
                        icon: Icons.restore_rounded,
                        accent: palette.highlightStrong,
                        onTap: _resetToSeedRecords,
                      ),
                      _GroupDivider(),
                      _ActionRow(
                        key: const Key('settingsClearDataButton'),
                        title: '전체 데이터 삭제',
                        subtitle: '앱 안에 저장된 로컬 기록과 인덱스를 제거합니다.',
                        icon: Icons.delete_sweep_rounded,
                        accent: theme.colorScheme.error,
                        onTap: _clearAllData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: '모델 준비',
                    subtitle: '개발자용 LiteRT 경로를 로컬 설정으로 덮어씁니다.',
                  ),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
                          ],
                        ),
                      ),
                      _GroupDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                        child: FilledButton.icon(
                          key: const Key('saveModelPathsButton'),
                          onPressed: _saveModelPaths,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('모델 경로 저장'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: '프라이버시',
                    subtitle: '저장 위치와 전송 정책을 한국어로 명확히 안내합니다.',
                  ),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      _InfoRow(
                        title: '데이터 저장 위치',
                        value:
                            '기록과 벡터 인덱스는 앱 로컬 SQLite 파일 `${config.vectorDbName}`에 저장됩니다.',
                      ),
                      _GroupDivider(),
                      const _InfoRow(
                        title: '외부 전송 정책',
                        value:
                            '온디바이스 모드에서는 기록과 임베딩을 외부로 보내지 않습니다. 원격 모드는 개발 점검용입니다.',
                      ),
                      _GroupDivider(),
                      const _InfoRow(
                        title: '안내 문구',
                        value:
                            '큐레이터는 의학·심리 진단 도구가 아니라, 일상 기록을 정리하고 질문을 돕는 개인 큐레이션 앱입니다.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: '앱 정보',
                    subtitle: '버전과 패키지 정보, 라이선스를 확인합니다.',
                  ),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      _InfoRow(title: '앱 이름', value: buildInfo.appName),
                      _GroupDivider(),
                      _InfoRow(title: '버전', value: buildInfo.versionLabel),
                      _GroupDivider(),
                      _InfoRow(title: '패키지', value: buildInfo.packageName),
                      _GroupDivider(),
                      _ActionRow(
                        key: const Key('showLicenseButton'),
                        title: '오픈소스 라이선스 보기',
                        subtitle: '앱에 포함된 라이브러리 정보를 확인합니다.',
                        icon: Icons.menu_book_rounded,
                        accent: palette.accentStrong,
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: buildInfo.appName,
                            applicationVersion: buildInfo.versionLabel,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setRuntimeMode(CurationRuntimeMode mode) async {
    await ref.read(appSettingsProvider.notifier).setRuntimeMode(mode);
    ref.invalidate(onDeviceRuntimeStatusProvider);
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

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.runtimeStatus});

  final AsyncValue<OnDeviceRuntimeStatus> runtimeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final status = runtimeStatus.asData?.value;
    final statusText = _runtimeSummary(status);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            palette.surfaceStrong.withValues(alpha: 0.9),
            palette.surface.withValues(alpha: 0.74),
            palette.accentSoft.withValues(alpha: 0.28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: palette.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CuratorOrbitArtwork(size: 130, icon: Icons.settings_rounded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 기록은 내 기기 안에서', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  statusText,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: palette.accentStrong,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceStrong.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? palette.accentSoft.withValues(alpha: 0.34)
                    : palette.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: palette.accentStrong),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? palette.accent : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? palette.accent
                      : palette.outline.withValues(alpha: 0.4),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.label,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.label),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(title, style: theme.textTheme.titleSmall),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelLarge),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    return Divider(
      height: 1,
      thickness: 1,
      color: palette.outline.withValues(alpha: 0.14),
      indent: 18,
      endIndent: 18,
    );
  }
}

String _runtimeSummary(OnDeviceRuntimeStatus? status) {
  if (status == null) {
    return '현재 기기 안 큐레이션 준비 상태를 확인하고 있습니다.';
  }
  if (status.runtime == 'remote-harness') {
    return '개발 점검을 위해 원격 하네스에 연결되어 있습니다.';
  }
  if (status.usingNativeLlm && status.usingNativeEmbedder) {
    return '질문과 검색이 모두 기기 안에서 준비된 상태입니다.';
  }
  if (status.usingNativeLlm) {
    return '생성은 네이티브, 일부 검색은 로컬 보조 경로로 이어집니다.';
  }
  return '네이티브 모델이 없어도 로컬 폴백으로 계속 사용할 수 있습니다.';
}
