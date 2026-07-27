import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'analytics_page.dart';
import 'api_setup_sheet.dart';
import 'compare_page.dart';
import 'home_page.dart';
import 'market_page.dart';
import 'investment_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard_rounded),
      label: 'خانه',
    ),
    NavigationDestination(
      icon: Icon(Icons.directions_car_outlined),
      selectedIcon: Icon(Icons.directions_car_rounded),
      label: 'بازار',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: 'تحلیل',
    ),
    NavigationDestination(
  icon: Icon(Icons.account_balance_wallet_outlined),
  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
  label: 'سرمایه‌گذاری',
),

    NavigationDestination(
      icon: Icon(Icons.compare_arrows_outlined),
      selectedIcon: Icon(Icons.compare_arrows_rounded),
      label: 'مقایسه',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final List<Widget> pages = [
          HomePage(
            controller: controller,
            onApiSettings: () => _showApi(context),
          ),
          MarketPage(controller: controller),
          AnalyticsPage(controller: controller),
          InvestmentPage(controller: controller),
          ComparePage(controller: controller),
        ];
        final isWide = MediaQuery.sizeOf(context).width >= 900;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: controller.tabIndex,
                    onDestinationSelected: controller.setTab,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.72,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: IconButton.filledTonal(
                        tooltip: 'تنظیم اتصال داده',
                        onPressed: () => _showApi(context),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.space_dashboard_outlined),
                        selectedIcon: Icon(Icons.space_dashboard_rounded),
                        label: Text('خانه'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.directions_car_outlined),
                        selectedIcon: Icon(Icons.directions_car_rounded),
                        label: Text('بازار'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.insights_outlined),
                        selectedIcon: Icon(Icons.insights_rounded),
                        label: Text('تحلیل'),
                      ),
                      NavigationRailDestination(
  icon: Icon(Icons.account_balance_wallet_outlined),
  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
  label: Text('سرمایه‌گذاری'),
),

                      NavigationRailDestination(
                        icon: Icon(Icons.compare_arrows_outlined),
                        selectedIcon: Icon(Icons.compare_arrows_rounded),
                        label: Text('مقایسه'),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: controller.tabIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        final comparisonCount = controller.compareCars.length;
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: controller.tabIndex, children: pages),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: controller.tabIndex,
              onDestinationSelected: controller.setTab,
              destinations: _destinations,
            ),
            
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: comparisonCount > 0 && controller.tabIndex != 4
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 72),
                  child: FloatingActionButton.extended(
                    heroTag: 'compare-selection',
                    onPressed: () => controller.setTab(4),
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: Text(
                      comparisonCount == 1
                          ? 'یک خودرو انتخاب شد؛ یکی دیگر اضافه کن'
                          : 'مشاهده مقایسه',
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showApi(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ApiSetupSheet(controller: controller),
    );
  }
}
