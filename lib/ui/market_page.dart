import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';
import 'car_detail_page.dart';
import 'widgets/common_widgets.dart';

enum _MarketFilter { all, market, factory, favorites }

enum _MarketSort { changeDesc, changeAsc, priceAsc, priceDesc, newest }

class MarketPage extends StatefulWidget {
  const MarketPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _searchController = TextEditingController();
  _MarketFilter _filter = _MarketFilter.all;
  _MarketSort _sort = _MarketSort.changeDesc;
  String? _brand;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cars = _filteredCars();
    if (widget.controller.isLoading && widget.controller.cars.isEmpty) {
      return const SafeArea(child: LoadingList());
    }
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: widget.controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بازار خودرو',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${toPersianDigits(cars.length)} نتیجه از ${toPersianDigits(widget.controller.cars.length)} خودرو',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'مرتب‌سازی',
                      onPressed: _showSortSheet,
                      icon: const Icon(Icons.swap_vert_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(
                minHeight: 116,
                maxHeight: 116,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'جست‌وجوی برند، مدل یا سال…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'پاک کردن',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _filterChip('همه', _MarketFilter.all),
                              _filterChip('بازار', _MarketFilter.market),
                              _filterChip('کارخانه', _MarketFilter.factory),
                              _filterChip(
                                'نشان‌شده‌ها',
                                _MarketFilter.favorites,
                              ),
                              const SizedBox(width: 7),
                              FilterChip(
                                selected: _brand != null,
                                avatar: const Icon(
                                  Icons.tune_rounded,
                                  size: 17,
                                ),
                                label: Text(_brand ?? 'برند'),
                                onSelected: (_) => _showBrandSheet(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (cars.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyPanel(
                  icon: Icons.search_off_rounded,
                  title: 'خودرویی پیدا نشد',
                  message:
                      'عبارت جست‌وجو یا فیلترها را تغییر بده تا نتایج بیشتری ببینی.',
                  actionLabel: 'پاک کردن فیلترها',
                  onAction: _resetFilters,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 120),
                sliver: SliverList.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    return CarCard(
                      car: car,
                      isFavorite: widget.controller.isFavorite(car),
                      isCompared: widget.controller.isCompared(car),
                      onFavorite: () => widget.controller.toggleFavorite(car),
                      onCompare: () => widget.controller.toggleCompare(car),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CarDetailPage(
                            controller: widget.controller,
                            car: car,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _MarketFilter value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 7),
      child: FilterChip(
        selected: _filter == value,
        label: Text(label),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  List<CarModel> _filteredCars() {
    final query = toEnglishDigits(_searchController.text).trim().toLowerCase();
    final cars = widget.controller.cars.where((car) {
      final haystack = toEnglishDigits(
        '${car.displayName} ${car.brand} ${car.model} ${car.trim} ${car.year} ${car.description}',
      ).toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      if (_brand != null && car.brand != _brand) return false;
      return switch (_filter) {
        _MarketFilter.all => true,
        _MarketFilter.market => car.marketPrice,
        _MarketFilter.factory => !car.marketPrice,
        _MarketFilter.favorites => widget.controller.isFavorite(car),
      };
    }).toList();
    cars.sort(
      (a, b) => switch (_sort) {
        _MarketSort.changeDesc => b.changePercent.compareTo(a.changePercent),
        _MarketSort.changeAsc => a.changePercent.compareTo(b.changePercent),
        _MarketSort.priceAsc => a.price.compareTo(b.price),
        _MarketSort.priceDesc => b.price.compareTo(a.price),
        _MarketSort.newest => b.year.compareTo(a.year),
      },
    );
    return cars;
  }

  Future<void> _showSortSheet() async {
    final value = await showModalBottomSheet<_MarketSort>(
      context: context,
      useSafeArea: true,
      builder: (context) => _ChoiceSheet<_MarketSort>(
        title: 'مرتب‌سازی خودروها',
        selected: _sort,
        choices: const {
          _MarketSort.changeDesc: 'بیشترین رشد',
          _MarketSort.changeAsc: 'بیشترین افت',
          _MarketSort.priceAsc: 'ارزان‌ترین',
          _MarketSort.priceDesc: 'گران‌ترین',
          _MarketSort.newest: 'جدیدترین مدل',
        },
      ),
    );
    if (value != null) setState(() => _sort = value);
  }

  Future<void> _showBrandSheet() async {
    final brands =
        widget.controller.cars
            .map((car) => car.brand)
            .where((brand) => brand.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final value = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('فیلتر برند', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('همه برندها'),
                        selected: _brand == null,
                        onSelected: (_) => Navigator.pop(context, '__all__'),
                      ),
                      for (final brand in brands)
                        ChoiceChip(
                          label: Text(brand),
                          selected: _brand == brand,
                          onSelected: (_) => Navigator.pop(context, brand),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (value != null) {
      setState(() => _brand = value == '__all__' ? null : value);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _filter = _MarketFilter.all;
      _brand = null;
    });
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SearchHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.minHeight != minHeight ||
      oldDelegate.maxHeight != maxHeight;
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.selected,
    required this.choices,
  });

  final String title;
  final T selected;
  final Map<T, String> choices;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 18, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            for (final choice in choices.entries)
              ListTile(
                title: Text(choice.value),
                leading: Icon(
                  choice.key == selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: choice.key == selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => Navigator.pop(context, choice.key),
              ),
          ],
        ),
      ),
    );
  }
}
