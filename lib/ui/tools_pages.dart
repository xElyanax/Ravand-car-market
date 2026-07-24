import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';
import 'car_detail_page.dart';
import 'widgets/common_widgets.dart';
import 'widgets/trend_chart.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late int _budget = widget.controller.medianPrice > 0
      ? widget.controller.medianPrice
      : 1000000000;
  late final TextEditingController _budgetController = TextEditingController(
    text: toPersianDigits(_budget),
  );
  double _tolerance = 0.05;
  String? _brand;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prices = widget.controller.cars
        .where((car) => car.price > 0)
        .map((car) => car.price);
    final minPrice = prices.isEmpty ? 100000000 : prices.reduce(math.min);
    final maxPrice = prices.isEmpty ? 10000000000 : prices.reduce(math.max);
    final safeBudget = _budget.clamp(minPrice, maxPrice);
    final results = widget.controller
        .budgetMatches(_budget, tolerance: _tolerance)
        .where((car) => _brand == null || car.brand == _brand)
        .take(12)
        .toList();
    final brands =
        widget.controller.cars
            .map((car) => car.brand)
            .where((brand) => brand.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('پیشنهاد با بودجه')),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 36),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'بودجه خرید من',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9۰-۹٠-٩٬,]'),
                          ),
                        ],
                        onChanged: (value) {
                          final parsed = parseFlexibleInt(value);
                          if (parsed != null && parsed > 0) {
                            setState(() => _budget = parsed);
                          }
                        },
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: InputDecoration(
                          labelText: 'مبلغ به تومان',
                          suffixText: 'تومان',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.edit_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Slider(
                          value: safeBudget.toDouble(),
                          min: minPrice.toDouble(),
                          max: math.max(minPrice + 1, maxPrice).toDouble(),
                          divisions: 100,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            final rounded =
                                (value / 10000000).round() * 10000000;
                            setState(() {
                              _budget = rounded;
                              _budgetController.text = toPersianDigits(rounded);
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatCompactToman(minPrice),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            formatCompactToman(maxPrice),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'کمی انعطاف در بودجه',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('دقیق')),
                    ButtonSegment(value: .05, label: Text('تا ۵٪ بیشتر')),
                    ButtonSegment(value: .1, label: Text('تا ۱۰٪ بیشتر')),
                  ],
                  selected: {_tolerance},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _tolerance = value.first),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  key: ValueKey(_brand),
                  initialValue: _brand,
                  decoration: const InputDecoration(
                    labelText: 'برند دلخواه (اختیاری)',
                    prefixIcon: Icon(Icons.factory_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('همه برندها'),
                    ),
                    ...brands.map(
                      (brand) => DropdownMenuItem<String?>(
                        value: brand,
                        child: Text(brand),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _brand = value),
                ),
                const SizedBox(height: 28),
                SectionHeading(
                  title: 'انتخاب‌های نزدیک بودجه',
                  subtitle: results.isEmpty
                      ? 'نتیجه‌ای با این شرایط نیست'
                      : '${toPersianDigits(results.length)} پیشنهاد مرتب‌شده بر اساس فاصله تا بودجه',
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const EmptyPanel(
                    icon: Icons.no_crash_outlined,
                    title: 'پیشنهادی پیدا نشد',
                    message: 'بودجه، انعطاف یا فیلتر برند را تغییر بده.',
                  )
                else
                  for (final car in results)
                    _BudgetResultCard(
                      car: car,
                      budget: _budget,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CarDetailPage(
                            controller: widget.controller,
                            car: car,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
                Text(
                  'این نتایج بر اساس قیمت و فیلترهای انتخابی مرتب شده‌اند و توصیه مالی یا تضمین بازده نیستند.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
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

class _BudgetResultCard extends StatelessWidget {
  const _BudgetResultCard({
    required this.car,
    required this.budget,
    required this.onTap,
  });

  final CarModel car;
  final int budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difference = budget - car.price;
    final ratio = budget == 0 ? 0.0 : difference * 100 / budget;
    final inside = difference >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CarAvatar(car: car, size: 48),
              const SizedBox(width: 12),
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      inside
                          ? '${formatPercent(ratio.abs(), showPlus: false)} زیر بودجه'
                          : '${formatPercent(ratio.abs(), showPlus: false)} بالاتر از بودجه',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: inside ? AppColors.positive : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              ChangePill(value: car.changePercent, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class InvestmentPage extends StatefulWidget {
  const InvestmentPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  CarModel? _selected;
  int _days = 180;
  InvestmentResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.cars.firstOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(title: const Text('اگر خریده بودم…')),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 36),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'یک سناریوی فرضی بساز',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'قیمت خودرو در ابتدای بازه را با قیمت امروز مقایسه می‌کنیم.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<CarModel>(
                  key: ValueKey(selected?.id),
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'خودرو',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                  ),
                  items: widget.controller.cars
                      .map(
                        (car) => DropdownMenuItem(
                          value: car,
                          child: Text(
                            car.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (car) {
                    setState(() => _selected = car);
                    _calculate();
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'زمان خرید فرضی',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 30, label: Text('۱ ماه')),
                    ButtonSegment(value: 90, label: Text('۳ ماه')),
                    ButtonSegment(value: 180, label: Text('۶ ماه')),
                    ButtonSegment(value: 365, label: Text('۱ سال')),
                  ],
                  selected: {_days},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) {
                    setState(() => _days = value.first);
                    _calculate();
                  },
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_result?.available == true)
                  _InvestmentResultCard(result: _result!, car: selected!)
                else
                  const EmptyPanel(
                    icon: Icons.event_busy_rounded,
                    title: 'قیمت تاریخی پیدا نشد',
                    message:
                        'ممکن است این مدل در تاریخ انتخابی داده‌ی ثبت‌شده نداشته باشد. بازه دیگری را امتحان کن.',
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(15),
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
                          'این محاسبه هزینه انتقال، نگهداری، بیمه، تورم و نقدشوندگی را لحاظ نمی‌کند؛ فقط اختلاف قیمت ثبت‌شده را نشان می‌دهد.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.65),
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

  Future<void> _calculate() async {
    final car = _selected;
    if (car == null) return;
    setState(() => _loading = true);
    final result = await widget.controller.calculateInvestment(car, _days);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }
}

class _InvestmentResultCard extends StatelessWidget {
  const _InvestmentResultCard({required this.result, required this.car});

  final InvestmentResult result;
  final CarModel car;

  @override
  Widget build(BuildContext context) {
    final positive = result.profit >= 0;
    final color = positive ? AppColors.positive : AppColors.negative;
    final values = car.history.length >= 2
        ? car.history.map((point) => point.price.toDouble()).toList()
        : [result.previousPrice.toDouble(), result.currentPrice.toDouble()];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: positive
                  ? const [Color(0xFF0F7E67), Color(0xFF19AA84)]
                  : const [Color(0xFF9F3445), Color(0xFFE05365)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                positive ? 'سود فرضی تا امروز' : 'زیان فرضی تا امروز',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                '${positive ? '+' : ''}${formatToman(result.profit)}',
                textDirection: TextDirection.ltr,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  formatPercent(result.profitPercent),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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
                    Expanded(
                      child: _ValueAtDate(
                        label:
                            'قیمت در ${toPersianDigits(result.requestedDate)}',
                        value: result.previousPrice,
                      ),
                    ),
                    const Icon(Icons.arrow_back_rounded),
                    Expanded(
                      child: _ValueAtDate(
                        label: 'قیمت امروز',
                        value: result.currentPrice,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridTrendChart(
                    primaryValues: values,
                    primaryColor: color,
                    height: 170,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueAtDate extends StatelessWidget {
  const _ValueAtDate({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final int value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        formatCompactToman(value),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ],
  );
}
