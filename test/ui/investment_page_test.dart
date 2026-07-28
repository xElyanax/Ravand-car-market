import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_repository.dart';
import 'package:ravand/state/app_controller.dart';
import 'package:ravand/ui/tools_pages.dart';
import 'package:ravand/data/car_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppController> createController({
    required bool historicalMatches,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    const latestCar = {
      'cid': 1,
      'name': 'تارا اتوماتیک',
      'brand': 'ایران خودرو',
      'model': 'تارا',
      'trim_fa': 'اتوماتیک',
      'year': 1402,
      'price': 1400000000,
      'change_percent': 0.5,
      'market_price': true,
      'unique_id': 'tara-market',
    };

    final client = MockClient((request) async {
      final isHistorical = request.url.queryParameters.containsKey('date');
      
      // اگر درخواست مربوط به تاریخچه باشد و سناریو عدم وجود داده تاریخی باشد، لیست خالی برمی‌گردانیم.
      if (isHistorical && !historicalMatches) {
        return http.Response(
          jsonEncode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      final historicalCar = {
        ...latestCar,
        'price': 1000000000,
      };

      final body = jsonEncode([isHistorical ? historicalCar : latestCar]);

      return http.Response(
        body,
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

  Future<void> showInvestmentPage(
    WidgetTester tester,
    AppController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvestmentPage(controller: controller),
        ),
      ),
    );

    await tester.pump(); 
    await tester.pumpAndSettle(); 
  }

  testWidgets('renders investment page controls', (tester) async {
    final controller = await createController(historicalMatches: true);
    addTearDown(controller.dispose);

    await showInvestmentPage(tester, controller);

    expect(find.text('اگر خریده بودم…'), findsOneWidget);
    expect(find.text('یک سناریوی فرضی بساز'), findsOneWidget);
    expect(
      find.text('قیمت خودرو در ابتدای بازه را با قیمت امروز مقایسه می‌کنیم.'),
      findsOneWidget,
    );
    expect(find.text('خودرو'), findsOneWidget);
    expect(find.text('زمان خرید فرضی'), findsOneWidget);

    expect(find.byType(DropdownButtonFormField<CarModel>), findsOneWidget);
    expect(find.byType(SegmentedButton<int>), findsOneWidget);

    expect(find.text('۱ ماه'), findsOneWidget);
    expect(find.text('۳ ماه'), findsOneWidget);
    expect(find.text('۶ ماه'), findsOneWidget);
    expect(find.text('۱ سال'), findsOneWidget);
  });

  testWidgets('shows successful investment result', (tester) async {
    final controller = await createController(historicalMatches: true);
    addTearDown(controller.dispose);

    await showInvestmentPage(tester, controller);

    expect(find.text('سود فرضی تا امروز'), findsOneWidget);
    expect(find.text('قیمت امروز'), findsOneWidget);
    expect(find.textContaining('قیمت در'), findsOneWidget);
    expect(find.text('قیمت تاریخی پیدا نشد'), findsNothing);
  });

  testWidgets('shows empty state when historical data is missing', (tester) async {
    final controller = await createController(historicalMatches: false);
    addTearDown(controller.dispose);

    await showInvestmentPage(tester, controller);

    expect(find.text('قیمت تاریخی پیدا نشد'), findsOneWidget);
    expect(
      find.text(
        'ممکن است این مدل در تاریخ انتخابی داده‌ی ثبت‌شده نداشته باشد. بازه دیگری را امتحان کن.',
      ),
      findsOneWidget,
    );
  });
}
