import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('پاسخ تاریخی خالی را Cache می‌کند و درخواست تکراری نمی‌فرستد', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    var requestCount = 0;

    final client = MockClient((request) async {
      requestCount++;

      return http.Response(
        jsonEncode(<Object?>[]),
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

    final first = await repository.fetchHistorical('1403/01/01');

    expect(first.isMissingSnapshot, isTrue);
    expect(first.source, CarDataSource.network);
    expect(first.cars, isEmpty);
    expect(requestCount, 1);

    final second = await repository.fetchHistorical('1403/01/01');

    expect(second.isMissingSnapshot, isTrue);
    expect(second.source, CarDataSource.cache);
    expect(second.cars, isEmpty);

    expect(requestCount, 1);
  });

  test('forceRefresh تاریخ ناموجود را دوباره بررسی می‌کند', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    var requestCount = 0;

    final client = MockClient((request) async {
      requestCount++;

      return http.Response(
        jsonEncode(<Object?>[]),
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

    await repository.fetchHistorical('1403/01/01');

    await repository.fetchHistorical('1403/01/01', forceRefresh: true);

    expect(requestCount, 2);
  });
}
