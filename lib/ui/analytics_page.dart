import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';
import 'car_detail_page.dart';
import 'tools_pages.dart';
import 'widgets/common_widgets.dart';
import 'widgets/trend_chart.dart';

enum _RankingMode { rising, falling, stable }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  _RankingMode _mode = _RankingMode.rising;

  static const _periods = {
    7: '۷ روز',
    30: '۱ ماه',
    90: '۳ ماه',
    180: '۶ ماه',
    365: '۱ سال',
  };

  @override
  Widget build(BuildContext context) {
    final ranked = _rankedCars();
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => widget.controller.loadPeriod(
          widget.controller.selectedPeriodDays,
          forceRefresh: true,
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageGutter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      'تحلیل بازار',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ببین در هر بازه کدام خودروها جلو یا عقب افتاده‌اند',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final entry in _periods.entries)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                label: Text(entry.value),
                                selected:
                                    widget.controller.selectedPeriodDays ==
                                    entry.key,
                                onSelected: (_) =>
                                    widget.controller.loadPeriod(entry.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AnalysisSummary(controller: widget.controller),
                    const SizedBox(height: 26),
                    const SectionHeading(
                      title: 'ابزارهای شخصی',
                      subtitle: 'تحلیل را با شرایط خودت ترکیب کن',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 128,
                      child: Row(
                        children: [
                          Expanded(
                            child: _MiniTool(
                              title: 'پیشنهاد با بودجه',
                              icon: Icons.wallet_rounded,
                              color: AppColors.primary,
                              onTap: () => _open(
                                BudgetPage(controller: widget.controller),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniTool(
                              title: 'اگر خریده بودم',
                              icon: Icons.ssid_chart_rounded,
                              color: AppColors.secondary,
                              onTap: () => _open(
                                InvestmentPage(controller: widget.controller),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionHeading(
                      title: 'رتبه‌بندی بازده',
                      subtitle: 'مقایسه قیمت ابتدای بازه با قیمت امروز',
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_RankingMode>(
                      segments: const [
                        ButtonSegment(
                          value: _RankingMode.rising,
                          label: Text('بیشترین رشد'),
                          icon: Icon(Icons.trending_up_rounded),
                        ),
                        ButtonSegment(
                          value: _RankingMode.falling,
                          label: Text('بیشترین افت'),
                          icon: Icon(Icons.trending_down_rounded),
                        ),
                        ButtonSegment(
                          value: _RankingMode.stable,
                          label: Text('کم‌نوسان'),
                          icon: Icon(Icons.horizontal_rule_rounded),
                        ),
                      ],
                      showSelectedIcon: false,
                      selected: {_mode},
                      onSelectionChanged: (value) =>
                          setState(() => _mode = value.first),
                    ),
                    const SizedBox(height: 14),
                    if (widget.controller.isPeriodLoading)
                      const _RankingLoading()
                    else if (ranked.isEmpty)
                      const EmptyPanel(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'داده‌ی کافی نیست',
                        message:
                            'برای این بازه هنوز قیمت تاریخی مشترکی پیدا نشد.',
                      )
                    else
                      for (var index = 0; index < ranked.length; index++)
                        _RankCard(
                          rank: index + 1,
                          car: ranked[index],
                          change: widget.controller.returnFor(ranked[index]),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CarDetailPage(
                                controller: widget.controller,
                                car: ranked[index],
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CarModel> _rankedCars() {
    final cars = [...widget.controller.cars];
    cars.sort((a, b) {
      final av = widget.controller.returnFor(a);
      final bv = widget.controller.returnFor(b);
      return switch (_mode) {
        _RankingMode.rising => bv.compareTo(av),
        _RankingMode.falling => av.compareTo(bv),
        _RankingMode.stable => av.abs().compareTo(bv.abs()),
      };
    });
    return cars.take(math.min(8, cars.length)).toList();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AnalysisSummary extends StatelessWidget {
  const _AnalysisSummary({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final valid = controller.cars.where(
      (car) => controller.periodReturns.containsKey(car.id),
    );
    final values = valid.map(controller.returnFor).toList();
    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    final positive = average >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (positive ? AppColors.positive : AppColors.negative)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: positive ? AppColors.positive : AppColors.negative,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isPeriodLoading
                      ? 'در حال محاسبه…'
                      : 'میانگین بازده خودروهای قابل مقایسه',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.isPeriodLoading ? '—' : formatPercent(average),
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                controller.periodDate == null
                    ? '—'
                    : toPersianDigits(controller.periodDate),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                'ابتدای بازه',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTool extends StatelessWidget {
  const _MiniTool({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'شروع تحلیل',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_back_rounded, size: 15),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.rank,
    required this.car,
    required this.change,
    required this.onTap,
  });

  final int rank;
  final CarModel car;
  final double change;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = change >= 0 ? AppColors.positive : AppColors.negative;
    final values = car.history.isEmpty
        ? [
            100.0,
            100 + change * .2,
            100 + change * .45,
            100 + change * .7,
            100 + change,
          ]
        : car.history.map((point) => point.price.toDouble()).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  toPersianDigits(rank),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCompactToman(car.price),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 66,
                child: TrendChart(
                  values: values,
                  color: color,
                  height: 38,
                  showArea: false,
                  showEndDot: false,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 10),
              ChangePill(value: change, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingLoading extends StatelessWidget {
  const _RankingLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
