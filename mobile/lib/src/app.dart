import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (!settings.onboardingCompleted) {
      return const OnboardingScreen();
    }
    return const HomeScreen();
  }
}
