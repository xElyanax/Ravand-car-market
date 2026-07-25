import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_model.dart';
import 'package:ravand/data/car_repository.dart';
import 'package:ravand/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  test('period returns and market rankings use historical prices', () async {
    final currentCars = [
      _car(
        id: 1,
        uniqueId: 'car-1',
        name: 'خودرو صعودی',
        price: 120000000,
        changePercent: -5,
      ),
      _car(
        id: 2,
        uniqueId: 'car-2',
        name: 'خودرو نزولی',
        price: 90000000,
        changePercent: 8,
      ),
      _car(
        id: 3,
        uniqueId: 'car-3',
        name: 'بدون تاریخچه',
        price: 150000000,
        changePercent: 20,
      ),
    ];

    final historicalCars = [
      _car(id: 1, uniqueId: 'car-1', name: 'خودرو صعودی', price: 100000000),
      _car(id: 2, uniqueId: 'car-2', name: 'خودرو نزولی', price: 100000000),
    ];

    final repository = _FakeCarRepository(
      preferences: preferences,
      latestCars: currentCars,
      historicalCars: historicalCars,
    );

    final controller = AppController(
      preferences: preferences,
      repository: repository,
    );

    await controller.initialize();

    expect(controller.hasPeriodReturn(currentCars[0]), isTrue);
    expect(controller.hasPeriodReturn(currentCars[1]), isTrue);
    expect(controller.hasPeriodReturn(currentCars[2]), isFalse);

    expect(controller.returnFor(currentCars[0]), closeTo(20, 0.001));

    expect(controller.returnFor(currentCars[1]), closeTo(-10, 0.001));

    expect(controller.returnFor(currentCars[2]), 0);

    final rising = controller.topMovers(rising: true);
    final falling = controller.topMovers(rising: false);

    expect(rising.map((car) => car.id).toList(), [1]);

    expect(falling.map((car) => car.id).toList(), [2]);

    controller.dispose();
  });
}

class _FakeCarRepository extends CarRepository {
  _FakeCarRepository({
    required SharedPreferences preferences,
    required this.latestCars,
    required this.historicalCars,
  }) : super(preferences: preferences);

  final List<CarModel> latestCars;
  final List<CarModel> historicalCars;

  @override
  Future<CarDataResult> fetchLatest({bool forceRefresh = false}) async {
    return CarDataResult(
      cars: latestCars,
      source: CarDataSource.network,
      fetchedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<CarDataResult> fetchHistorical(
    String jalaliDate, {
    bool forceRefresh = false,
  }) async {
    return CarDataResult(
      cars: historicalCars,
      source: CarDataSource.network,
      fetchedAt: DateTime(2026, 1, 1),
      requestedDate: jalaliDate,
    );
  }
}

CarModel _car({
  required int id,
  required String uniqueId,
  required String name,
  required int price,
  double changePercent = 0,
}) {
  return CarModel(
    id: id,
    uniqueId: uniqueId,
    name: name,
    brand: 'برند آزمایشی',
    model: 'model-$id',
    trim: '',
    year: 1403,
    description: '',
    price: price,
    changePercent: changePercent,
    marketPrice: true,
    lastUpdate: '',
    typeEn: 'test-car-$id',
  );
}
