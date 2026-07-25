import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_model.dart';
import 'package:ravand/data/car_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('historical snapshots are cached separately by date', () async {
    final preferences = await SharedPreferences.getInstance();

    final onlineRepository = CarRepository(
      preferences: preferences,
      runtimeToken: 'test-token',
      client: MockClient((request) async {
        final date = request.url.queryParameters['date'];

        final price = switch (date) {
          '1404/01/01' => 100000000,
          '1404/02/01' => 120000000,
          _ => 0,
        };

        return http.Response(
          jsonEncode([_carJson(price: price)]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await onlineRepository.fetchHistorical('1404/01/01', forceRefresh: true);

    await onlineRepository.fetchHistorical('1404/02/01', forceRefresh: true);

    final offlineRepository = CarRepository(
      preferences: preferences,
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );

    final firstDate = await offlineRepository.fetchHistorical('1404/1/1');

    final secondDate = await offlineRepository.fetchHistorical('1404/2/1');

    expect(firstDate.source, CarDataSource.cache);
    expect(secondDate.source, CarDataSource.cache);

    expect(firstDate.cars.single.price, 100000000);
    expect(secondDate.cars.single.price, 120000000);
  });

  test('car history is matched and sorted by Jalali date', () async {
    final preferences = await SharedPreferences.getInstance();

    final repository = CarRepository(
      preferences: preferences,
      runtimeToken: 'test-token',
      client: MockClient((request) async {
        final date = request.url.queryParameters['date'];

        final price = switch (date) {
          '1404/01/01' => 100000000,
          '1404/02/01' => 115000000,
          '1404/03/01' => 130000000,
          _ => 0,
        };

        return http.Response(
          jsonEncode([
            _carJson(price: price, id: date == '1404/2/1' ? 999 : 10),
          ]),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final targetCar = CarModel(
      id: 10,
      uniqueId: 'tara-v1-1403',
      name: 'Tara V1',
      brand: 'Iran Khodro',
      model: 'V1',
      trim: '',
      year: 1403,
      description: '',
      price: 140000000,
      changePercent: 0,
      marketPrice: true,
      lastUpdate: '',
      typeEn: 'tara',
    );

    final result = await repository.fetchHistoryForCar(
      car: targetCar,
      jalaliDates: const ['1404/3/1', '1404/1/1', '1404/2/1'],
      forceRefresh: true,
    );

    expect(result.points.map((point) => point.date).toList(), [
      '1404/01/01',
      '1404/02/01',
      '1404/03/01',
    ]);

    expect(result.points.map((point) => point.price).toList(), [
      100000000,
      115000000,
      130000000,
    ]);

    expect(result.missingDates, isEmpty);
    expect(result.hasEnoughDataForChart, isTrue);
  });
}

Map<String, Object?> _carJson({required int price, int id = 10}) {
  return {
    'cid': id,
    'unique_id': 'tara-v1-1403',
    'type': 'Tara',
    'type_en': 'tara',
    'brand': 'Iran Khodro',
    'model': 'V1',
    'year': 1403,
    'price': price,
    'change_percent': 0,
    'market_price': true,
    'last_update': 'today',
  };
}
