import 'package:flutter/material.dart';

import '../../theme/curator_theme.dart';

class CuratorBackdrop extends StatelessWidget {
  const CuratorBackdrop({
    super.key,
    required this.child,
    this.includePaperGrain = true,
  });

  final Widget child;
  final bool includePaperGrain;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            palette.paper,
            palette.backdropAccent,
            palette.backdropBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _EditorialHalo(
              diameter: 320,
              color: palette.terra.withValues(alpha: palette.isDark ? 0.14 : 0.12),
            ),
          ),
          Positioned(
            top: 160,
            left: -120,
            child: _EditorialHalo(
              diameter: 280,
              color: palette.ochre.withValues(alpha: palette.isDark ? 0.08 : 0.07),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -90,
            child: _EditorialHalo(
              diameter: 260,
              color: palette.terraSoft.withValues(
                alpha: palette.isDark ? 0.18 : 0.24,
              ),
            ),
          ),
          if (includePaperGrain)
            const Positioned.fill(child: PaperGrain(opacity: 0.18)),
          child,
        ],
      ),
    );
  }
}

class PaperGrain extends StatelessWidget {
  const PaperGrain({
    super.key,
    this.opacity = 0.18,
    this.borderRadius,
  });

  final double opacity;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.72, -0.78),
              radius: 1.3,
              colors: <Color>[
                palette.terra.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const <double>[0, 0.58],
            ),
          ),
          child: CustomPaint(
            painter: _PaperGrainPainter(
              darkInk: palette.ink.withValues(alpha: opacity * 0.22),
              warmInk: palette.ochre.withValues(alpha: opacity * 0.18),
              coolInk: palette.terra.withValues(alpha: opacity * 0.14),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class CuratorMark extends StatelessWidget {
  const CuratorMark({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CuratorPalette>()!;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CuratorMarkPainter(color ?? palette.terra),
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
            diameter: size * 1.5,
            color: palette.terra.withValues(alpha: 0.16),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              color: palette.surfaceStrong.withValues(alpha: 0.84),
              border: Border.all(color: palette.line2),
              boxShadow: palette.shadowCard,
            ),
            child: Center(
              child: CuratorMark(
                size: size * 0.48,
                color: palette.terra,
              ),
            ),
          ),
        ],
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
        boxShadow: <BoxShadow>[
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

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter({
    required this.darkInk,
    required this.warmInk,
    required this.coolInk,
  });

  final Color darkInk;
  final Color warmInk;
  final Color coolInk;

  @override
  void paint(Canvas canvas, Size size) {
    final grain = Paint()..style = PaintingStyle.fill;
    final soft = Paint()..style = PaintingStyle.fill;
    final shimmer = Paint()..style = PaintingStyle.fill;

    var seed = 73;
    for (var index = 0; index < 280; index += 1) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final x = (seed % 1000) / 1000 * size.width;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final y = (seed % 1000) / 1000 * size.height;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final radius = 0.35 + (seed % 1000) / 1000 * 0.7;

      grain.color = index.isEven ? darkInk : warmInk;
      canvas.drawCircle(Offset(x, y), radius, grain);
    }

    for (var index = 0; index < 40; index += 1) {
      final dx = size.width * ((index * 37) % 100) / 100;
      final dy = size.height * ((index * 53) % 100) / 100;
      soft.color = warmInk.withValues(alpha: warmInk.a * 0.6);
      canvas.drawCircle(Offset(dx, dy), 1.3, soft);
    }

    shimmer.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Colors.transparent,
        coolInk.withValues(alpha: coolInk.a * 0.9),
        Colors.transparent,
      ],
      stops: const <double>[0.0, 0.5, 1.0],
      transform: const GradientRotation(-0.5),
    ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, shimmer);
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter other) {
    return darkInk != other.darkInk ||
        warmInk != other.warmInk ||
        coolInk != other.coolInk;
  }
}

class _CuratorMarkPainter extends CustomPainter {
  const _CuratorMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final left = Path()
      ..moveTo(size.width * 0.18, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.16,
        size.width * 0.25,
        size.height * 0.16,
      )
      ..lineTo(size.width * 0.47, size.height * 0.16)
      ..lineTo(size.width * 0.47, size.height * 0.8)
      ..lineTo(size.width * 0.25, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.8,
        size.width * 0.18,
        size.height * 0.74,
      )
      ..close();

    final right = Path()
      ..moveTo(size.width * 0.82, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.16,
        size.width * 0.75,
        size.height * 0.16,
      )
      ..lineTo(size.width * 0.53, size.height * 0.16)
      ..lineTo(size.width * 0.53, size.height * 0.8)
      ..lineTo(size.width * 0.75, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.8,
        size.width * 0.82,
        size.height * 0.74,
      )
      ..close();

    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      size.width * 0.11,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CuratorMarkPainter other) {
    return color != other.color;
  }
}
