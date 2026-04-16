import 'package:flutter/material.dart';

import 'presentation/screens/home_screen.dart';
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
      home: const HomeScreen(),
    );
  }
}
