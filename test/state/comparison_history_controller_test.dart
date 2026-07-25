import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_model.dart';
import 'package:ravand/data/car_repository.dart';
import 'package:ravand/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'تاریخچه مشترک را بارگذاری و Scale مشترک را در Controller نگه می‌دارد',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final releaseResponse = Completer<void>();

      final client = MockClient((request) async {
        await releaseResponse.future;

        final date = request.url.queryParameters['date'];

        final prices = switch (date) {
          '1403/01/01' => (1_000_000_000, 1_300_000_000),
          '1403/02/01' => (1_100_000_000, 1_250_000_000),
          _ => (0, 0),
        };

        return http.Response(
          jsonEncode([
            _carJson(
              id: 1,
              uniqueId: 'first-car',
              name: 'خودروی اول',
              price: prices.$1,
            ),
            _carJson(
              id: 2,
              uniqueId: 'second-car',
              name: 'خودروی دوم',
              price: prices.$2,
            ),
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

      final loadFuture = controller.loadComparisonHistory(
        firstCar: _car(
          id: 1,
          uniqueId: 'first-car',
          name: 'خودروی اول',
          price: 1_150_000_000,
        ),
        secondCar: _car(
          id: 2,
          uniqueId: 'second-car',
          name: 'خودروی دوم',
          price: 1_350_000_000,
        ),
        jalaliDates: const ['1403/01/01', '1403/02/01'],
      );

      expect(controller.isComparisonHistoryLoading, isTrue);
      expect(controller.comparisonHistoryError, isNull);

      releaseResponse.complete();
      await loadFuture;

      expect(controller.isComparisonHistoryLoading, isFalse);
      expect(controller.comparisonHistoryError, isNull);
      expect(controller.hasComparisonHistory, isTrue);

      expect(controller.firstComparisonPoints, hasLength(2));
      expect(controller.secondComparisonPoints, hasLength(2));

      expect(controller.comparisonMinPrice, 1_000_000_000);
      expect(controller.comparisonMaxPrice, 1_300_000_000);
      expect(controller.comparisonMissingDates, isEmpty);
    },
  );

  test('نبود داده مشترک را در Controller مدیریت می‌کند', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final client = MockClient((request) async {
      final date = request.url.queryParameters['date'];

      final cars = date == '1403/01/01'
          ? [
              _carJson(
                id: 1,
                uniqueId: 'first-car',
                name: 'خودروی اول',
                price: 1_000_000_000,
              ),
              _carJson(
                id: 2,
                uniqueId: 'second-car',
                name: 'خودروی دوم',
                price: 1_200_000_000,
              ),
            ]
          : [
              // در تاریخ دوم فقط خودروی اول موجود است.
              _carJson(
                id: 1,
                uniqueId: 'first-car',
                name: 'خودروی اول',
                price: 1_100_000_000,
              ),
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

    addTearDown(controller.dispose);

    await controller.loadComparisonHistory(
      firstCar: _car(
        id: 1,
        uniqueId: 'first-car',
        name: 'خودروی اول',
        price: 1_150_000_000,
      ),
      secondCar: _car(
        id: 2,
        uniqueId: 'second-car',
        name: 'خودروی دوم',
        price: 1_250_000_000,
      ),
      jalaliDates: const ['1403/01/01', '1403/02/01'],
    );

    expect(controller.isComparisonHistoryLoading, isFalse);
    expect(controller.hasComparisonHistory, isFalse);

    expect(controller.comparisonMissingDates, ['1403/02/01']);

    expect(controller.comparisonHistoryError, isNotNull);
  });

  test('پاک‌سازی، نتیجه و خطای مقایسه را حذف می‌کند', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          _carJson(
            id: 1,
            uniqueId: 'first-car',
            name: 'خودروی اول',
            price: 1_000_000_000,
          ),
          _carJson(
            id: 2,
            uniqueId: 'second-car',
            name: 'خودروی دوم',
            price: 1_200_000_000,
          ),
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

    await controller.loadComparisonHistory(
      firstCar: _car(
        id: 1,
        uniqueId: 'first-car',
        name: 'خودروی اول',
        price: 1_100_000_000,
      ),
      secondCar: _car(
        id: 2,
        uniqueId: 'second-car',
        name: 'خودروی دوم',
        price: 1_300_000_000,
      ),
      jalaliDates: const ['1403/01/01', '1403/02/01'],
    );

    expect(controller.comparisonHistory, isNotNull);

    controller.clearComparisonHistory();

    expect(controller.comparisonHistory, isNull);
    expect(controller.firstComparisonPoints, isEmpty);
    expect(controller.secondComparisonPoints, isEmpty);
    expect(controller.comparisonHistoryError, isNull);
    expect(controller.isComparisonHistoryLoading, isFalse);
  });
}

Map<String, Object?> _carJson({
  required int id,
  required String uniqueId,
  required String name,
  required int price,
}) {
  return {
    'cid': id,
    'unique_id': uniqueId,
    'name': name,
    'brand': 'برند آزمایشی',
    'model': name,
    'year': 1403,
    'price': price,
    'market_price': true,
  };
}

CarModel _car({
  required int id,
  required String uniqueId,
  required String name,
  required int price,
}) {
  return CarModel(
    id: id,
    uniqueId: uniqueId,
    name: name,
    brand: 'برند آزمایشی',
    model: name,
    trim: '',
    year: 1403,
    description: '',
    price: price,
    changePercent: 0,
    marketPrice: true,
    lastUpdate: '',
    typeEn: '',
  );
}
