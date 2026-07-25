import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';
import 'car_detail_page.dart';
import 'tools_pages.dart';
import 'widgets/brand_mark.dart';
import 'widgets/common_widgets.dart';
import 'widgets/trend_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onApiSettings,
  });

  final AppController controller;
  final VoidCallback onApiSettings;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.cars.isEmpty) {
      return const SafeArea(child: LoadingList());
    }
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageGutter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _HomeHeader(
                      controller: controller,
                      onApiSettings: onApiSettings,
                    ),
                    const SizedBox(height: 22),
                    _MarketPulseCard(controller: controller),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _DataNotice(controller: controller),
                    ],
                    const SizedBox(height: 26),
                    const SectionHeading(
                      title: 'ابزارهای تصمیم‌گیری',
                      subtitle: 'بودجه و بازده فرضی را سریع بررسی کن',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 164,
                      child: Row(
                        children: [
                          Expanded(
                            child: ToolCard(
                              title: 'با بودجه‌ام چی بخرم؟',
                              subtitle: 'انتخاب‌های نزدیک به بودجه',
                              icon: Icons.account_balance_wallet_rounded,
                              colors: const [
                                Color(0xFF3158FF),
                                Color(0xFF6F7EFF),
                              ],
                              onTap: () => _open(
                                context,
                                BudgetPage(controller: controller),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ToolCard(
                              title: 'اگر خریده بودم…',
                              subtitle: 'سود یا زیان فرضی امروز',
                              icon: Icons.query_stats_rounded,
                              colors: const [
                                Color(0xFF0E8D82),
                                Color(0xFF24B6A5),
                              ],
                              onTap: () => _open(
                                context,
                                InvestmentPage(controller: controller),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SectionHeading(
                      title: 'حرکت‌های مهم امروز',
                      subtitle: 'بیشترین تغییر ثبت‌شده بین خودروها',
                      actionLabel: 'همه بازار',
                      onAction: () => controller.setTab(1),
                    ),
                    const SizedBox(height: 12),
                    _MoversRow(controller: controller),
                    const SizedBox(height: 28),
                    SectionHeading(
                      title: controller.favoriteCars.isEmpty
                          ? 'پیشنهاد برای شروع'
                          : 'نشان‌شده‌های من',
                      subtitle: controller.favoriteCars.isEmpty
                          ? 'چند خودروی پرتغییر بازار'
                          : '${toPersianDigits(controller.favoriteCars.length)} خودرو برای پیگیری',
                      actionLabel: 'بازار',
                      onAction: () => controller.setTab(1),
                    ),
                    const SizedBox(height: 12),
                    ..._previewCars(controller).map(
                      (car) => CarCard(
                        car: car,
                        isFavorite: controller.isFavorite(car),
                        isCompared: controller.isCompared(car),
                        onFavorite: () => controller.toggleFavorite(car),
                        onCompare: () => controller.toggleCompare(car),
                        onTap: () => _open(
                          context,
                          CarDetailPage(controller: controller, car: car),
                        ),
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CarModel> _previewCars(AppController controller) {
    final favorites = controller.favoriteCars;
    return favorites.isNotEmpty
        ? favorites.take(3).toList()
        : controller.topMovers(rising: true, limit: 3);
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller, required this.onApiSettings});

  final AppController controller;
  final VoidCallback onApiSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: BrandMark.lockup(size: 40, showTagline: true)),
        SourcePill(source: controller.source, onTap: onApiSettings),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'تازه‌سازی',
          onPressed: controller.isRefreshing ? null : controller.refresh,
          icon: controller.isRefreshing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _MarketPulseCard extends StatelessWidget {
  const _MarketPulseCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final marketColors = MarketColors.of(context);
    final positive = controller.medianChange >= 0;
    final values = controller.cars
        .take(10)
        .map((car) => 100 + car.changePercent * 2)
        .toList();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: marketColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.cardValue + 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -80,
            start: -45,
            child: _GlowOrb(size: 190, color: Color(0x337B96FF)),
          ),
          PositionedDirectional(
            bottom: -100,
            end: -60,
            child: _GlowOrb(
              size: 210,
              color: AppColors.secondary.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'نبض امروز بازار',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${toPersianDigits(controller.cars.length)} خودرو',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  formatPercent(controller.medianChange),
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  positive
                      ? 'میانه تغییر قیمت‌ها مثبت است'
                      : 'میانه تغییر قیمت‌ها منفی است',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                TrendChart(
                  values: values.isEmpty ? const [1, 1] : values,
                  color: positive
                      ? const Color(0xFF62E6C8)
                      : const Color(0xFFFF8B9A),
                  height: 72,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PulseMetric(
                        icon: Icons.north_east_rounded,
                        label: 'صعودی',
                        value: controller.risingCount,
                        color: const Color(0xFF62E6C8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PulseMetric(
                        icon: Icons.south_east_rounded,
                        label: 'نزولی',
                        value: controller.fallingCount,
                        color: const Color(0xFFFF8B9A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PulseMetric(
                        icon: Icons.horizontal_rule_rounded,
                        label: 'ثابت',
                        value: controller.stableCount,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 4),
              Text(
                toPersianDigits(value),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MoversRow extends StatelessWidget {
  const _MoversRow({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final gain = controller.topMovers(rising: true, limit: 1).firstOrNull;
    final loss = controller.topMovers(rising: false, limit: 1).firstOrNull;
    return Row(
      children: [
        Expanded(
          child: _MoverCard(
            label: 'بیشترین رشد',
            car: gain,
            color: AppColors.positive,
            icon: Icons.trending_up_rounded,
            onTap: gain == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CarDetailPage(controller: controller, car: gain),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MoverCard(
            label: 'بیشترین افت',
            car: loss,
            color: AppColors.negative,
            icon: Icons.trending_down_rounded,
            onTap: loss == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CarDetailPage(controller: controller, car: loss),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({
    required this.label,
    required this.car,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final CarModel? car;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 19),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                car?.displayName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 7),
              ChangePill(value: car?.changePercent ?? 0, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataNotice extends StatelessWidget {
  const _DataNotice({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              controller.errorMessage ??
                  'دریافت تازه انجام نشد؛ داده جایگزین نمایش داده می‌شود.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
