import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A dependency-free sparkline/area chart used across the app.
///
/// The chart always runs from the oldest value on the left to the newest on
/// the right, even when it is placed inside an RTL interface.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 72,
    this.strokeWidth = 2.5,
    this.showArea = true,
    this.showEndDot = true,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final bool showArea;
  final bool showEndDot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(
          values: values,
          color: color,
          strokeWidth: strokeWidth,
          showArea: showArea,
          showEndDot: showEndDot,
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.showArea,
    required this.showEndDot,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool showArea;
  final bool showEndDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1);
    const verticalInset = 7.0;
    final chartHeight = math.max(size.height - verticalInset * 2, 1);
    final dx = values.length == 1 ? 0.0 : size.width / (values.length - 1);

    final points = <Offset>[
      for (var index = 0; index < values.length; index++)
        Offset(
          dx * index,
          verticalInset +
              chartHeight * (1 - ((values[index] - minValue) / range)),
        ),
    ];

    final line = _smoothPath(points);
    if (showArea) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showEndDot && points.isNotEmpty) {
      final point = points.last;
      canvas.drawCircle(
        point,
        5,
        Paint()..color = color.withValues(alpha: 0.2),
      );
      canvas.drawCircle(point, 2.6, Paint()..color = color);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path;
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midpoint = (previous.dx + current.dx) / 2;
      path.cubicTo(
        midpoint,
        previous.dy,
        midpoint,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showArea != showArea ||
        oldDelegate.showEndDot != showEndDot;
  }
}

class GridTrendChart extends StatelessWidget {
  const GridTrendChart({
    super.key,
    required this.primaryValues,
    required this.primaryColor,
    this.secondaryValues,
    this.secondaryColor,
    this.height = 190,
  });

  final List<double> primaryValues;
  final Color primaryColor;
  final List<double>? secondaryValues;
  final Color? secondaryColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _GridTrendPainter(
          primaryValues: primaryValues,
          primaryColor: primaryColor,
          secondaryValues: secondaryValues,
          secondaryColor: secondaryColor,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _GridTrendPainter extends CustomPainter {
  const _GridTrendPainter({
    required this.primaryValues,
    required this.primaryColor,
    required this.secondaryValues,
    required this.secondaryColor,
    required this.gridColor,
  });

  final List<double> primaryValues;
  final Color primaryColor;
  final List<double>? secondaryValues;
  final Color? secondaryColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    _drawSeries(canvas, size, primaryValues, primaryColor);
    final secondary = secondaryValues;
    final secondaryPaint = secondaryColor;
    if (secondary != null && secondaryPaint != null) {
      _drawSeries(canvas, size, secondary, secondaryPaint);
    }
  }

  void _drawSeries(Canvas canvas, Size size, List<double> values, Color color) {
    if (values.isEmpty) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? 0.0
          : size.width * index / (values.length - 1);
      final y =
          8 + (size.height - 16) * (1 - (values[index] - minValue) / range);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GridTrendPainter oldDelegate) => true;
}
