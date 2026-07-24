import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';
import 'widgets/common_widgets.dart';
import 'widgets/trend_chart.dart';

class CarDetailPage extends StatefulWidget {
  const CarDetailPage({super.key, required this.controller, required this.car});

  final AppController controller;
  final CarModel car;

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final car =
        widget.controller.cars
            .where((item) => item.id == widget.car.id)
            .firstOrNull ??
        widget.car;
    final points = _visiblePoints(car);
    final prices = points.map((point) => point.price.toDouble()).toList();
    final firstPrice = points.isEmpty ? car.price : points.first.price;
    final lastPrice = points.isEmpty ? car.price : points.last.price;
    final periodReturn = firstPrice <= 0
        ? 0.0
        : (lastPrice - firstPrice) * 100 / firstPrice;
    final minPrice = points.isEmpty
        ? car.price
        : points.map((point) => point.price).reduce(math.min);
    final maxPrice = points.isEmpty
        ? car.price
        : points.map((point) => point.price).reduce(math.max);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات خودرو'),
        actions: [
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => IconButton(
              tooltip: widget.controller.isFavorite(car)
                  ? 'حذف نشان'
                  : 'نشان کردن',
              onPressed: () => widget.controller.toggleFavorite(car),
              icon: Icon(
                widget.controller.isFavorite(car)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 12),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final selected = widget.controller.isCompared(car);
              return FilledButton.icon(
                onPressed: () {
                  widget.controller.toggleCompare(car);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        selected ? 'از مقایسه حذف شد.' : 'به مقایسه اضافه شد.',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  selected ? Icons.check_rounded : Icons.compare_arrows_rounded,
                ),
                label: Text(
                  selected ? 'در لیست مقایسه است' : 'افزودن به مقایسه',
                ),
              );
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 28),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PriceHero(car: car),
                const SizedBox(height: 26),
                const SectionHeading(
                  title: 'روند قیمت',
                  subtitle: 'از قدیمی در چپ تا جدید در راست',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final entry in const {
                        1: '۱ ماه',
                        3: '۳ ماه',
                        6: '۶ ماه',
                        12: '۱ سال',
                      }.entries)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            selected: _months == entry.key,
                            label: Text(entry.value),
                            onSelected: (_) =>
                                setState(() => _months = entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تغییر بازه',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                ChangePill(value: periodReturn),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'آخرین قیمت',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatCompactToman(lastPrice),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: GridTrendChart(
                            primaryValues: prices.isEmpty
                                ? [car.price.toDouble()]
                                : prices,
                            primaryColor: periodReturn >= 0
                                ? AppColors.positive
                                : AppColors.negative,
                            height: 205,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              points.isEmpty
                                  ? 'ابتدای بازه'
                                  : toPersianDigits(points.first.date),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              points.isEmpty
                                  ? 'امروز'
                                  : toPersianDigits(points.last.date),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'کمینه بازه',
                        value: formatCompactToman(minPrice),
                        icon: Icons.south_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'بیشینه بازه',
                        value: formatCompactToman(maxPrice),
                        icon: Icons.north_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const SectionHeading(title: 'مشخصات و منبع قیمت'),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'برند / نوع',
                          value: car.brand.isEmpty
                              ? car.displayName
                              : car.brand,
                        ),
                        _InfoRow(
                          label: 'مدل',
                          value: car.model.isEmpty ? '—' : car.model,
                        ),
                        _InfoRow(
                          label: 'تیپ',
                          value: car.trim.isEmpty ? '—' : car.trim,
                        ),
                        _InfoRow(
                          label: 'سال تولید',
                          value: car.year > 0 ? toPersianDigits(car.year) : '—',
                        ),
                        _InfoRow(
                          label: 'منبع قیمت',
                          value: car.marketPrice
                              ? 'قیمت بازار'
                              : 'قیمت کارخانه',
                        ),
                        _InfoRow(
                          label: 'آخرین بروزرسانی',
                          value: car.lastUpdate.isEmpty
                              ? 'نامشخص'
                              : car.lastUpdate,
                          isLast: car.description.isEmpty,
                        ),
                        if (car.description.isNotEmpty)
                          _InfoRow(
                            label: 'توضیحات',
                            value: car.description,
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'قیمت‌ها صرفاً برای درک روند بازار هستند و پیشنهاد خرید یا سرمایه‌گذاری محسوب نمی‌شوند.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<CarPricePoint> _visiblePoints(CarModel car) {
    if (car.history.isNotEmpty) {
      final take = math.min(_months + 1, car.history.length);
      return car.history.sublist(car.history.length - take);
    }
    final change = widget.controller.returnFor(car);
    if (change == 0 || car.price <= 0) return const [];
    final oldPrice = (car.price / (1 + change / 100)).round();
    return [
      CarPricePoint(
        date: widget.controller.periodDate ?? 'ابتدای بازه',
        price: oldPrice,
      ),
      CarPricePoint(date: 'امروز', price: car.price),
    ];
  }
}

class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.car});

  final CarModel car;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: MarketColors.of(context).heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -48,
            end: -34,
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 142,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CarAvatar(car: car, size: 58),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.displayName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مدل ${toPersianDigits(car.year)} • ${car.marketPrice ? 'بازار' : 'کارخانه'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'قیمت امروز',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 4),
              Text(
                car.price > 0 ? formatToman(car.price) : 'قیمت ناموجود',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 11),
              ChangePill(value: car.changePercent),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 9),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      if (!isLast) const Divider(height: 1),
    ],
  );
}
