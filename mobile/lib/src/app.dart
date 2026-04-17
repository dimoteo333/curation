import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/security/database_encryption.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'providers.dart';
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
      themeMode: ThemeMode.system,
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
        return const HomeScreen();
      },
      loading: () => const _StartupStatusScreen(
        title: '로컬 데이터를 준비하는 중입니다',
        message: '기기 안의 기록 저장소를 안전하게 확인하고 있습니다.',
      ),
      error: (error, _) {
        if (error is DatabaseEncryptionResetRequiredException) {
          return _LocalDataRecoveryScreen(error: error);
        }
        return _StartupStatusScreen(
          title: '앱을 시작하지 못했습니다',
          message: '로컬 데이터 준비 중 오류가 발생했습니다.\n$error',
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(localDataInitializationProvider),
        );
      },
    );
  }
}

class _StartupStatusScreen extends StatelessWidget {
  const _StartupStatusScreen({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                if (onAction == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                ],
                Text(title, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalDataRecoveryScreen extends ConsumerStatefulWidget {
  const _LocalDataRecoveryScreen({required this.error});

  final DatabaseEncryptionResetRequiredException error;

  @override
  ConsumerState<_LocalDataRecoveryScreen> createState() =>
      _LocalDataRecoveryScreenState();
}

class _LocalDataRecoveryScreenState
    extends ConsumerState<_LocalDataRecoveryScreen> {
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    return _StartupStatusScreen(
      title: '로컬 데이터를 복구할 수 없습니다',
      message: widget.error.message,
      actionLabel: _isResetting ? '초기화 중...' : '로컬 데이터 초기화',
      onAction: _isResetting ? null : _resetLocalData,
    );
  }

  Future<void> _resetLocalData() async {
    setState(() => _isResetting = true);
    try {
      await ref.read(lifeRecordStoreProvider).deleteAllData();
      ref.read(localDataRevisionProvider.notifier).bump();
      ref.invalidate(appSettingsProvider);
      ref.invalidate(importHistorySnapshotProvider);
      ref.invalidate(calendarSyncStatusProvider);
      ref.invalidate(onDeviceRuntimeStatusProvider);
      ref.invalidate(localDataInitializationProvider);
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }
}
