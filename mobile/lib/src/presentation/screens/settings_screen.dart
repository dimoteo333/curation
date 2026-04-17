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
      resizeToAvoidBottomInset: true,
      body: CuratorBackdrop(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 40),
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          tooltip: '뒤로 가기',
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('설정', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    _runtimeSummary(runtimeStatus.asData?.value),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.label,
                    ),
                  ),
                  const SizedBox(height: 42),
                  _EditorialSection(
                    title: '사용 방식',
                    child: Column(
                      children: [
                        _SwitchRow(
                          title: '온디바이스 우선',
                          subtitle: '질문과 기록을 기기 안에서 먼저 읽습니다.',
                          value:
                              settings.runtimeMode ==
                              CurationRuntimeMode.onDevice,
                          onChanged: (value) => _setRuntimeMode(
                            value
                                ? CurationRuntimeMode.onDevice
                                : CurationRuntimeMode.remote,
                          ),
                        ),
                        const _HairlineDivider(),
                        _ValueRow(
                          title: '현재 모드',
                          value:
                              settings.runtimeMode ==
                                  CurationRuntimeMode.onDevice
                              ? '온디바이스'
                              : '원격 점검',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '데이터',
                    child: Column(
                      children: [
                        dataStats.when(
                          data: (stats) => Column(
                            children: [
                              _ValueRow(
                                title: '저장된 기록',
                                value: '${stats.recordCount}건',
                              ),
                              const _HairlineDivider(),
                              _ValueRow(
                                title: '벡터 DB',
                                value: _formatBytes(stats.databaseSizeBytes),
                              ),
                            ],
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.only(bottom: 18),
                            child: LinearProgressIndicator(minHeight: 1.5),
                          ),
                          error: (error, _) => _DescriptionBlock(
                            text: '데이터 상태를 읽지 못했습니다: $error',
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const _HairlineDivider(),
                        _ActionRow(
                          key: const Key('settingsImportButton'),
                          title: '파일 가져오기',
                          subtitle: '`.txt`, `.md` 기록을 불러옵니다.',
                          actionLabel: '불러오기',
                          onTap: _importFiles,
                        ),
                        const _HairlineDivider(),
                        _ActionRow(
                          key: const Key('settingsResetSeedButton'),
                          title: '기본 시드 복원',
                          subtitle: '체험용 기본 기록으로 되돌립니다.',
                          actionLabel: '복원',
                          onTap: _resetToSeedRecords,
                        ),
                        const _HairlineDivider(),
                        _ActionRow(
                          key: const Key('settingsClearDataButton'),
                          title: '전체 데이터 삭제',
                          subtitle: '로컬 기록과 인덱스를 제거합니다.',
                          actionLabel: '삭제',
                          destructive: true,
                          onTap: _clearAllData,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '모델 준비',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          key: const Key('llmModelPathField'),
                          controller: _llmPathController,
                          decoration: const InputDecoration(
                            labelText: 'LLM 모델 경로',
                            hintText: '/path/to/gemma.task',
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          key: const Key('embedderModelPathField'),
                          controller: _embedderPathController,
                          decoration: const InputDecoration(
                            labelText: '임베딩 모델 경로',
                            hintText: '/path/to/embedder.tflite',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ActionRow(
                          key: const Key('saveModelPathsButton'),
                          title: '모델 경로 저장',
                          subtitle: '개발자용 로컬 경로로만 사용됩니다.',
                          actionLabel: '저장',
                          onTap: _saveModelPaths,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '프라이버시',
                    child: Column(
                      children: [
                        _ValueRow(
                          title: '저장 위치',
                          value: '로컬 SQLite `${config.vectorDbName}`',
                        ),
                        const _HairlineDivider(),
                        const _ValueRow(
                          title: '외부 전송',
                          value: '온디바이스 모드에서는 기본적으로 외부 전송이 없습니다.',
                        ),
                        const SizedBox(height: 18),
                        const _DescriptionBlock(
                          text:
                              '큐레이터는 의학·심리 진단 앱이 아니라, 일상 기록을 조용히 정리하고 질문을 돕는 개인 큐레이션 도구입니다.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '앱 정보',
                    child: Column(
                      children: [
                        _ValueRow(title: '앱 이름', value: buildInfo.appName),
                        const _HairlineDivider(),
                        _ValueRow(title: '버전', value: buildInfo.versionLabel),
                        const _HairlineDivider(),
                        _ValueRow(title: '패키지', value: buildInfo.packageName),
                        const _HairlineDivider(),
                        _ActionRow(
                          key: const Key('showLicenseButton'),
                          title: '오픈소스 라이선스',
                          subtitle: '앱에 포함된 라이브러리 정보를 확인합니다.',
                          actionLabel: '보기',
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

class _EditorialSection extends StatelessWidget {
  const _EditorialSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelSmall),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.label,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Transform.scale(
            scale: 0.88,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool destructive;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final accent = widget.destructive
        ? theme.colorScheme.error
        : palette.accentStrong;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.99 : 1,
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
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.label,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.actionLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accent,
                    decoration: TextDecoration.underline,
                    decorationColor: accent.withValues(alpha: 0.46),
                    decorationThickness: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(title, style: theme.textTheme.bodySmall),
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

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color));
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return Divider(
      height: 1,
      thickness: 0.8,
      color: palette.outline.withValues(alpha: 0.38),
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
