import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/car_model.dart';
import '../../data/car_repository.dart';
import 'trend_chart.dart';

class PageGutter extends StatelessWidget {
  const PageGutter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width > 760 ? 700 : double.infinity,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class ChangePill extends StatelessWidget {
  const ChangePill({
    super.key,
    required this.value,
    this.compact = false,
    this.neutralLabel,
  });

  final double value;
  final bool compact;
  final String? neutralLabel;

  @override
  Widget build(BuildContext context) {
    final positive = value > 0;
    final negative = value < 0;
    final color = positive
        ? const Color(0xFF12956F)
        : negative
        ? const Color(0xFFDC5260)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = positive
        ? Icons.arrow_upward_rounded
        : negative
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;
    return Semantics(
      label: value == 0
          ? neutralLabel ?? 'بدون تغییر'
          : '${positive ? 'رشد' : 'افت'} ${formatPercent(value.abs())}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 7 : 9,
            compact ? 4 : 6,
            compact ? 6 : 8,
            compact ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 13 : 15, color: color),
              const SizedBox(width: 3),
              Text(
                value == 0 && neutralLabel != null
                    ? neutralLabel!
                    : formatPercent(value),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarAvatar extends StatelessWidget {
  const CarAvatar({super.key, required this.car, this.size = 52});

  final CarModel car;
  final double size;

  static const _palettes = [
    [Color(0xFF3158FF), Color(0xFF8296FF)],
    [Color(0xFF18A594), Color(0xFF57D3C4)],
    [Color(0xFF7B55DE), Color(0xFFB291FF)],
    [Color(0xFFE17550), Color(0xFFF5AC72)],
  ];

  @override
  Widget build(BuildContext context) {
    final index = car.id.abs() % _palettes.length;
    final colors = _palettes[index];
    final initial = car.brand.trim().isNotEmpty
        ? car.brand.trim().characters.first
        : 'خ';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.39,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class CarCard extends StatelessWidget {
  const CarCard({
    super.key,
    required this.car,
    required this.onTap,
    this.isFavorite = false,
    this.isCompared = false,
    this.onFavorite,
    this.onCompare,
    this.showTrend = true,
    this.margin,
  });

  final CarModel car;
  final VoidCallback onTap;
  final bool isFavorite;
  final bool isCompared;
  final VoidCallback? onFavorite;
  final VoidCallback? onCompare;
  final bool showTrend;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final positive = car.changePercent >= 0;
    final trendValues = car.history.isNotEmpty
        ? car.history.map((point) => point.price.toDouble()).toList()
        : _fallbackTrend(car);
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarAvatar(car: car),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (car.year > 0)
                              MetaLabel(
                                label: 'مدل ${toPersianDigits(car.year)}',
                              ),
                            MetaLabel(
                              label: car.marketPrice ? 'بازار' : 'کارخانه',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onFavorite != null)
                    IconButton(
                      tooltip: isFavorite
                          ? 'حذف از علاقه‌مندی'
                          : 'افزودن به علاقه‌مندی',
                      onPressed: onFavorite,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isFavorite
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قیمت امروز',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          car.price > 0
                              ? formatCompactToman(car.price)
                              : 'قیمت ناموجود',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ChangePill(value: car.changePercent, compact: true),
                      ],
                    ),
                  ),
                  if (showTrend)
                    SizedBox(
                      width: 108,
                      child: TrendChart(
                        values: trendValues,
                        color: positive
                            ? const Color(0xFF12956F)
                            : const Color(0xFFDC5260),
                        height: 58,
                        strokeWidth: 2.2,
                      ),
                    ),
                ],
              ),
              if (onCompare != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        car.lastUpdate.isEmpty ? 'زمان نامشخص' : car.lastUpdate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onCompare,
                      icon: Icon(
                        isCompared
                            ? Icons.check_rounded
                            : Icons.compare_arrows_rounded,
                        size: 18,
                      ),
                      label: Text(isCompared ? 'انتخاب شد' : 'مقایسه'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<double> _fallbackTrend(CarModel car) {
    final base = car.price <= 0 ? 1.0 : car.price.toDouble();
    final delta = car.changePercent / 100;
    return [
      base * (1 - delta * 1.4),
      base * (1 - delta * 1.1),
      base * (1 - delta * 0.7),
      base * (1 - delta * 0.9),
      base * (1 - delta * 0.3),
      base,
    ];
  }
}

class MetaLabel extends StatelessWidget {
  const MetaLabel({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12),
              const SizedBox(width: 3),
            ],
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class SourcePill extends StatelessWidget {
  const SourcePill({super.key, required this.source, this.onTap});

  final CarDataSource source;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (source) {
      CarDataSource.network => (
        'داده زنده',
        Icons.wifi_rounded,
        const Color(0xFF12956F),
      ),
      CarDataSource.cache => (
        'داده ذخیره‌شده',
        Icons.cloud_off_rounded,
        const Color(0xFFE8A62A),
      ),
      CarDataSource.demo => (
        'حالت نمایشی',
        Icons.auto_awesome_rounded,
        const Color(0xFF7B55DE),
      ),
    };
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 15, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.09),
      side: BorderSide(color: color.withValues(alpha: 0.12)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
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

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                icon,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 120),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _LoadingCard(),
    );
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.surface,
          _controller.value,
        )!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 188,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _bar(color, 18)),
                    ],
                  ),
                  const Spacer(),
                  _bar(color, 22, width: 160),
                  const SizedBox(height: 10),
                  _bar(color, 16, width: 96),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bar(Color color, double height, {double? width}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
