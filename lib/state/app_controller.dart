import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../data/car_model.dart';
import '../data/car_repository.dart';
import '../core/formatters.dart';

class AppController extends ChangeNotifier {
  AppController({
    required SharedPreferences preferences,
    CarRepository? repository,
  }) : _preferences = preferences,
       _repository =
           repository ??
           CarRepository(
             preferences: preferences,
             runtimeToken: preferences.getString(_tokenKey),
           ) {
    _favoriteIds.addAll(preferences.getStringList(_favoritesKey) ?? const []);
    _compareIds.addAll(preferences.getStringList(_compareKey) ?? const []);
  }

  static const _favoritesKey = 'favorite_car_ids_v1';
  static const _compareKey = 'compare_car_ids_v1';
  // v2 deliberately ignores the legacy v1 browser override so a newly
  // compiled token is not shadowed by stale local storage.
  static const _tokenKey = 'sourcearena_api_token_v2';

  final SharedPreferences _preferences;
  final CarRepository _repository;
  final Set<String> _favoriteIds = {};
  final List<String> _compareIds = [];
  final Map<int, double> _periodReturns = {};
  final Map<String, CarHistoryResult> _carHistoryResults = {};
  final Set<String> _carHistoryLoadingKeys = {};
  final Map<String, String> _carHistoryErrors = {};

  List<CarModel> _cars = const [];
  CarDataSource _source = CarDataSource.demo;
  DateTime? _fetchedAt;
  String? _errorMessage;
  String? _periodDate;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPeriodLoading = false;
  int _selectedPeriodDays = 30;
  int _tabIndex = 0;

  List<CarModel> get cars => List.unmodifiable(_cars);
  CarDataSource get source => _source;
  DateTime? get fetchedAt => _fetchedAt;
  String? get errorMessage => _errorMessage;
  String? get periodDate => _periodDate;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isPeriodLoading => _isPeriodLoading;
  bool get isDemo => _source == CarDataSource.demo;
  bool get isCached => _source == CarDataSource.cache;
  bool get hasToken => _repository.hasToken;
  int get selectedPeriodDays => _selectedPeriodDays;
  int get tabIndex => _tabIndex;
  Map<int, double> get periodReturns => Map.unmodifiable(_periodReturns);

  List<CarPricePoint> historyFor(CarModel car, int days) {
    final result = _carHistoryResults[_historyKey(car, days)];
    return result?.points ?? const [];
  }

  bool isHistoryLoading(CarModel car, int days) {
    return _carHistoryLoadingKeys.contains(_historyKey(car, days));
  }

  String? historyErrorFor(CarModel car, int days) {
    return _carHistoryErrors[_historyKey(car, days)];
  }

  bool hasEnoughHistory(CarModel car, int days) {
    return _carHistoryResults[_historyKey(car, days)]?.hasEnoughDataForChart ??
        false;
  }

  List<String> missingHistoryDatesFor(CarModel car, int days) {
    return _carHistoryResults[_historyKey(car, days)]?.missingDates ?? const [];
  }

  List<CarModel> get favoriteCars =>
      _cars.where((car) => _favoriteIds.contains(car.uniqueId)).toList();

  List<CarModel> get compareCars => _compareIds
      .map((id) => _cars.where((car) => car.uniqueId == id).firstOrNull)
      .whereType<CarModel>()
      .toList();

  int get risingCount => _cars.where((car) => car.changePercent > 0).length;
  int get fallingCount => _cars.where((car) => car.changePercent < 0).length;
  int get stableCount => _cars.where((car) => car.changePercent == 0).length;

  double get medianChange {
    if (_cars.isEmpty) return 0;
    final values = _cars.map((car) => car.changePercent).toList()..sort();
    final middle = values.length ~/ 2;
    if (values.length.isOdd) return values[middle];
    return (values[middle - 1] + values[middle]) / 2;
  }

  int get medianPrice {
    final values =
        _cars.where((car) => car.price > 0).map((car) => car.price).toList()
          ..sort();
    if (values.isEmpty) return 0;
    final middle = values.length ~/ 2;
    return values.length.isOdd
        ? values[middle]
        : ((values[middle - 1] + values[middle]) / 2).round();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await _loadLatest();
    _isLoading = false;
    notifyListeners();
    await loadPeriod(_selectedPeriodDays);
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    await _loadLatest(forceRefresh: true);
    _isRefreshing = false;
    notifyListeners();
    await loadPeriod(_selectedPeriodDays, forceRefresh: true);
  }

  Future<void> _loadLatest({bool forceRefresh = false}) async {
    final result = await _repository.fetchLatest(forceRefresh: forceRefresh);
    if (result.cars.isNotEmpty) _cars = result.cars;
    _source = result.source;
    _fetchedAt = result.fetchedAt;
    _errorMessage = result.error;
    _trimSelections();
    _clearCarHistory();
  }

  Future<bool> connectWithToken(String token) async {
    final normalized = token.trim();

    if (normalized.isEmpty) {
      return false;
    }

    final previousRuntimeToken = _repository.runtimeToken;

    _repository.setRuntimeToken(normalized);

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    final result = await _repository.fetchLatest(forceRefresh: true);

    final connected = result.source == CarDataSource.network;

    if (connected) {
      await _preferences.setString(_tokenKey, normalized);
    } else {
      _repository.setRuntimeToken(previousRuntimeToken);
    }

    if (result.cars.isNotEmpty) {
      _cars = result.cars;
    }

    // تاریخچه‌های قبلی مربوط به داده یا توکن قبلی هستند.
    _clearCarHistory();

    _source = result.source;
    _fetchedAt = result.fetchedAt;
    _errorMessage = result.error;
    _isLoading = false;

    notifyListeners();

    if (connected) {
      await loadPeriod(_selectedPeriodDays, forceRefresh: true);
    }

    return connected;
  }

  Future<void> useDemoMode() async {
    await _preferences.remove(_tokenKey);
    _repository.setRuntimeToken(null);
    await refresh();
  }

  void setTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  bool isFavorite(CarModel car) => _favoriteIds.contains(car.uniqueId);

  Future<void> toggleFavorite(CarModel car) async {
    if (!_favoriteIds.add(car.uniqueId)) {
      _favoriteIds.remove(car.uniqueId);
    }
    notifyListeners();
    await _preferences.setStringList(_favoritesKey, _favoriteIds.toList());
  }

  bool isCompared(CarModel car) => _compareIds.contains(car.uniqueId);

  Future<void> toggleCompare(CarModel car) async {
    if (_compareIds.contains(car.uniqueId)) {
      _compareIds.remove(car.uniqueId);
    } else {
      if (_compareIds.length == 2) _compareIds.removeAt(0);
      _compareIds.add(car.uniqueId);
    }
    notifyListeners();
    await _persistCompare();
  }

  Future<void> replaceCompare(int index, CarModel car) async {
    _compareIds.remove(car.uniqueId);
    if (index < _compareIds.length) {
      _compareIds[index] = car.uniqueId;
    } else {
      _compareIds.add(car.uniqueId);
    }
    notifyListeners();
    await _persistCompare();
  }

  Future<void> clearCompare() async {
    _compareIds.clear();
    notifyListeners();
    await _persistCompare();
  }

  Future<void> _persistCompare() =>
      _preferences.setStringList(_compareKey, _compareIds);

  Future<void> loadPeriod(int days, {bool forceRefresh = false}) async {
    _selectedPeriodDays = days;
    _isPeriodLoading = true;
    notifyListeners();

    try {
      final target = DateTime.now().subtract(Duration(days: days));
      final date = _toJalaliDate(target);

      final result = await _repository.fetchHistorical(
        date,
        forceRefresh: forceRefresh,
      );

      _periodReturns.clear();

      if (!result.isDemo) {
        for (final currentCar in _cars) {
          final historicalCar = _findHistoricalCar(currentCar, result.cars);

          if (historicalCar == null ||
              historicalCar.price <= 0 ||
              currentCar.price <= 0) {
            continue;
          }

          _periodReturns[currentCar.id] =
              (currentCar.price - historicalCar.price) *
              100 /
              historicalCar.price;
        }
      }

      _periodDate = result.requestedDate ?? date;
    } catch (_) {
      _periodReturns.clear();
      _periodDate = null;
    } finally {
      _isPeriodLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCarHistory(
    CarModel car,
    int days, {
    bool forceRefresh = false,
  }) async {
    final normalizedDays = _normalizeHistoryDays(days);
    final key = _historyKey(car, normalizedDays);

    if (_carHistoryLoadingKeys.contains(key)) {
      return;
    }

    if (!forceRefresh && _carHistoryResults.containsKey(key)) {
      return;
    }

    if (_source == CarDataSource.demo) {
      _carHistoryResults.remove(key);
      _carHistoryErrors[key] =
          'در حالت نمایشی، تاریخچه واقعی قیمت در دسترس نیست.';
      notifyListeners();
      return;
    }

    _carHistoryLoadingKeys.add(key);
    _carHistoryErrors.remove(key);
    notifyListeners();

    try {
      final dates = _buildHistoryDates(normalizedDays);

      final historicalResult = await _repository.fetchHistoryForCar(
        car: car,
        jalaliDates: dates,
        forceRefresh: forceRefresh,
        allowDemoData: false,
      );

      final pointsByDate = <String, CarPricePoint>{
        for (final point in historicalResult.points) point.date: point,
      };

      if (car.price > 0) {
        final today = _toJalaliDate(DateTime.now());

        pointsByDate[today] = CarPricePoint(date: today, price: car.price);
      }

      final points = pointsByDate.values.toList()
        ..sort(
          (first, second) =>
              _jalaliSortKey(first.date).compareTo(_jalaliSortKey(second.date)),
        );

      final result = CarHistoryResult(
        points: points,
        missingDates: historicalResult.missingDates,
        usedDemoData: historicalResult.usedDemoData,
      );

      _carHistoryResults[key] = result;

      if (!result.hasEnoughDataForChart) {
        _carHistoryErrors[key] =
            'داده تاریخی کافی برای رسم نمودار این خودرو پیدا نشد.';
      } else if (result.usedDemoData) {
        _carHistoryErrors[key] =
            'بعضی تاریخ‌ها از سرویس دریافت نشدند و از نمودار حذف شدند.';
      } else if (result.missingDates.isNotEmpty) {
        _carHistoryErrors[key] =
            'برای ${result.missingDates.length} تاریخ، قیمت این خودرو موجود نبود.';
      }
    } catch (_) {
      _carHistoryResults.remove(key);
      _carHistoryErrors[key] = 'دریافت تاریخچه قیمت این خودرو با خطا مواجه شد.';
    } finally {
      _carHistoryLoadingKeys.remove(key);
      notifyListeners();
    }
  }

  bool hasPeriodReturn(CarModel car) {
    return _periodReturns.containsKey(car.id);
  }

  double returnFor(CarModel car) {
    return _periodReturns[car.id] ?? 0;
  }

  Future<InvestmentResult> calculateInvestment(CarModel car, int days) async {
    final target = DateTime.now().subtract(Duration(days: days));
    final jalali = Jalali.fromDateTime(target);
    final date = '${jalali.year}/${jalali.month}/${jalali.day}';
    final result = await _repository.fetchHistorical(date);
    final previous = result.cars.where((item) => item.id == car.id).firstOrNull;
    if (previous == null || previous.price <= 0 || car.price <= 0) {
      return InvestmentResult.unavailable(
        car: car,
        requestedDate: date,
        source: result.source,
      );
    }
    return InvestmentResult(
      car: car,
      requestedDate: result.requestedDate ?? date,
      previousPrice: previous.price,
      currentPrice: car.price,
      source: result.source,
    );
  }

  List<CarModel> budgetMatches(int budget, {double tolerance = 0}) {
    final ceiling = budget * (1 + tolerance);
    final matches =
        _cars.where((car) => car.price > 0 && car.price <= ceiling).toList()
          ..sort((a, b) {
            final aDistance = (budget - a.price).abs();
            final bDistance = (budget - b.price).abs();
            final distance = aDistance.compareTo(bDistance);
            return distance != 0
                ? distance
                : b.changePercent.compareTo(a.changePercent);
          });
    return matches;
  }

  List<CarModel> topMovers({required bool rising, int limit = 5}) {
    final result =
        _cars.where((car) => _periodReturns.containsKey(car.id)).where((car) {
          final value = _periodReturns[car.id] ?? 0;

          return rising ? value > 0 : value < 0;
        }).toList()..sort((first, second) {
          final firstReturn = _periodReturns[first.id] ?? 0;
          final secondReturn = _periodReturns[second.id] ?? 0;

          return rising
              ? secondReturn.compareTo(firstReturn)
              : firstReturn.compareTo(secondReturn);
        });

    return result.take(math.min(limit, result.length)).toList();
  }

  String _historyKey(CarModel car, int days) {
    return '${car.id}:$days';
  }

  int _normalizeHistoryDays(int days) {
    return switch (days) {
      30 => 30,
      90 => 90,
      180 => 180,
      365 => 365,
      _ => 30,
    };
  }

  List<String> _buildHistoryDates(int days) {
    final totalPoints = switch (days) {
      30 => 6,
      90 => 7,
      180 => 7,
      365 => 13,
      _ => 6,
    };

    final now = DateTime.now();
    final dates = <String>{};

    // نقطه امروز جداگانه با قیمت فعلی خودرو اضافه می‌شود.
    // در اینجا فقط تاریخ‌های گذشته ساخته می‌شوند.
    for (var index = totalPoints - 1; index >= 1; index--) {
      final offsetDays = (days * index / (totalPoints - 1)).round();

      final date = now.subtract(Duration(days: offsetDays));

      dates.add(_toJalaliDate(date));
    }

    return dates.toList();
  }

  String _toJalaliDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);

    return '${jalali.year}/${jalali.month}/${jalali.day}';
  }

  int _jalaliSortKey(String value) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return 0;
    }

    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;

    return (year * 10000) + (month * 100) + day;
  }

  void _clearCarHistory() {
    _carHistoryResults.clear();
    _carHistoryLoadingKeys.clear();
    _carHistoryErrors.clear();
  }

  CarModel? _findHistoricalCar(CarModel target, List<CarModel> candidates) {
    final targetUniqueId = target.uniqueId.trim();

    if (targetUniqueId.isNotEmpty) {
      for (final candidate in candidates) {
        if (candidate.uniqueId.trim() == targetUniqueId) {
          return candidate;
        }
      }
    }

    if (target.id > 0) {
      for (final candidate in candidates) {
        if (candidate.id == target.id) {
          return candidate;
        }
      }
    }

    final targetIdentity = _carIdentity(target);

    for (final candidate in candidates) {
      if (_carIdentity(candidate) == targetIdentity) {
        return candidate;
      }
    }

    return null;
  }

  String _carIdentity(CarModel car) {
    String normalize(String value) {
      return cleanText(
        value,
      ).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    }

    return [
      normalize(car.typeEn),
      normalize(car.brand),
      normalize(car.model),
      normalize(car.trim),
      car.year.toString(),
    ].join('|');
  }

  void _trimSelections() {
    final valid = _cars.map((car) => car.uniqueId).toSet();
    _favoriteIds.removeWhere((id) => !valid.contains(id));
    _compareIds.removeWhere((id) => !valid.contains(id));
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}

class InvestmentResult {
  const InvestmentResult({
    required this.car,
    required this.requestedDate,
    required this.previousPrice,
    required this.currentPrice,
    required this.source,
  }) : available = true;

  const InvestmentResult.unavailable({
    required this.car,
    required this.requestedDate,
    required this.source,
  }) : previousPrice = 0,
       currentPrice = 0,
       available = false;

  final CarModel car;
  final String requestedDate;
  final int previousPrice;
  final int currentPrice;
  final CarDataSource source;
  final bool available;

  int get profit => currentPrice - previousPrice;
  double get profitPercent =>
      previousPrice == 0 ? 0 : profit * 100 / previousPrice;
}
