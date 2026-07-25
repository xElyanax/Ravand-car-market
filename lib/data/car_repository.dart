import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters.dart';
import 'car_model.dart';
import 'demo_data.dart';

enum CarDataSource { network, cache, demo }

/// One atomic payload for a ChangeNotifier (or any other state holder).
class CarDataResult {
  CarDataResult({
    required List<CarModel> cars,
    required this.source,
    required this.fetchedAt,
    this.requestedDate,
    this.error,
  }) : cars = List.unmodifiable(cars);

  final List<CarModel> cars;
  final CarDataSource source;
  final DateTime fetchedAt;
  final String? requestedDate;
  final String? error;

  bool get isDemo => source == CarDataSource.demo;
  bool get isStale => source == CarDataSource.cache;
  bool get hasError => error != null && error!.isNotEmpty;
}

class CarHistoryResult {
  CarHistoryResult({
    required List<CarPricePoint> points,
    required List<String> missingDates,
    required this.usedDemoData,
  }) : points = List.unmodifiable(points),
       missingDates = List.unmodifiable(missingDates);

  final List<CarPricePoint> points;
  final List<String> missingDates;
  final bool usedDemoData;

  bool get hasData => points.isNotEmpty;

  bool get hasEnoughDataForChart => points.length >= 2;

  bool get isComplete => missingDates.isEmpty;
}

class CarComparisonHistoryResult {
  CarComparisonHistoryResult({
    required List<CarPricePoint> firstPoints,
    required List<CarPricePoint> secondPoints,
    required List<String> missingDates,
    required this.usedDemoData,
  }) : firstPoints = List.unmodifiable(firstPoints),
       secondPoints = List.unmodifiable(secondPoints),
       missingDates = List.unmodifiable(missingDates);

  final List<CarPricePoint> firstPoints;
  final List<CarPricePoint> secondPoints;
  final List<String> missingDates;
  final bool usedDemoData;

  bool get hasEnoughDataForChart =>
      firstPoints.length >= 2 && secondPoints.length >= 2;

  bool get isComplete => missingDates.isEmpty;

  int? get minPrice {
    int? result;

    for (final point in [...firstPoints, ...secondPoints]) {
      if (result == null || point.price < result) {
        result = point.price;
      }
    }

    return result;
  }

  int? get maxPrice {
    int? result;

    for (final point in [...firstPoints, ...secondPoints]) {
      if (result == null || point.price > result) {
        result = point.price;
      }
    }

    return result;
  }
}

class CarAtDateResult {
  const CarAtDateResult({
    required this.requestedDate,
    required this.source,
    required this.car,
    this.error,
  });

  final String requestedDate;
  final CarDataSource source;
  final CarModel? car;
  final String? error;

  bool get available => car != null && car!.price > 0;

  bool get isDemo => source == CarDataSource.demo;
}

class CarRepository {
  CarRepository({
    http.Client? client,
    SharedPreferences? preferences,
    String? runtimeToken,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _preferences = preferences,
       _runtimeToken = _cleanToken(runtimeToken);

  static const _environmentToken = String.fromEnvironment('SOURCEARENA_TOKEN');
  static const _host = 'apis.sourcearena.ir';
  static const _path = '/api/';

  static const _latestJsonKey = 'sourcearena.latest.json.v1';
  static const _latestSavedAtKey = 'sourcearena.latest.saved_at.v1';
  static String _historyJsonKeyFor(String date) {
    final safeDate = date.replaceAll('/', '_');
    return 'sourcearena.history.$safeDate.json.v2';
  }

  static String _historySavedAtKeyFor(String date) {
    final safeDate = date.replaceAll('/', '_');
    return 'sourcearena.history.$safeDate.saved_at.v2';
  }

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  SharedPreferences? _preferences;
  Future<SharedPreferences>? _preferencesFuture;
  String? _runtimeToken;
  bool _allowEnvironmentToken = true;
  bool _disposed = false;

  /// Runtime value wins over `--dart-define=SOURCEARENA_TOKEN=...`.
  String? get effectiveToken {
    if (_runtimeToken != null) {
      return _runtimeToken;
    }

    if (!_allowEnvironmentToken) {
      return null;
    }

    return _cleanToken(_environmentToken);
  }

  /// The device-local override, excluding any compile-time fallback.
  String? get runtimeToken => _runtimeToken;

  bool get hasToken => effectiveToken != null;

  /// Passing null or a blank value restores the compile-time token.
  void setRuntimeToken(String? token) {
    _runtimeToken = _cleanToken(token);
    _allowEnvironmentToken = true;
  }

  void disableAllTokens() {
    _runtimeToken = null;
    _allowEnvironmentToken = false;
  }

  bool get areAllTokensDisabled =>
      _runtimeToken == null && !_allowEnvironmentToken;

  Future<CarDataResult> fetchLatest({bool forceRefresh = false}) {
    return fetchCars(forceRefresh: forceRefresh);
  }

  Future<CarDataResult> fetchHistorical(
    String jalaliDate, {
    bool forceRefresh = false,
  }) {
    return fetchCars(jalaliDate: jalaliDate, forceRefresh: forceRefresh);
  }

  Future<CarAtDateResult> fetchCarAtDate({
    required CarModel car,
    required String jalaliDate,
    bool forceRefresh = false,
    bool allowDemoData = false,
  }) async {
    _ensureNotDisposed();

    final validatedDate = _validateDate(jalaliDate);

    if (validatedDate == null) {
      throw const FormatException('تاریخ شمسی نمی‌تواند خالی باشد.');
    }

    final snapshot = await fetchHistorical(
      validatedDate,
      forceRefresh: forceRefresh,
    );

    if (snapshot.isDemo && !allowDemoData) {
      return CarAtDateResult(
        requestedDate: snapshot.requestedDate ?? validatedDate,
        source: snapshot.source,
        car: null,
        error: snapshot.error,
      );
    }

    final historicalCar = _findMatchingCar(
      target: car,
      candidates: snapshot.cars,
    );

    return CarAtDateResult(
      requestedDate: snapshot.requestedDate ?? validatedDate,
      source: snapshot.source,
      car: historicalCar,
      error: snapshot.error,
    );
  }

  Future<CarHistoryResult> fetchHistoryForCar({
    required CarModel car,
    required Iterable<String> jalaliDates,
    bool forceRefresh = false,
    bool allowDemoData = false,
  }) async {
    _ensureNotDisposed();

    final uniqueDates = <String>{};

    for (final rawDate in jalaliDates) {
      final validatedDate = _validateDate(rawDate);

      if (validatedDate != null) {
        uniqueDates.add(validatedDate);
      }
    }
    final pointsByDate = <String, CarPricePoint>{};
    final missingDates = <String>[];
    var usedDemoData = false;

    for (final date in uniqueDates) {
      final snapshot = await fetchHistorical(date, forceRefresh: forceRefresh);

      if (snapshot.isDemo) {
        usedDemoData = true;

        if (!allowDemoData) {
          missingDates.add(date);
          continue;
        }
      }

      final historicalCar = _findMatchingCar(
        target: car,
        candidates: snapshot.cars,
      );

      if (historicalCar == null || historicalCar.price <= 0) {
        missingDates.add(date);
        continue;
      }

      pointsByDate[date] = CarPricePoint(
        date: date,
        price: historicalCar.price,
      );
    }

    final points = pointsByDate.values.toList()
      ..sort((first, second) => _compareJalaliDates(first.date, second.date));

    return CarHistoryResult(
      points: points,
      missingDates: missingDates,
      usedDemoData: usedDemoData,
    );
  }

  Future<CarComparisonHistoryResult> fetchComparisonHistory({
    required CarModel firstCar,
    required CarModel secondCar,
    required Iterable<String> jalaliDates,
    bool forceRefresh = false,
    bool allowDemoData = false,
  }) async {
    _ensureNotDisposed();

    final uniqueDates = <String>{};

    for (final rawDate in jalaliDates) {
      final validatedDate = _validateDate(rawDate);

      if (validatedDate != null) {
        uniqueDates.add(validatedDate);
      }
    }

    final firstPointsByDate = <String, CarPricePoint>{};
    final secondPointsByDate = <String, CarPricePoint>{};
    final missingDates = <String>[];

    var usedDemoData = false;

    for (final date in uniqueDates) {
      // هر تاریخ فقط یک بار از API یا Cache دریافت می‌شود.
      final snapshot = await fetchHistorical(date, forceRefresh: forceRefresh);

      if (snapshot.isDemo) {
        usedDemoData = true;

        if (!allowDemoData) {
          missingDates.add(date);
          continue;
        }
      }

      final firstHistoricalCar = _findMatchingCar(
        target: firstCar,
        candidates: snapshot.cars,
      );

      final secondHistoricalCar = _findMatchingCar(
        target: secondCar,
        candidates: snapshot.cars,
      );

      final firstPrice = firstHistoricalCar?.price ?? 0;
      final secondPrice = secondHistoricalCar?.price ?? 0;

      // فقط تاریخ‌هایی نگه داشته می‌شوند که هر دو خودرو داده معتبر دارند.
      if (firstPrice <= 0 || secondPrice <= 0) {
        missingDates.add(date);
        continue;
      }

      firstPointsByDate[date] = CarPricePoint(date: date, price: firstPrice);

      secondPointsByDate[date] = CarPricePoint(date: date, price: secondPrice);
    }

    final firstPoints = firstPointsByDate.values.toList()
      ..sort((first, second) => _compareJalaliDates(first.date, second.date));

    final secondPoints = secondPointsByDate.values.toList()
      ..sort((first, second) => _compareJalaliDates(first.date, second.date));

    return CarComparisonHistoryResult(
      firstPoints: firstPoints,
      secondPoints: secondPoints,
      missingDates: missingDates,
      usedDemoData: usedDemoData,
    );
  }

  /// Loads a current or historical full-market snapshot.
  ///
  /// Historical snapshots are immutable and served from the selected-date
  /// cache first. Current data attempts the network first and uses cached data
  /// only as a graceful fallback. When neither is available, deterministic
  /// demo data keeps the whole product usable and [CarDataResult.isDemo] makes
  /// that state explicit to the UI.
  ///
  Future<CarDataResult> fetchCars({
    String? jalaliDate,
    bool forceRefresh = false,
  }) async {
    _ensureNotDisposed();
    final requestedDate = _validateDate(jalaliDate);

    if (requestedDate != null && !forceRefresh) {
      final cached = await _readCache(requestedDate: requestedDate);
      if (cached != null) return cached;
    }

    final token = effectiveToken;
    if (token == null) {
      final cached = await _readCache(requestedDate: requestedDate);
      if (cached != null) {
        return _withError(
          cached,
          'توکن سرویس تنظیم نشده؛ آخرین داده ذخیره‌شده نمایش داده می‌شود.',
        );
      }
      return _demoResult(
        requestedDate: requestedDate,
        error: 'توکن سرویس تنظیم نشده و داده‌های نمایشی در حال استفاده هستند.',
      );
    }

    try {
      final parameters = <String, String>{'token': token, 'car': 'all'};
      if (requestedDate != null) parameters['date'] = requestedDate;
      final uri = Uri.https(_host, _path, parameters);
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _RepositoryException(_messageForStatus(response.statusCode));
      }

      var rawJson = utf8
          .decode(response.bodyBytes, allowMalformed: true)
          .trim();
      if (rawJson.startsWith('\ufeff')) rawJson = rawJson.substring(1);
      final cars = _parseCars(rawJson);
      if (cars.isEmpty) {
        throw const _RepositoryException(
          'پاسخ سرویس معتبر بود اما خودرویی در آن پیدا نشد.',
        );
      }

      await _writeCache(
        rawJson: rawJson,
        requestedDate: requestedDate,
        savedAt: DateTime.now(),
      );
      return CarDataResult(
        cars: cars,
        source: CarDataSource.network,
        fetchedAt: DateTime.now(),
        requestedDate: requestedDate,
      );
    } on TimeoutException {
      return _fallbackAfterFailure(
        requestedDate: requestedDate,
        message:
            'مهلت اتصال به SourceArena تمام شد؛ اینترنت یا وضعیت سرویس را بررسی کنید.',
      );
    } on _RepositoryException catch (error) {
      return _fallbackAfterFailure(
        requestedDate: requestedDate,
        message: error.message,
      );
    } on FormatException {
      return _fallbackAfterFailure(
        requestedDate: requestedDate,
        message: 'پاسخ SourceArena یک JSON معتبر با ساختار قابل خواندن نیست.',
      );
    } on http.ClientException {
      return _fallbackAfterFailure(
        requestedDate: requestedDate,
        message: kIsWeb
            ? 'مرورگر نتوانست به SourceArena متصل شود؛ اینترنت، DNS یا محدودیت CORS را بررسی کنید.'
            : 'ارتباط شبکه با SourceArena برقرار نشد؛ اینترنت یا DNS را بررسی کنید.',
      );
    } catch (_) {
      // Avoid surfacing exception strings because HTTP errors may include the
      // request URI and therefore the secret query token.
      return _fallbackAfterFailure(
        requestedDate: requestedDate,
        message: 'خطای پیش‌بینی‌نشده‌ای هنگام دریافت قیمت‌ها رخ داد.',
      );
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_ownsClient) _client.close();
  }

  Future<CarDataResult> _fallbackAfterFailure({
    required String? requestedDate,
    required String message,
  }) async {
    final cached = await _readCache(requestedDate: requestedDate);
    if (cached != null) {
      return _withError(cached, '$message داده ذخیره‌شده نمایش داده می‌شود.');
    }
    return _demoResult(
      requestedDate: requestedDate,
      error: '$message داده‌های نمایشی در حال استفاده هستند.',
    );
  }

  CarDataResult _demoResult({
    required String? requestedDate,
    required String error,
  }) {
    final cars = requestedDate == null
        ? buildDemoCars()
        : demoSnapshotForDate(requestedDate);
    return CarDataResult(
      cars: cars,
      source: CarDataSource.demo,
      fetchedAt: DateTime.now(),
      requestedDate: requestedDate,
      error: error,
    );
  }

  CarDataResult _withError(CarDataResult result, String error) {
    return CarDataResult(
      cars: result.cars,
      source: result.source,
      fetchedAt: result.fetchedAt,
      requestedDate: result.requestedDate,
      error: error,
    );
  }

  Future<CarDataResult?> _readCache({required String? requestedDate}) async {
    try {
      final preferences = await _getPreferences();

      late final String? rawJson;
      late final String? savedAtValue;

      if (requestedDate == null) {
        rawJson = preferences.getString(_latestJsonKey);
        savedAtValue = preferences.getString(_latestSavedAtKey);
      } else {
        rawJson = preferences.getString(_historyJsonKeyFor(requestedDate));

        savedAtValue = preferences.getString(
          _historySavedAtKeyFor(requestedDate),
        );
      }

      if (rawJson == null || rawJson.trim().isEmpty) {
        return null;
      }

      final cars = _parseCars(rawJson);

      if (cars.isEmpty) {
        return null;
      }

      return CarDataResult(
        cars: cars,
        source: CarDataSource.cache,
        fetchedAt: DateTime.tryParse(savedAtValue ?? '') ?? DateTime.now(),
        requestedDate: requestedDate,
      );
    } catch (_) {
      // خرابی Cache نباید مانع دریافت داده شبکه یا Demo شود.
      return null;
    }
  }

  Future<void> _writeCache({
    required String rawJson,
    required String? requestedDate,
    required DateTime savedAt,
  }) async {
    try {
      final preferences = await _getPreferences();

      if (requestedDate == null) {
        await preferences.setString(_latestJsonKey, rawJson);

        await preferences.setString(
          _latestSavedAtKey,
          savedAt.toIso8601String(),
        );

        return;
      }

      await preferences.setString(_historyJsonKeyFor(requestedDate), rawJson);

      await preferences.setString(
        _historySavedAtKeyFor(requestedDate),
        savedAt.toIso8601String(),
      );
    } catch (_) {
      // حتی اگر ذخیره محلی شکست خورد، پاسخ موفق API قابل استفاده است.
    }
  }

  Future<SharedPreferences> _getPreferences() {
    final existing = _preferences;
    if (existing != null) return Future.value(existing);
    return _preferencesFuture ??= SharedPreferences.getInstance().then((value) {
      _preferences = value;
      return value;
    });
  }

  CarModel? _findMatchingCar({
    required CarModel target,
    required List<CarModel> candidates,
  }) {
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

    final targetIdentity = _fallbackCarIdentity(target);

    for (final candidate in candidates) {
      if (_fallbackCarIdentity(candidate) == targetIdentity) {
        return candidate;
      }
    }

    return null;
  }

  String _fallbackCarIdentity(CarModel car) {
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

  int _compareJalaliDates(String first, String second) {
    return _jalaliSortKey(first).compareTo(_jalaliSortKey(second));
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

  String _carSnapshotKey(CarModel car) {
    String normalize(String value) {
      return cleanText(
        value,
      ).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    }

    return [
      car.id.toString(),
      car.uniqueId.trim().toLowerCase(),
      normalize(car.typeEn),
      normalize(car.brand),
      normalize(car.model),
      normalize(car.trim),
      car.year.toString(),
      car.marketPrice ? 'market' : 'factory',
    ].join('|');
  }

  List<CarModel> _parseCars(String rawJson) {
    Object? decoded = jsonDecode(rawJson);
    // A few PHP-style APIs wrap the real JSON document in a JSON string.
    for (var depth = 0; depth < 2 && decoded is String; depth++) {
      final nested = decoded.trim();
      if (!(nested.startsWith('{') || nested.startsWith('['))) break;
      decoded = jsonDecode(nested);
    }

    _throwIfErrorEnvelope(decoded);
    if (decoded is! Map && decoded is! List) {
      throw const FormatException('Unsupported SourceArena response root.');
    }

    final maps = _extractCarMaps(decoded);
    final byIdentity = <String, CarModel>{};

    for (final map in maps) {
      final car = CarModel.fromJson(map);

      if (car.name.isEmpty && car.uniqueId.isEmpty) {
        continue;
      }

      byIdentity[_carSnapshotKey(car)] = car;
    }

    return List.unmodifiable(byIdentity.values);
  }

  void _throwIfErrorEnvelope(Object? value) {
    if (value is String) {
      if (value.trim().isNotEmpty) {
        throw _RepositoryException(
          _messageForEnvelopeError(diagnosticText: value),
        );
      }
      return;
    }
    if (value is! Map) return;

    final map = <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString().toLowerCase(): entry.value,
    };
    Object? firstValue(List<String> keys) {
      for (final key in keys) {
        if (map.containsKey(key)) return map[key];
      }
      return null;
    }

    final statusValue = firstValue(const ['status', 'success', 'ok']);
    final errorValue = firstValue(const ['error', 'errors']);
    final code = _parseStatusCode(
      firstValue(const ['status_code', 'statuscode', 'http_code', 'code']),
    );
    final diagnosticParts = <String>[
      for (final key in const [
        'message',
        'msg',
        'error',
        'errors',
        'detail',
        'description',
      ])
        if (map[key] != null) map[key].toString(),
    ];
    final diagnosticText = diagnosticParts.join(' ');

    final hasKnownErrorStatus =
        code == 401 ||
        code == 403 ||
        code == 429 ||
        (code != null && code >= 500 && code <= 599);
    final isFailure = _isFailureFlag(statusValue) || _hasErrorValue(errorValue);

    if (hasKnownErrorStatus || isFailure) {
      throw _RepositoryException(
        _messageForEnvelopeError(
          statusCode: code,
          diagnosticText: diagnosticText,
        ),
      );
    }

    final hasNestedPayload = map.values.any(
      (item) => item is Map || item is List,
    );
    if (!_looksLikeCar(Map<String, dynamic>.from(map)) &&
        !hasNestedPayload &&
        diagnosticText.trim().isNotEmpty) {
      throw _RepositoryException(
        _messageForEnvelopeError(
          statusCode: code,
          diagnosticText: diagnosticText,
        ),
      );
    }
  }

  int? _parseStatusCode(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  bool _isFailureFlag(Object? value) {
    if (value is bool) return !value;
    if (value is num) {
      return value == 0 || (value >= 400 && value <= 599);
    }
    final normalized = value?.toString().trim().toLowerCase();
    return const {
      '0',
      'false',
      'error',
      'failed',
      'failure',
      'unauthorized',
      'forbidden',
      'invalid',
    }.contains(normalized);
  }

  bool _hasErrorValue(Object? value) {
    if (value == null || value == false) return false;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized.isNotEmpty &&
          !const {
            '0',
            'false',
            'null',
            'none',
            'success',
            'ok',
          }.contains(normalized);
    }
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  String _messageForStatus(int statusCode) {
    return _messageForEnvelopeError(statusCode: statusCode);
  }

  String _messageForEnvelopeError({
    int? statusCode,
    String diagnosticText = '',
  }) {
    if (statusCode == 401 || statusCode == 403) {
      return 'توکن SourceArena نامعتبر، منقضی یا فاقد دسترسی است.';
    }
    if (statusCode == 429) {
      return 'سهمیه درخواست‌های SourceArena تمام شده یا محدودیت تعداد درخواست فعال است.';
    }
    if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
      return 'سرویس SourceArena موقتاً دچار اختلال است (خطای سرور $statusCode).';
    }

    final diagnostic = diagnosticText.toLowerCase();
    const quotaMarkers = [
      'quota',
      'rate limit',
      'too many',
      'limit exceeded',
      'request limit',
      'سهمیه',
      'تعداد درخواست',
      'محدودیت درخواست',
    ];
    if (quotaMarkers.any(diagnostic.contains)) {
      return 'سهمیه درخواست‌های SourceArena تمام شده یا محدودیت تعداد درخواست فعال است.';
    }

    const credentialMarkers = [
      'unauthorized',
      'forbidden',
      'invalid token',
      'expired token',
      'api key',
      'apikey',
      'access denied',
      'توکن',
      'کلید دسترسی',
      'نامعتبر',
      'منقضی',
      'عدم دسترسی',
    ];
    if (credentialMarkers.any(diagnostic.contains)) {
      return 'توکن SourceArena نامعتبر، منقضی یا فاقد دسترسی است.';
    }

    const serverMarkers = [
      'internal server',
      'server error',
      'unavailable',
      'maintenance',
      'temporarily',
      'خطای سرور',
      'در دسترس نیست',
      'تعمیر',
    ];
    if (serverMarkers.any(diagnostic.contains)) {
      return 'سرویس SourceArena موقتاً دچار اختلال است.';
    }

    if (statusCode != null) {
      return 'SourceArena با کد HTTP $statusCode پاسخ داد و داده خودرو دریافت نشد.';
    }
    return 'SourceArena یک پاسخ خطا برگرداند و داده خودرو دریافت نشد.';
  }

  List<Map<String, dynamic>> _extractCarMaps(Object? value, [int depth = 0]) {
    if (value == null || depth > 8) return const [];
    if (value is List) {
      final result = <Map<String, dynamic>>[];
      for (final item in value) {
        result.addAll(_extractCarMaps(item, depth + 1));
      }
      return result;
    }
    if (value is! Map) return const [];

    final map = <String, dynamic>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    if (_looksLikeCar(map)) return [map];

    final result = <Map<String, dynamic>>[];
    const preferredContainers = [
      'data',
      'result',
      'results',
      'cars',
      'car',
      'items',
      'response',
      'records',
    ];
    final visited = <String>{};
    for (final key in preferredContainers) {
      if (map.containsKey(key)) {
        visited.add(key);
        result.addAll(_extractCarMaps(map[key], depth + 1));
      }
    }
    if (result.isNotEmpty) return result;

    // Also supports maps keyed by cid/unique id rather than a JSON array.
    for (final entry in map.entries) {
      if (!visited.contains(entry.key) &&
          (entry.value is Map || entry.value is List)) {
        result.addAll(_extractCarMaps(entry.value, depth + 1));
      }
    }
    return result;
  }

  bool _looksLikeCar(Map<String, dynamic> value) {
    final hasId =
        value.containsKey('cid') ||
        value.containsKey('unique_id') ||
        value.containsKey('car_id');
    final hasPrice =
        value.containsKey('price') ||
        value.containsKey('latest_price') ||
        value.containsKey('current_price');
    final hasIdentity =
        value.containsKey('type') ||
        value.containsKey('name') ||
        value.containsKey('model') ||
        value.containsKey('car_name');
    return hasPrice && (hasId || hasIdentity);
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalised = normalizeJalaliDate(value);
    if (normalised == null) {
      throw FormatException('Invalid Jalali date: $value');
    }
    return normalised;
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('CarRepository has been disposed.');
  }

  static String? _cleanToken(String? token) {
    final value = token?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class _RepositoryException implements Exception {
  const _RepositoryException(this.message);

  final String message;
}
