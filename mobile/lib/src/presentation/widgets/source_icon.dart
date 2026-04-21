import 'dart:math' as math;

import 'package:flutter/material.dart';

class SourceIcon extends StatelessWidget {
  const SourceIcon({
    super.key,
    required this.source,
    this.size = 14,
    this.color,
  });

  final String source;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final normalized = source.trim().toLowerCase();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SourceIconPainter(
          source: normalized,
          color:
              color ??
              IconTheme.of(context).color ??
              DefaultTextStyle.of(context).style.color ??
              Colors.black,
        ),
      ),
    );
  }
}

class _SourceIconPainter extends CustomPainter {
  const _SourceIconPainter({required this.source, required this.color});

  final String source;
  final Color color;

  bool get _isDiary => source == 'diary' || source == 'journal';
  bool get _isCalendar => source == 'calendar';
  bool get _isMemo => source == 'memo' || source == 'note' || source == 'file';
  bool get _isVoice =>
      source == 'voice_memo' || source == 'voice' || source == 'audio';

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    if (_isDiary) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.14,
          size.width * 0.64,
          size.height * 0.72,
        ),
        Radius.circular(size.width * 0.07),
      );
      canvas.drawRRect(rect, stroke);
      for (final factor in <double>[0.34, 0.5, 0.66]) {
        canvas.drawLine(
          Offset(size.width * 0.34, size.height * factor),
          Offset(size.width * 0.66, size.height * factor),
          stroke,
        );
      }
      return;
    }

    if (_isCalendar) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.22,
          size.width * 0.68,
          size.height * 0.56,
        ),
        Radius.circular(size.width * 0.08),
      );
      canvas.drawRRect(rect, stroke);
      canvas.drawLine(
        Offset(size.width * 0.3, size.height * 0.14),
        Offset(size.width * 0.3, size.height * 0.32),
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.14),
        Offset(size.width * 0.7, size.height * 0.32),
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.16, size.height * 0.42),
        Offset(size.width * 0.84, size.height * 0.42),
        stroke,
      );
      return;
    }

    if (_isMemo) {
      final path = Path()
        ..moveTo(size.width * 0.24, size.height * 0.14)
        ..lineTo(size.width * 0.7, size.height * 0.14)
        ..lineTo(size.width * 0.8, size.height * 0.24)
        ..lineTo(size.width * 0.8, size.height * 0.82)
        ..lineTo(size.width * 0.24, size.height * 0.82)
        ..close();
      canvas.drawPath(path, stroke);
      final fold = Path()
        ..moveTo(size.width * 0.7, size.height * 0.14)
        ..lineTo(size.width * 0.7, size.height * 0.24)
        ..lineTo(size.width * 0.8, size.height * 0.24)
        ..close();
      canvas.drawPath(fold, fill);
      canvas.drawPath(fold, stroke);
      return;
    }

    if (_isVoice) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.14,
          size.width * 0.24,
          size.height * 0.42,
        ),
        Radius.circular(size.width * 0.14),
      );
      canvas.drawRRect(rect, stroke);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.46),
          radius: size.width * 0.24,
        ),
        math.pi,
        math.pi,
        false,
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.5, size.height * 0.7),
        Offset(size.width * 0.5, size.height * 0.86),
        stroke,
      );
      return;
    }

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.22,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SourceIconPainter other) {
    return source != other.source || color != other.color;
  }
}
