import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_repository.dart';
import 'package:ravand/state/app_controller.dart';
import 'package:ravand/ui/market_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppController> createController() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final client = MockClient((request) async {
      final cars = [
        {
          'cid': 1,
          'name': 'ری‌را اتوماتیک',
          'brand': 'ایران خودرو',
          'model': 'ری‌را',
          'trim_fa': 'اتوماتیک',
          'year': 1404,
          'price': 1800000000,
          'change_percent': 2.1,
          'market_price': true,
          'unique_id': 'rira-market',
        },
        {
          'cid': 2,
          'name': 'دنا پلاس',
          'brand': 'ایران خودرو',
          'model': 'دنا پلاس',
          'trim_fa': 'توربو',
          'year': 1403,
          'price': 1200000000,
          'change_percent': -1.2,
          'market_price': false,
          'unique_id': 'dena-factory',
        },
        {
          'cid': 3,
          'name': 'تارا اتوماتیک',
          'brand': 'ایران خودرو',
          'model': 'تارا',
          'trim_fa': 'اتوماتیک',
          'year': 1402,
          'price': 1400000000,
          'change_percent': 0.5,
          'market_price': true,
          'unique_id': 'tara-market',
        },
      ];

      return http.Response(
        jsonEncode(cars),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = CarRepository(
      client: client,
      preferences: preferences,
      runtimeToken: 'test-token',
    );

    final controller = AppController(
      preferences: preferences,
      repository: repository,
    );

    await controller.initialize();
    return controller;
  }

  Future<void> showMarketPage(
    WidgetTester tester,
    AppController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MarketPage(controller: controller)),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('جست‌وجو فاصله و نیم‌فاصله را مدیریت می‌کند', (tester) async {
    final controller = await createController();
    addTearDown(controller.dispose);

    await showMarketPage(tester, controller);

    await tester.enterText(find.byType(TextField), 'ری را');
    await tester.pump();

    expect(find.text('ری‌را اتوماتیک'), findsOneWidget);
    expect(find.text('دنا پلاس'), findsNothing);
    expect(find.text('تارا اتوماتیک'), findsNothing);
  });

  testWidgets('جست‌وجو با اعداد فارسی و انگلیسی کار می‌کند', (tester) async {
    final controller = await createController();
    addTearDown(controller.dispose);

    await showMarketPage(tester, controller);

    await tester.enterText(find.byType(TextField), '۱۴۰۳');
    await tester.pump();

    expect(find.text('دنا پلاس'), findsOneWidget);
    expect(find.text('ری‌را اتوماتیک'), findsNothing);

    await tester.enterText(find.byType(TextField), '1402');
    await tester.pump();

    expect(find.text('تارا اتوماتیک'), findsOneWidget);
    expect(find.text('دنا پلاس'), findsNothing);
  });

  testWidgets('فیلتر کارخانه فقط قیمت کارخانه را نمایش می‌دهد', (tester) async {
    final controller = await createController();
    addTearDown(controller.dispose);

    await showMarketPage(tester, controller);

    await tester.tap(find.widgetWithText(FilterChip, 'کارخانه'));
    await tester.pumpAndSettle();

    expect(find.text('دنا پلاس'), findsOneWidget);
    expect(find.text('ری‌را اتوماتیک'), findsNothing);
    expect(find.text('تارا اتوماتیک'), findsNothing);
  });

  testWidgets('فیلتر بازار فقط قیمت بازار را نمایش می‌دهد', (tester) async {
    final controller = await createController();
    addTearDown(controller.dispose);

    await showMarketPage(tester, controller);

    await tester.tap(find.widgetWithText(FilterChip, 'بازار'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('ری‌را اتوماتیک'), findsOneWidget);
    expect(find.text('تارا اتوماتیک'), findsOneWidget);
    expect(find.text('دنا پلاس'), findsNothing);
  });

  testWidgets('جست‌وجوی ناموجود پنل خالی و بازنشانی را نمایش می‌دهد', (
    tester,
  ) async {
    final controller = await createController();
    addTearDown(controller.dispose);

    await showMarketPage(tester, controller);

    await tester.enterText(find.byType(TextField), 'خودروی ناموجود');
    await tester.pump();

    expect(find.text('خودرویی پیدا نشد'), findsOneWidget);
    expect(find.text('پاک کردن فیلترها'), findsOneWidget);

    await tester.tap(find.text('پاک کردن فیلترها'));
    await tester.pump();

    expect(find.text('۳ نتیجه از ۳ خودرو'), findsOneWidget);
    expect(find.text('خودرویی پیدا نشد'), findsNothing);
  });
}
