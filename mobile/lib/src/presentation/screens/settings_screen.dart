import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_settings.dart';
import '../../data/import/calendar_import_service.dart';
import '../../data/import/import_history_service.dart';
import '../../data/import/notes_import_guide.dart';
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
  bool _developerToolsExpanded = false;

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
    final calendarStatus = ref.watch(calendarSyncStatusProvider);
    final dataStats = ref.watch(localDataStatsProvider);
    final importHistory = ref.watch(importHistorySnapshotProvider);
    final buildInfo = ref.watch(appBuildInfoProvider);
    final config = ref.watch(appConfigProvider);

    if (!_pathsInitialized) {
      _llmPathController.text = settings.llmModelPath ?? '';
      _embedderPathController.text = settings.embedderModelPath ?? '';
      _pathsInitialized = true;
    }

    return Material(
      type: MaterialType.transparency,
      child: CuratorBackdrop(
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 140),
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
                    title: '캘린더',
                    child: calendarStatus.when(
                      data: (status) => Column(
                        children: [
                          _SwitchRow(
                            key: const Key('settingsCalendarToggle'),
                            title: '캘린더 동기화',
                            subtitle: status.syncEnabled
                                ? '최근 30일 일정에서 큐레이션 문맥을 가져옵니다.'
                                : '켜면 권한을 요청하고 기기 일정 가져오기를 시작합니다.',
                            value: settings.calendarSyncEnabled,
                            onChanged: _toggleCalendarSync,
                          ),
                          const _HairlineDivider(),
                          _ValueRow(
                            title: '권한',
                            value: _calendarPermissionLabel(
                              status.permissionStatus,
                            ),
                          ),
                          const _HairlineDivider(),
                          _ValueRow(
                            title: '상태',
                            value: _calendarSyncStateLabel(status),
                          ),
                          const _HairlineDivider(),
                          _ValueRow(
                            title: '마지막 동기화',
                            value: _formatTimestamp(status.lastSyncedAt),
                          ),
                          const _HairlineDivider(),
                          _ValueRow(
                            title: '가져온 일정',
                            value: '${status.importedEventCount}건',
                          ),
                          const _HairlineDivider(),
                          _ActionRow(
                            key: const Key('settingsCalendarSyncButton'),
                            title: '지금 동기화',
                            subtitle: '최근 30일 기기 일정에서 중복 없이 다시 가져옵니다.',
                            actionLabel: '동기화',
                            onTap: _syncCalendar,
                          ),
                          const _HairlineDivider(),
                          _ActionRow(
                            key: const Key('settingsGoogleCalendarNoteButton'),
                            title: 'Google Calendar 가져오기 안내',
                            subtitle: 'iPhone 캘린더에 동기화된 Google 일정도 함께 읽을 수 있습니다.',
                            actionLabel: '보기',
                            onTap: _showGoogleCalendarNote,
                          ),
                          if (status.permissionStatus ==
                                  CalendarImportPermissionStatus.denied ||
                              status.permissionStatus ==
                                  CalendarImportPermissionStatus.writeOnly ||
                              status.permissionStatus ==
                                  CalendarImportPermissionStatus
                                      .restricted) ...[
                            const _HairlineDivider(),
                            _ActionRow(
                              key: const Key(
                                'settingsCalendarPermissionButton',
                              ),
                              title: '권한 설정 열기',
                              subtitle: '시스템 설정에서 캘린더 접근 권한을 바꿉니다.',
                              actionLabel: '열기',
                              onTap: _openCalendarPermissionSettings,
                            ),
                          ],
                          if (!status.syncEnabled)
                            const Padding(
                              padding: EdgeInsets.only(top: 18),
                              child: _DescriptionBlock(
                                text: '동기화를 꺼도 이미 가져온 일정 기록은 로컬 DB에 남아 있습니다.',
                              ),
                            ),
                        ],
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: LinearProgressIndicator(minHeight: 1.5),
                      ),
                      error: (error, _) => _DescriptionBlock(
                        text: '캘린더 상태를 읽지 못했습니다: $error',
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '데이터',
                    child: dataStats.when(
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
                          const _HairlineDivider(),
                          _ValueRow(
                            title: '데이터 소스',
                            value: _formatDataSourceSummary(stats.sourceCounts),
                          ),
                          const _HairlineDivider(),
                          _ActionRow(
                            key: const Key('settingsImportButton'),
                            title: '파일 가져오기',
                            subtitle: '`.txt`, `.md` 기록을 불러옵니다.',
                            actionLabel: '불러오기',
                            onTap: _importFiles,
                          ),
                          if (stats.recordCount == 0) ...[
                            const _HairlineDivider(),
                            _ActionRow(
                              key: const Key('settingsLoadDemoDataButton'),
                              title: '데모 데이터 로드',
                              subtitle: '체험용 기록 14건을 로컬 DB에 불러옵니다.',
                              actionLabel: '로드',
                              onTap: _loadDemoData,
                            ),
                          ],
                          const _HairlineDivider(),
                          _ActionRow(
                            key: const Key('settingsClearDataButton'),
                            title: '모든 데이터 삭제',
                            subtitle: '로컬 기록, 인덱스, 앱 설정을 모두 제거합니다.',
                            actionLabel: '삭제',
                            destructive: true,
                            onTap: _clearAllData,
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
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '가져오기 기록',
                    child: importHistory.when(
                      data: (history) {
                        if (history.recentEntries.isEmpty) {
                          return const _DescriptionBlock(
                            text: '아직 가져온 기록이 없습니다.',
                          );
                        }

                        return Column(
                          children: [
                            for (
                              var index = 0;
                              index < history.recentEntries.length;
                              index += 1
                            ) ...[
                              _HistoryRow(entry: history.recentEntries[index]),
                              if (index != history.recentEntries.length - 1)
                                const _HairlineDivider(),
                            ],
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: LinearProgressIndicator(minHeight: 1.5),
                      ),
                      error: (error, _) => _DescriptionBlock(
                        text: '가져오기 기록을 읽지 못했습니다: $error',
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '노트 가져오기',
                    child: Column(
                      children: [
                        _ActionRow(
                          key: const Key('settingsNotesImportButton'),
                          title: '내보낸 메모 파일 가져오기',
                          subtitle: 'Apple Notes에서 저장한 `.txt`, `.md` 파일을 바로 선택합니다.',
                          actionLabel: '불러오기',
                          onTap: _importFiles,
                        ),
                        const _HairlineDivider(),
                        _ActionRow(
                          key: const Key('settingsNotesGuideButton'),
                          title: 'Apple Notes 가져오기 안내',
                          subtitle: '공유 시트 연동과 `.txt` 또는 `.md` 파일 가져오기 흐름을 안내합니다.',
                          actionLabel: '가이드 보기',
                          onTap: _showNotesImportGuide,
                        ),
                        const SizedBox(height: 18),
                        const _DescriptionBlock(text: NotesImportGuide.summary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  _EditorialSection(
                    title: '개발자 런타임',
                    child: Column(
                      children: [
                        _ActionRow(
                          key: const Key('developerRuntimeToggleButton'),
                          title: '모델 경로와 런타임 디버그',
                          subtitle: _developerRuntimeSummary(settings),
                          actionLabel: _developerToolsExpanded ? '접기' : '열기',
                          onTap: () {
                            setState(() {
                              _developerToolsExpanded = !_developerToolsExpanded;
                            });
                          },
                        ),
                        if (_developerToolsExpanded) ...[
                          const _HairlineDivider(),
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
                          value: '암호화된 로컬 SQLite `${config.vectorDbName}`',
                        ),
                        const _HairlineDivider(),
                        const _ValueRow(
                          title: '외부 전송',
                          value: '온디바이스 모드에서는 기본적으로 외부 전송이 없습니다.',
                        ),
                        const _HairlineDivider(),
                        _ActionRow(
                          key: const Key('privacyPolicyButton'),
                          title: '개인정보 처리방침',
                          subtitle: '앱의 데이터 보관과 삭제 기준을 확인합니다.',
                          actionLabel: '보기',
                          onTap: _showPrivacyPolicy,
                        ),
                        const SizedBox(height: 18),
                        const _DescriptionBlock(
                          text:
                              '정책 원문은 저장소의 `docs/privacy/PRIVACY_POLICY.md`에 있습니다. 큐레이터는 의학·심리 진단 앱이 아니라, 일상 기록을 조용히 정리하고 질문을 돕는 개인 큐레이션 도구입니다.',
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
    if (result.importedCount > 0) {
      ref.read(localDataRevisionProvider.notifier).bump();
    }

    if (!mounted) {
      return;
    }

    if (!result.hasImportedRecords &&
        result.skippedFiles.isEmpty &&
        result.duplicateFiles.isEmpty) {
      _showMessage('선택한 파일이 없습니다.');
      return;
    }

    final skippedSummary = result.skippedFiles.isEmpty
        ? ''
        : ' 건너뜀 ${result.skippedFiles.length}건';
    final duplicateSummary = result.duplicateFiles.isEmpty
        ? ''
        : ' 중복 ${result.duplicateFiles.length}건';
    _showMessage(
      '파일 ${result.importedCount}건을 가져왔습니다.$duplicateSummary$skippedSummary',
    );
  }

  Future<void> _toggleCalendarSync(bool enabled) async {
    final controller = ref.read(appSettingsProvider.notifier);
    if (!enabled) {
      await controller.setCalendarSyncEnabled(false);
      ref.invalidate(calendarSyncStatusProvider);
      if (!mounted) {
        return;
      }
      _showMessage('캘린더 자동 동기화를 껐습니다.');
      return;
    }

    final permissionStatus = await ref
        .read(calendarImportServiceProvider)
        .requestPermission();
    if (permissionStatus != CalendarImportPermissionStatus.granted) {
      await controller.setCalendarSyncEnabled(false);
      ref.invalidate(calendarSyncStatusProvider);
      if (!mounted) {
        return;
      }
      _showMessage(_calendarPermissionErrorMessage(permissionStatus));
      return;
    }

    await controller.setCalendarSyncEnabled(true);
    ref.invalidate(calendarSyncStatusProvider);
    await _syncCalendar();
  }

  Future<void> _syncCalendar() async {
    final result = await ref
        .read(calendarImportServiceProvider)
        .syncRecentEvents();
    if (result.permissionStatus != CalendarImportPermissionStatus.granted) {
      ref.invalidate(calendarSyncStatusProvider);
      if (!mounted) {
        return;
      }
      _showMessage(_calendarPermissionErrorMessage(result.permissionStatus));
      return;
    }

    ref.read(localDataRevisionProvider.notifier).bump();
    ref.invalidate(calendarSyncStatusProvider);
    if (!mounted) {
      return;
    }

    if (!result.hasImportedRecords) {
      _showMessage('최근 30일 내 가져올 일정이 없습니다.');
      return;
    }
    _showMessage(
      '캘린더 일정 ${result.importedCount}건을 동기화했습니다. 조회 ${result.scannedCount}건',
    );
  }

  Future<void> _openCalendarPermissionSettings() async {
    await ref.read(calendarImportServiceProvider).openAppSettings();
    if (!mounted) {
      return;
    }
    _showMessage('시스템 설정에서 캘린더 권한을 확인해 주세요.');
  }

  Future<void> _loadDemoData() async {
    await ref.read(lifeRecordStoreProvider).loadDemoData();
    ref.read(localDataRevisionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    _showMessage('데모 데이터를 로드했습니다.');
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('모든 데이터를 삭제할까요?'),
          content: const Text('가져온 기록, 시드 데이터, 로컬 인덱스, 저장된 앱 설정이 모두 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(lifeRecordStoreProvider).deleteAllData();
    ref.read(localDataRevisionProvider.notifier).bump();
    ref.invalidate(appSettingsProvider);
    ref.invalidate(localDataInitializationProvider);
    ref.invalidate(onDeviceRuntimeStatusProvider);
    if (!mounted) {
      return;
    }
    _llmPathController.clear();
    _embedderPathController.clear();
    _showMessage('모든 로컬 데이터를 삭제했습니다.');
    Navigator.of(context).popUntil((route) => route.isFirst);
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

  Future<void> _showNotesImportGuide() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(NotesImportGuide.title),
          content: SingleChildScrollView(
            child: Text(
              [
                NotesImportGuide.summary,
                '',
                for (
                  var index = 0;
                  index < NotesImportGuide.steps.length;
                  index += 1
                )
                  '${index + 1}. ${NotesImportGuide.steps[index]}',
                '',
                NotesImportGuide.fallbackTip,
              ].join('\n'),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGoogleCalendarNote() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Google Calendar 안내'),
          content: const SingleChildScrollView(
            child: Text(
              '큐레이터는 `device_calendar_plus`를 통해 iPhone 기본 캘린더 저장소를 읽습니다.\n\n'
              '따라서 iOS 설정 또는 캘린더 앱에서 Google 계정을 연결해 두면, 기기에 동기화된 Google 일정도 같은 동기화 경로로 함께 가져올 수 있습니다.\n\n'
              '큐레이터가 Google 계정에 직접 로그인하거나 Google Calendar API를 호출하는 방식은 아닙니다.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPrivacyPolicy() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('개인정보 처리방침'),
          content: const SingleChildScrollView(
            child: Text(
              '큐레이터는 사용자가 직접 가져온 파일만 처리합니다.\n\n'
              '개인 기록은 기기 안의 암호화된 SQLite에 저장되며, 온디바이스 모드에서는 기록 내용이 외부로 전송되지 않습니다.\n\n'
              '데이터는 사용자가 삭제하기 전까지 유지되며, 설정의 "모든 데이터 삭제"로 언제든 제거할 수 있습니다.\n\n'
              '정책 원문: docs/privacy/PRIVACY_POLICY.md',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
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

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return '없음';
    }

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}.$month.$day $hour:$minute';
  }

  String _calendarPermissionLabel(CalendarImportPermissionStatus status) {
    return switch (status) {
      CalendarImportPermissionStatus.granted => '허용됨',
      CalendarImportPermissionStatus.denied => '거부됨',
      CalendarImportPermissionStatus.writeOnly => '쓰기 전용',
      CalendarImportPermissionStatus.restricted => '제한됨',
      CalendarImportPermissionStatus.notDetermined => '아직 요청하지 않음',
    };
  }

  String _calendarPermissionErrorMessage(
    CalendarImportPermissionStatus status,
  ) {
    return switch (status) {
      CalendarImportPermissionStatus.granted => '캘린더 권한이 허용되었습니다.',
      CalendarImportPermissionStatus.denied =>
        '캘린더 권한이 거부되었습니다. 설정에서 접근을 허용해 주세요.',
      CalendarImportPermissionStatus.writeOnly =>
        '쓰기 전용 권한만 허용되어 기존 일정을 읽을 수 없습니다. 전체 접근 권한이 필요합니다.',
      CalendarImportPermissionStatus.restricted => '이 기기에서는 캘린더 접근이 제한되어 있습니다.',
      CalendarImportPermissionStatus.notDetermined => '캘린더 권한을 먼저 허용해 주세요.',
    };
  }

  String _calendarSyncStateLabel(CalendarSyncStatus status) {
    if (!status.syncEnabled) {
      return '꺼짐';
    }
    if (!status.hasPermission) {
      return '권한 필요';
    }
    if (status.lastSyncedAt == null) {
      return '동기화 대기 중';
    }
    if (status.importedEventCount == 0) {
      return '동기화 완료, 저장된 일정 없음';
    }
    return '동기화 완료';
  }

  String _formatDataSourceSummary(Map<String, int> sourceCounts) {
    final orderedSources = <MapEntry<String, String>>[
      const MapEntry<String, String>('file', '파일'),
      const MapEntry<String, String>('diary', '일기'),
      const MapEntry<String, String>('note', '메모'),
      const MapEntry<String, String>('calendar', '캘린더'),
    ];
    final parts = <String>[
      for (final entry in orderedSources)
        if ((sourceCounts[entry.key] ?? 0) > 0)
          '${entry.value} ${sourceCounts[entry.key]}건',
      for (final entry in sourceCounts.entries)
        if (!orderedSources.any(
              (orderedEntry) => orderedEntry.key == entry.key,
            ) &&
            entry.value > 0)
          '${entry.key} ${entry.value}건',
    ];
    if (parts.isEmpty) {
      return '없음';
    }
    return parts.join(' · ');
  }

  String _developerRuntimeSummary(AppSettings settings) {
    final llmConfigured = settings.llmModelPath?.isNotEmpty ?? false;
    final embedderConfigured = settings.embedderModelPath?.isNotEmpty ?? false;
    if (!llmConfigured && !embedderConfigured) {
      return '일반 사용에는 필요 없는 개발자 전용 설정입니다.';
    }

    final configured = <String>[
      if (llmConfigured) 'LLM 경로 저장됨',
      if (embedderConfigured) '임베딩 경로 저장됨',
    ];
    return '${configured.join(' · ')}. 일반 사용에는 보통 열지 않아도 됩니다.';
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
    super.key,
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final ImportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final importedAt = entry.importedAt;
    final month = importedAt.month.toString().padLeft(2, '0');
    final day = importedAt.day.toString().padLeft(2, '0');
    final hour = importedAt.hour.toString().padLeft(2, '0');
    final minute = importedAt.minute.toString().padLeft(2, '0');
    final detail = entry.detail == null ? '' : '\n${entry.detail}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              _historySourceLabel(entry.importSource),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              '${entry.label}$detail\n${importedAt.year}.$month.$day $hour:$minute',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.label,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _historySourceLabel(String importSource) {
    return switch (importSource) {
      'calendar' => '캘린더',
      'file' => '파일',
      _ => '기타',
    };
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
