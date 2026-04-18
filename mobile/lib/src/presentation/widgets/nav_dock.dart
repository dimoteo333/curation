import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/curator_theme.dart';

enum CuratorNavDestination { home, ask, settings }

class NavDock extends StatelessWidget {
  const NavDock({
    super.key,
    required this.activeDestination,
    required this.onSelected,
  });

  final CuratorNavDestination activeDestination;
  final ValueChanged<CuratorNavDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    final textTheme = Theme.of(context).textTheme;
    final items = <({CuratorNavDestination destination, String label, IconData icon})>[
      (
        destination: CuratorNavDestination.home,
        label: '오늘',
        icon: CupertinoIcons.house,
      ),
      (
        destination: CuratorNavDestination.ask,
        label: '질문',
        icon: CupertinoIcons.search,
      ),
      (
        destination: CuratorNavDestination.settings,
        label: '설정',
        icon: CupertinoIcons.gear,
      ),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Container(
        decoration: BoxDecoration(
          color: palette.paper.withValues(alpha: palette.isDark ? 0.92 : 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.line),
          boxShadow: palette.shadowSoft,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final active = item.destination == activeDestination;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(item.destination),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 21,
                        color: active ? palette.terraDeep : palette.ink3,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: textTheme.labelMedium?.copyWith(
                          fontFamily: 'IBMPlexSansKR',
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: -0.1,
                          color: active ? palette.terraDeep : palette.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}
