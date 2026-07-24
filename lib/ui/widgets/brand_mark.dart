import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Ravand's code-native brand mark.
///
/// The symbol combines a simplified car profile with an ascending market line.
/// Use the compact default in app bars and [BrandMark.lockup] where the Persian
/// wordmark (and optional tagline) has enough horizontal space. Increasing
/// [size] to 80–112 also makes the symbol suitable for empty states.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 44,
    this.showWordmark = false,
    this.showTagline = false,
    this.foregroundColor,
    this.accentColor,
    this.backgroundColor,
    this.wordmarkColor,
    this.semanticLabel = 'روند، هوشمندی بازار خودرو',
  });

  const BrandMark.lockup({
    super.key,
    this.size = 44,
    this.showTagline = false,
    this.foregroundColor,
    this.accentColor,
    this.backgroundColor,
    this.wordmarkColor,
    this.semanticLabel = 'روند، هوشمندی بازار خودرو',
  }) : showWordmark = true;

  /// Width and height of the square symbol.
  final double size;

  /// Adds the Persian “روند” wordmark beside the symbol.
  final bool showWordmark;

  /// Adds “هوشمندی بازار خودرو” below the wordmark.
  final bool showTagline;

  /// Color of the car silhouette. Defaults to white.
  final Color? foregroundColor;

  /// Color of the market line and wheel hubs.
  final Color? accentColor;

  /// Replaces the standard navy-to-indigo background with a solid color.
  final Color? backgroundColor;

  /// Overrides the theme-aware wordmark color.
  final Color? wordmarkColor;

  /// Spoken description for screen readers.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(size > 0, 'BrandMark.size must be greater than zero.');

    final theme = Theme.of(context);
    final marketColors = MarketColors.of(context);
    final symbol = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          backgroundStart: backgroundColor ?? marketColors.heroStart,
          backgroundEnd: backgroundColor ?? marketColors.heroEnd,
          foreground: foregroundColor ?? Colors.white,
          accent: accentColor ?? marketColors.chartSecondary,
        ),
      ),
    );

    final Widget mark;
    if (!showWordmark && !showTagline) {
      mark = symbol;
    } else {
      final titleSize = (size * 0.44).clamp(18.0, 32.0);
      final taglineSize = (size * 0.25).clamp(11.0, 15.0);
      final textColor = wordmarkColor ?? theme.colorScheme.onSurface;

      mark = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          symbol,
          SizedBox(width: size * 0.28),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'روند',
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontSize: titleSize,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 2),
                Text(
                  'هوشمندی بازار خودرو',
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.68),
                    fontSize: taglineSize,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: mark),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.foreground,
    required this.accent,
  });

  final Color backgroundStart;
  final Color backgroundEnd;
  final Color foreground;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shortestSide = size.shortestSide;
    final radius = Radius.circular(shortestSide * 0.28);
    final outer = RRect.fromRectAndRadius(rect, radius);

    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [backgroundStart, backgroundEnd],
        ).createShader(rect),
    );

    // Quiet orbital rings give the emblem depth without image assets.
    final ringPaint = Paint()
      ..color = foreground.withValues(alpha: 0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortestSide * 0.018;
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.13),
      shortestSide * 0.30,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.93),
      shortestSide * 0.39,
      ringPaint,
    );

    final carFill = Path()
      ..moveTo(size.width * 0.13, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.14,
        size.height * 0.59,
        size.width * 0.26,
        size.height * 0.56,
      )
      ..lineTo(size.width * 0.34, size.height * 0.43)
      ..quadraticBezierTo(
        size.width * 0.39,
        size.height * 0.35,
        size.width * 0.50,
        size.height * 0.35,
      )
      ..lineTo(size.width * 0.61, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.36,
        size.width * 0.75,
        size.height * 0.46,
      )
      ..lineTo(size.width * 0.82, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.58,
        size.width * 0.92,
        size.height * 0.66,
      )
      ..lineTo(size.width * 0.92, size.height * 0.70)
      ..lineTo(size.width * 0.13, size.height * 0.70)
      ..close();

    canvas.drawPath(
      carFill,
      Paint()
        ..color = foreground.withValues(alpha: 0.13)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      carFill,
      Paint()
        ..color = foreground.withValues(alpha: 0.94)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortestSide * 0.035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // The roof doubles as a market trend line, making the icon recognisable
    // even at app-bar size.
    final trend = Path()
      ..moveTo(size.width * 0.27, size.height * 0.55)
      ..lineTo(size.width * 0.41, size.height * 0.43)
      ..lineTo(size.width * 0.54, size.height * 0.49)
      ..lineTo(size.width * 0.74, size.height * 0.29);
    final trendPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortestSide * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trend, trendPaint);

    final arrow = Path()
      ..moveTo(size.width * 0.64, size.height * 0.30)
      ..lineTo(size.width * 0.74, size.height * 0.29)
      ..lineTo(size.width * 0.73, size.height * 0.39);
    canvas.drawPath(arrow, trendPaint);

    _paintWheel(
      canvas,
      center: Offset(size.width * 0.31, size.height * 0.70),
      radius: shortestSide * 0.088,
    );
    _paintWheel(
      canvas,
      center: Offset(size.width * 0.75, size.height * 0.70),
      radius: shortestSide * 0.088,
    );

    canvas.restore();
  }

  void _paintWheel(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    canvas.drawCircle(center, radius, Paint()..color = backgroundStart);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.42,
    );
    canvas.drawCircle(center, radius * 0.31, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) {
    return backgroundStart != oldDelegate.backgroundStart ||
        backgroundEnd != oldDelegate.backgroundEnd ||
        foreground != oldDelegate.foreground ||
        accent != oldDelegate.accent;
  }
}
