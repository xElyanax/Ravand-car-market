import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';
import 'car_detail_page.dart';
import 'widgets/common_widgets.dart';
import 'widgets/trend_chart.dart';

class ComparePage extends StatelessWidget {
  const ComparePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.compareCars;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageGutter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مقایسه هوشمند',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'دو خودرو را با معیارهای هم‌سطح ببین',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (selected.isNotEmpty)
                        IconButton.filledTonal(
                          tooltip: 'پاک کردن مقایسه',
                          onPressed: controller.clearCompare,
                          icon: const Icon(Icons.delete_sweep_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CompareSlot(
                          index: 0,
                          car: selected.firstOrNull,
                          color: AppColors.primary,
                          onSelect: () => _selectCar(context, 0),
                          onOpen: selected.firstOrNull == null
                              ? null
                              : () => _openDetail(context, selected.first),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 35,
                        ),
                        child: Text('در برابر', style: TextStyle(fontSize: 11)),
                      ),
                      Expanded(
                        child: _CompareSlot(
                          index: 1,
                          car: selected.length > 1 ? selected[1] : null,
                          color: AppColors.secondary,
                          onSelect: () => _selectCar(context, 1),
                          onOpen: selected.length > 1
                              ? () => _openDetail(context, selected[1])
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (selected.length < 2)
                    EmptyPanel(
                      icon: Icons.compare_arrows_rounded,
                      title: selected.isEmpty
                          ? 'اولین خودرو را انتخاب کن'
                          : 'یک خودرو دیگر لازم است',
                      message: selected.isEmpty
                          ? 'با انتخاب دو خودرو، اختلاف قیمت، بازده و مشخصات آن‌ها کنار هم نمایش داده می‌شود.'
                          : 'خودروی دوم را اضافه کن تا مقایسه کامل شود.',
                      actionLabel: selected.isEmpty
                          ? 'انتخاب خودرو'
                          : 'انتخاب خودروی دوم',
                      onAction: () =>
                          _selectCar(context, selected.isEmpty ? 0 : 1),
                    )
                  else
                    _ComparisonBody(
                      controller: controller,
                      first: selected[0],
                      second: selected[1],
                    ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCar(BuildContext context, int index) async {
    final car = await showModalBottomSheet<CarModel>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _CarPicker(
        cars: controller.cars,
        excludedIds: controller.compareCars.map((car) => car.id).toSet(),
      ),
    );
    if (car != null) controller.replaceCompare(index, car);
  }

  void _openDetail(BuildContext context, CarModel car) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CarDetailPage(controller: controller, car: car),
      ),
    );
  }
}

class _CompareSlot extends StatelessWidget {
  const _CompareSlot({
    required this.index,
    required this.car,
    required this.color,
    required this.onSelect,
    required this.onOpen,
  });

  final int index;
  final CarModel? car;
  final Color color;
  final VoidCallback onSelect;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final item = car;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item == null ? onSelect : onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 144,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: item == null
                ? color.withValues(alpha: 0.06)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item == null
                  ? color.withValues(alpha: 0.38)
                  : Theme.of(context).colorScheme.outlineVariant,
              style: item == null ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: item == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: color,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'خودروی ${toPersianDigits(index + 1)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'برای انتخاب بزن',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CarAvatar(car: item, size: 42),
                        const Spacer(),
                        IconButton(
                          tooltip: 'تعویض خودرو',
                          visualDensity: VisualDensity.compact,
                          onPressed: onSelect,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatCompactToman(item.price),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({
    required this.controller,
    required this.first,
    required this.second,
  });

  final AppController controller;
  final CarModel first;
  final CarModel second;

  @override
  Widget build(BuildContext context) {
    final firstReturn = controller.returnFor(first);
    final secondReturn = controller.returnFor(second);
    final priceDiff = (first.price - second.price).abs();
    final better = firstReturn >= secondReturn ? first : second;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: MarketColors.of(context).heroGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DarkMetric(
                  label: 'اختلاف قیمت امروز',
                  value: formatCompactToman(priceDiff),
                ),
              ),
              Container(width: 1, height: 46, color: Colors.white24),
              const SizedBox(width: 14),
              Expanded(
                child: _DarkMetric(
                  label: 'بازده بهتر در بازه',
                  value: better.displayName,
                  small: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(
          title: 'مسیر تغییر قیمت',
          subtitle: 'هر دو خط از نقطه شروع به ۱۰۰ نرمال شده‌اند',
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    _Legend(color: AppColors.primary, label: first.displayName),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Legend(
                        color: AppColors.secondary,
                        label: second.displayName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridTrendChart(
                    primaryValues: _normalized(first, firstReturn),
                    primaryColor: AppColors.primary,
                    secondaryValues: _normalized(second, secondReturn),
                    secondaryColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'مقایسه جزئیات'),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _ComparisonRow(
                label: 'قیمت امروز',
                first: formatCompactToman(first.price),
                second: formatCompactToman(second.price),
              ),
              _ComparisonRow(
                label: 'بازده بازه',
                first: formatPercent(firstReturn),
                second: formatPercent(secondReturn),
              ),
              _ComparisonRow(
                label: 'سال تولید',
                first: toPersianDigits(first.year),
                second: toPersianDigits(second.year),
              ),
              _ComparisonRow(
                label: 'نوع قیمت',
                first: first.marketPrice ? 'بازار' : 'کارخانه',
                second: second.marketPrice ? 'بازار' : 'کارخانه',
              ),
              _ComparisonRow(
                label: 'آخرین بروزرسانی',
                first: first.lastUpdate,
                second: second.lastUpdate,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _normalized(CarModel car, double fallbackChange) {
    if (car.history.length >= 2) {
      final base = car.history.first.price.toDouble();
      if (base > 0) {
        return car.history.map((point) => point.price * 100 / base).toList();
      }
    }
    return [
      100,
      100 + fallbackChange * .2,
      100 + fallbackChange * .55,
      100 + fallbackChange,
    ];
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({
    required this.label,
    required this.value,
    this.small = false,
  });

  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        maxLines: small ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ],
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ],
  );
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.first,
    required this.second,
    this.isLast = false,
  });

  final String label;
  final String first;
  final String second;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  first.isEmpty ? '—' : first,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  second.isEmpty ? '—' : second,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _CarPicker extends StatefulWidget {
  const _CarPicker({required this.cars, required this.excludedIds});

  final List<CarModel> cars;
  final Set<int> excludedIds;

  @override
  State<_CarPicker> createState() => _CarPickerState();
}

class _CarPickerState extends State<_CarPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final cars = widget.cars.where((car) {
      if (widget.excludedIds.contains(car.id)) return false;
      return query.isEmpty ||
          car.displayName.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('انتخاب خودرو', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                hintText: 'نام خودرو را جست‌وجو کن…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: cars.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final car = cars[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CarAvatar(car: car, size: 44),
                    title: Text(car.displayName),
                    subtitle: Text(
                      '${formatCompactToman(car.price)} • مدل ${toPersianDigits(car.year)}',
                    ),
                    trailing: ChangePill(
                      value: car.changePercent,
                      compact: true,
                    ),
                    onTap: () => Navigator.pop(context, car),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
