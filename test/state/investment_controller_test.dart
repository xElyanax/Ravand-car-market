import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_model.dart';
import 'package:ravand/data/car_repository.dart';
import 'package:ravand/services/investment_calculator.dart';
import 'package:ravand/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('سود واقعی را با قیمت تاریخی محاسبه می‌کند', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'cid': 101,
            'unique_id': 'test-car-101',
            'name': 'خودروی آزمایشی',
            'brand': 'برند آزمایشی',
            'model': 'مدل آزمایشی',
            'year': 1403,
            'price': 1_000_000_000,
            'market_price': true,
          },
        ]),
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

    addTearDown(controller.dispose);

    final currentCar = CarModel(
      id: 101,
      uniqueId: 'test-car-101',
      name: 'خودروی آزمایشی',
      brand: 'برند آزمایشی',
      model: 'مدل آزمایشی',
      trim: '',
      year: 1403,
      description: '',
      price: 1_200_000_000,
      changePercent: 0,
      marketPrice: true,
      lastUpdate: '',
      typeEn: '',
    );

    final result = await controller.calculateInvestment(currentCar, 30);

    expect(result.available, isTrue);
    expect(result.previousPrice, 1_000_000_000);
    expect(result.currentPrice, 1_200_000_000);
    expect(result.profit, 200_000_000);
    expect(result.profitPercent, closeTo(20, 0.001));
    expect(result.outcome, InvestmentOutcome.profit);
    expect(result.isProfit, isTrue);
  });

  test('نبود خودروی تاریخی را مدیریت می‌کند', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'cid': 999,
            'unique_id': 'another-car',
            'name': 'خودروی دیگر',
            'price': 900_000_000,
            'market_price': true,
          },
        ]),
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

    addTearDown(controller.dispose);

    final currentCar = CarModel(
      id: 101,
      uniqueId: 'test-car-101',
      name: 'خودروی آزمایشی',
      brand: '',
      model: '',
      trim: '',
      year: 1403,
      description: '',
      price: 1_200_000_000,
      changePercent: 0,
      marketPrice: true,
      lastUpdate: '',
      typeEn: '',
    );

    final result = await controller.calculateInvestment(currentCar, 30);

    expect(result.available, isFalse);
    expect(result.calculation, isNull);
    expect(result.profit, 0);
    expect(result.profitPercent, 0);
  });
  test('با تاریخ شمسی دقیق سود را محاسبه می‌کند', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    String? receivedDate;

    final client = MockClient((request) async {
      receivedDate = request.url.queryParameters['date'];

      return http.Response(
        jsonEncode([
          {
            'cid': 101,
            'unique_id': 'test-car-101',
            'name': 'خودروی آزمایشی',
            'brand': 'برند آزمایشی',
            'model': 'مدل آزمایشی',
            'year': 1403,
            'price': 900_000_000,
            'market_price': true,
          },
        ]),
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

    addTearDown(controller.dispose);

    final currentCar = CarModel(
      id: 101,
      uniqueId: 'test-car-101',
      name: 'خودروی آزمایشی',
      brand: 'برند آزمایشی',
      model: 'مدل آزمایشی',
      trim: '',
      year: 1403,
      description: '',
      price: 1_080_000_000,
      changePercent: 0,
      marketPrice: true,
      lastUpdate: '',
      typeEn: '',
    );

    final result = await controller.calculateInvestmentForDate(
      currentCar,
      '1403/06/15',
    );

    expect(receivedDate, '1403/06/15');
    expect(result.available, isTrue);
    expect(result.requestedDate, '1403/06/15');
    expect(result.previousPrice, 900_000_000);
    expect(result.currentPrice, 1_080_000_000);
    expect(result.profit, 180_000_000);
    expect(result.profitPercent, closeTo(20, 0.001));
  });
}
