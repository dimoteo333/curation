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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _EditorialHalo(
              diameter: 320,
              color: palette.ambientGlow.withValues(alpha: 0.11),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _EditorialHalo(
              diameter: 300,
              color: palette.accent.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 140,
            left: 36,
            child: _HairlineFrame(
              width: 84,
              height: 84,
              color: palette.outline.withValues(alpha: 0.18),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class CuratorMarkArtwork extends StatelessWidget {
  const CuratorMarkArtwork({super.key, this.size = 136, this.opacity = 1});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return Opacity(
      opacity: opacity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _EditorialHalo(
            diameter: size * 1.45,
            color: palette.ambientGlow.withValues(alpha: 0.18),
          ),
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              gradient: LinearGradient(
                colors: <Color>[
                  palette.accent.withValues(alpha: 0.94),
                  palette.accentSoft.withValues(alpha: 0.94),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Image.asset('assets/branding/curator_mark.png'),
          ),
        ],
      ),
    );
  }
}

class _HairlineFrame extends StatelessWidget {
  const _HairlineFrame({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color, width: 0.9),
      ),
    );
  }
}

class _EditorialHalo extends StatelessWidget {
  const _EditorialHalo({required this.diameter, required this.color});

  final double diameter;
  final Color color;

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
            blurRadius: diameter * 0.42,
            spreadRadius: diameter * 0.02,
          ),
        ],
      ),
    );
  }
}
