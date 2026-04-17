import 'package:flutter/material.dart';

import '../../theme/curator_theme.dart';

class CuratorBackdrop extends StatelessWidget {
  const CuratorBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return DecoratedBox(
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
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -50,
            child: _GlowOrb(
              color: palette.ambientGlow.withValues(alpha: 0.24),
              diameter: 320,
            ),
          ),
          Positioned(
            top: 180,
            right: -110,
            child: _GlowOrb(
              color: palette.accent.withValues(alpha: 0.16),
              diameter: 280,
            ),
          ),
          Positioned(
            bottom: -120,
            left: 20,
            child: _GlowOrb(
              color: palette.highlight.withValues(alpha: 0.18),
              diameter: 260,
            ),
          ),
          Positioned(
            bottom: 110,
            right: 42,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: palette.outline.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class CuratorOrbitArtwork extends StatelessWidget {
  const CuratorOrbitArtwork({
    super.key,
    this.size = 220,
    this.icon = Icons.auto_awesome_rounded,
    this.showBrandMark = true,
  });

  final double size;
  final IconData icon;
  final bool showBrandMark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<CuratorPalette>()!;
    final orbSize = size * 0.78;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  palette.highlight.withValues(alpha: 0.6),
                  palette.accent.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.22,
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.28),
                gradient: LinearGradient(
                  colors: <Color>[
                    palette.highlight.withValues(alpha: 0.92),
                    palette.accent.withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadowColor.withValues(alpha: 0.16),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.38),
                width: 1.5,
              ),
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.16,
            child: Container(
              width: size * 0.17,
              height: size * 0.17,
              decoration: BoxDecoration(
                color: palette.surfaceStrong.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
              child: Icon(icon, size: size * 0.09, color: palette.accentStrong),
            ),
          ),
          Positioned(
            bottom: size * 0.12,
            left: size * 0.12,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: palette.surfaceStrong.withValues(alpha: 0.74),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.outline.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          if (showBrandMark)
            Container(
              width: size * 0.44,
              height: size * 0.44,
              padding: EdgeInsets.all(size * 0.07),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(size * 0.16),
                border: Border.all(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                ),
              ),
              child: Image.asset('assets/branding/curator_mark.png'),
            ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: diameter * 0.5,
            spreadRadius: diameter * 0.12,
          ),
        ],
      ),
    );
  }
}
