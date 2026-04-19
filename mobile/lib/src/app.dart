import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/security/database_encryption.dart';
import 'presentation/screens/ask_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/timeline_screen.dart';
import 'presentation/widgets/nav_dock.dart';
import 'providers.dart';
import 'state/app_shell_controller.dart';
import 'theme/curator_theme.dart';

class CuratorApp extends StatelessWidget {
  const CuratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '큐레이터',
      debugShowCheckedModeBanner: false,
      theme: buildCuratorTheme(Brightness.light),
      darkTheme: buildCuratorTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final localDataInitialization = ref.watch(localDataInitializationProvider);

    return localDataInitialization.when(
      data: (_) {
        if (!settings.onboardingCompleted) {
          return const OnboardingScreen();
        }
        return const CuratorAppShell();
      },
      loading: () => const _StartupStatusScreen(
        title: '로컬 데이터를 준비하는 중입니다',
        message: '기기 안의 기록 저장소를 안전하게 확인하고 있습니다.',
      ),
      error: (error, _) {
        if (error is LocalDataInitializationRecoveryRequiredException) {
          if (_requiresLocalDataRecovery(error)) {
            return _LocalDataRecoveryScreen(recovery: error);
          }
          return _LocalDataRetryScreen(
            title: error.title,
            message: error.message,
            details: error.details,
          );
        }
        if (error is DatabaseEncryptionResetRequiredException) {
          return _LocalDataRecoveryScreen(
            recovery:
                LocalDataInitializationRecoveryRequiredException.fromEncryptionError(
                  error,
                ),
          );
        }
        return _LocalDataRetryScreen(
          title: '앱을 바로 열 수 없습니다',
          message: '로컬 데이터를 준비하는 중 문제가 발생했습니다. 다시 시도해 주세요.',
          details: error.toString(),
        );
      },
    );
  }
}

bool _requiresLocalDataRecovery(
  LocalDataInitializationRecoveryRequiredException recovery,
) {
  return switch (recovery.reason) {
    LocalDataInitializationRecoveryReason.missingKeyForExistingDatabase ||
    LocalDataInitializationRecoveryReason.encryptedDataUnavailable ||
    LocalDataInitializationRecoveryReason.corruptedDatabase => true,
    LocalDataInitializationRecoveryReason.unknown => false,
  };
}

class CuratorAppShell extends ConsumerStatefulWidget {
  const CuratorAppShell({super.key});

  @override
  ConsumerState<CuratorAppShell> createState() => _CuratorAppShellState();
}

class _CuratorAppShellState extends ConsumerState<CuratorAppShell> {
  bool _didRequestFirstRunVersion = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final shellState = ref.watch(curatorAppShellProvider);

    if (!_didRequestFirstRunVersion && settings.firstRunVersion == null) {
      _didRequestFirstRunVersion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref.read(appSettingsProvider.notifier).ensureFirstRunVersion(),
        );
      });
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: shellState.currentTab.index,
              children: const [
                HomeScreen(),
                AskScreen(),
                TimelineScreen(),
                SettingsScreen(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NavDock(
              activeDestination: shellState.currentTab,
              onSelected: (tab) {
                ref.read(curatorAppShellProvider.notifier).selectTab(tab);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalDataRetryScreen extends ConsumerWidget {
  const _LocalDataRetryScreen({
    required this.title,
    required this.message,
    this.details,
  });

  final String title;
  final String message;
  final String? details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.sync_problem_rounded,
                    size: 44,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (details != null && details!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      details!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('localDataRetryOnlyButton'),
                    onPressed: () =>
                        ref.invalidate(localDataInitializationProvider),
                    child: const Text('다시 시도'),
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

class _StartupStatusScreen extends StatelessWidget {
  const _StartupStatusScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalDataRecoveryScreen extends ConsumerStatefulWidget {
  const _LocalDataRecoveryScreen({required this.recovery});

  final LocalDataInitializationRecoveryRequiredException recovery;

  @override
  ConsumerState<_LocalDataRecoveryScreen> createState() =>
      _LocalDataRecoveryScreenState();
}

class _LocalDataRecoveryScreenState
    extends ConsumerState<_LocalDataRecoveryScreen> {
  bool _isResetting = false;
  String? _resetError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 44,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.recovery.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.recovery.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '초기화 시 삭제되는 항목\n${widget.recovery.lossDescription}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (_resetError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _resetError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton(
                    key: const Key('localDataRecoveryRetryButton'),
                    onPressed: _isResetting
                        ? null
                        : () => ref.invalidate(localDataInitializationProvider),
                    child: const Text('다시 시도'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('localDataRecoveryResetButton'),
                    onPressed: _isResetting ? null : _resetLocalData,
                    child: Text(_isResetting ? '초기화 중...' : '초기화하고 새로 시작하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetLocalData() async {
    setState(() {
      _isResetting = true;
      _resetError = null;
    });
    try {
      await ref.read(lifeRecordStoreProvider).deleteAllData();
      ref.read(localDataRevisionProvider.notifier).bump();
      ref.invalidate(appSettingsProvider);
      ref.invalidate(importHistorySnapshotProvider);
      ref.invalidate(calendarSyncStatusProvider);
      ref.invalidate(onDeviceRuntimeStatusProvider);
      ref.invalidate(recentConversationsProvider);
      ref.invalidate(localDataInitializationProvider);
    } catch (error) {
      if (mounted) {
        setState(() {
          _resetError = '초기화 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }
}
