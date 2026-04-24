import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../state/app_shell_controller.dart';
import '../../theme/curator_theme.dart';

class NavDock extends StatelessWidget {
  const NavDock({
    super.key,
    required this.activeDestination,
    required this.onSelected,
  });

  final CuratorTab activeDestination;
  final ValueChanged<CuratorTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final items = <({CuratorTab destination, String label, IconData icon})>[
      (destination: CuratorTab.home, label: '오늘', icon: CupertinoIcons.house),
      (destination: CuratorTab.ask, label: '질문', icon: CupertinoIcons.search),
      (
        destination: CuratorTab.timeline,
        label: '타임라인',
        icon: CupertinoIcons.list_bullet,
      ),
      (
        destination: CuratorTab.settings,
        label: '설정',
        icon: CupertinoIcons.gear_alt,
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.paper.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: palette.line2.withValues(alpha: 0.9),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              10,
              8,
              bottomInset > 0 ? bottomInset + 2 : 8,
            ),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: _NavItem(
                      key: Key('navDock-${item.destination.name}'),
                      active: item.destination == activeDestination,
                      icon: item.icon,
                      label: item.label,
                      onTap: () => onSelected(item.destination),
                      textTheme: textTheme,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textTheme,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    final color = active ? palette.terra : palette.ink3;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontFamily: 'IBMPlexSansKR',
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
