import '../core/formatters.dart';

class CarPricePoint {
  const CarPricePoint({required this.date, required this.price});

  final String date;
  final int price;

  factory CarPricePoint.fromJson(Map<String, dynamic> json) {
    return CarPricePoint(
      date: cleanText(
        _firstValue(json, const ['date', 'jalali_date', 'label', 'time']),
      ),
      price:
          parseFlexibleInt(
            _firstValue(json, const ['price', 'value', 'market_price', 'y']),
          ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {'date': date, 'price': price};
}

/// Normalised representation of a vehicle returned by SourceArena.
///
/// Fields are intentionally non-nullable so screens can sort, filter and chart
/// data without repeating defensive JSON checks. Missing numeric values become
/// zero and missing text becomes an empty string.
class CarModel {
  CarModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.trim,
    required this.year,
    required this.description,
    required this.price,
    required this.changePercent,
    required this.marketPrice,
    required this.lastUpdate,
    required this.typeEn,
    required this.uniqueId,
    List<CarPricePoint> history = const [],
  }) : history = List.unmodifiable(history);

  final int id;
  final String name;
  final String brand;
  final String model;
  final String trim;
  final int year;
  final String description;
  final int price;
  final double changePercent;
  final bool marketPrice;
  final String lastUpdate;
  final String typeEn;
  final String uniqueId;
  final List<CarPricePoint> history;

  String get displayName =>
      name.isNotEmpty ? name : _buildName(brand, model, trim);

  factory CarModel.fromJson(Map<String, dynamic> json) {
    final uniqueId = cleanText(
      _firstValue(json, const ['unique_id', 'uniqueId', 'uid', 'slug']),
    );
    final type = cleanText(
      _firstValue(json, const ['type', 'type_fa', 'car', 'car_type']),
    );
    final brand = cleanText(
      _firstValue(json, const [
        'brand',
        'brand_fa',
        'brand_name',
        'company',
        'manufacturer',
      ]),
      fallback: type,
    );
    final model = cleanText(
      _firstValue(json, const ['model', 'model_fa', 'car_model']),
    );
    final trim = cleanText(
      _firstValue(json, const ['trim_fa', 'trim', 'version', 'variant']),
    );
    final explicitName = cleanText(
      _firstValue(json, const ['name', 'title', 'car_name', 'full_name']),
    );
    final name = explicitName.isNotEmpty
        ? explicitName
        : _buildName(type.isNotEmpty ? type : brand, model, trim);

    final rawId = _firstValue(json, const ['cid', 'id', 'car_id']);
    final id =
        parseFlexibleInt(rawId) ??
        _stableId(uniqueId.isNotEmpty ? uniqueId : '$name|${json['year']}');
    final history = _parseHistory(
      _firstValue(json, const [
        'history',
        'price_history',
        'priceHistory',
        'prices',
      ]),
    );

    return CarModel(
      id: id,
      name: name,
      brand: brand,
      model: model,
      trim: trim,
      year:
          parseFlexibleInt(
            _firstValue(json, const ['year', 'production_year', 'model_year']),
          ) ??
          0,
      description: cleanText(
        _firstValue(json, const ['description', 'desc', 'details']),
      ),
      price:
          parseFlexibleInt(
            _unwrapValue(
              _firstValue(json, const [
                'price',
                'latest_price',
                'current_price',
                'amount',
              ]),
            ),
          ) ??
          0,
      changePercent:
          parseFlexibleDouble(
            _unwrapValue(
              _firstValue(json, const [
                'change_percent',
                'changePercent',
                'percent_change',
                'change',
              ]),
            ),
          ) ??
          0,
      marketPrice: parseFlexibleBool(
        _firstValue(json, const ['market_price', 'marketPrice', 'is_market']),
        fallback: true,
      ),
      lastUpdate: cleanText(
        _firstValue(json, const [
          'last_update',
          'lastUpdate',
          'updated_at',
          'update',
        ]),
      ),
      typeEn: cleanText(
        _firstValue(json, const ['type_en', 'typeEn', 'slug_en']),
      ),
      uniqueId: uniqueId,
      history: history,
    );
  }

  CarModel copyWith({
    int? id,
    String? name,
    String? brand,
    String? model,
    String? trim,
    int? year,
    String? description,
    int? price,
    double? changePercent,
    bool? marketPrice,
    String? lastUpdate,
    String? typeEn,
    String? uniqueId,
    List<CarPricePoint>? history,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      trim: trim ?? this.trim,
      year: year ?? this.year,
      description: description ?? this.description,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      marketPrice: marketPrice ?? this.marketPrice,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      typeEn: typeEn ?? this.typeEn,
      uniqueId: uniqueId ?? this.uniqueId,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cid': id,
      'name': name,
      'brand': brand,
      'model': model,
      'trim_fa': trim,
      'year': year,
      'description': description,
      'price': price,
      'change_percent': changePercent,
      'market_price': marketPrice,
      'last_update': lastUpdate,
      'type_en': typeEn,
      'unique_id': uniqueId,
      'history': history.map((point) => point.toJson()).toList(),
    };
  }
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
  }
  return null;
}

Object? _unwrapValue(Object? value) {
  if (value is! Map) return value;
  for (final key in const ['value', 'amount', 'price', 'percent']) {
    if (value[key] != null) return value[key];
  }
  return value;
}

List<CarPricePoint> _parseHistory(Object? value) {
  if (value is! List) return const [];
  final points = <CarPricePoint>[];
  for (final item in value) {
    if (item is Map) {
      final point = CarPricePoint.fromJson(Map<String, dynamic>.from(item));
      if (point.date.isNotEmpty && point.price > 0) points.add(point);
    }
  }
  return points;
}

String _buildName(String base, String model, String trim) {
  final parts = <String>[];
  for (final part in [base, model, trim]) {
    final clean = cleanText(part);
    if (clean.isNotEmpty && !parts.contains(clean)) parts.add(clean);
  }
  return parts.join(' ');
}

int _stableId(String value) {
  // 32-bit FNV-1a, kept positive for convenient list keys and persistence.
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
