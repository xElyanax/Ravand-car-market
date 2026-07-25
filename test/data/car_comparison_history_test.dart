import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_model.dart';
import 'package:ravand/data/car_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'فقط تاریخ‌های مشترک دو خودرو را نگه می‌دارد و Scale مشترک می‌سازد',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final client = MockClient((request) async {
        final date = request.url.queryParameters['date'];

        final cars = switch (date) {
          '1403/01/01' => [
            _carJson(
              id: 1,
              uniqueId: 'car-one',
              name: 'خودروی اول',
              price: 1_000_000_000,
            ),
            _carJson(
              id: 2,
              uniqueId: 'car-two',
              name: 'خودروی دوم',
              price: 1_200_000_000,
            ),
          ],
          '1403/02/01' => [
            _carJson(
              id: 1,
              uniqueId: 'car-one',
              name: 'خودروی اول',
              price: 900_000_000,
            ),
            _carJson(
              id: 2,
              uniqueId: 'car-two',
              name: 'خودروی دوم',
              price: 1_300_000_000,
            ),
          ],
          // در این تاریخ، خودروی دوم داده ندارد.
          '1403/03/01' => [
            _carJson(
              id: 1,
              uniqueId: 'car-one',
              name: 'خودروی اول',
              price: 1_100_000_000,
            ),
          ],
          _ => <Map<String, Object?>>[],
        };

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

      addTearDown(repository.dispose);

      final result = await repository.fetchComparisonHistory(
        firstCar: _car(
          id: 1,
          uniqueId: 'car-one',
          name: 'خودروی اول',
          price: 1_150_000_000,
        ),
        secondCar: _car(
          id: 2,
          uniqueId: 'car-two',
          name: 'خودروی دوم',
          price: 1_350_000_000,
        ),
        jalaliDates: const ['1403/01/01', '1403/02/01', '1403/03/01'],
      );

      expect(result.firstPoints, hasLength(2));
      expect(result.secondPoints, hasLength(2));

      expect(result.firstPoints.map((point) => point.date), [
        '1403/01/01',
        '1403/02/01',
      ]);

      expect(result.secondPoints.map((point) => point.date), [
        '1403/01/01',
        '1403/02/01',
      ]);

      expect(result.missingDates, ['1403/03/01']);
      expect(result.hasEnoughDataForChart, isTrue);

      expect(result.minPrice, 900_000_000);
      expect(result.maxPrice, 1_300_000_000);
    },
  );
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
