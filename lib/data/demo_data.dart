import '../core/formatters.dart';
import 'car_model.dart';

const _demoDates = <String>[
  '1404/04/15',
  '1404/05/15',
  '1404/06/15',
  '1404/07/15',
  '1404/08/15',
  '1404/09/15',
  '1404/10/15',
  '1404/11/15',
  '1404/12/15',
  '1405/01/15',
  '1405/02/15',
  '1405/03/15',
  '1405/04/15',
];

/// A varied, deterministic market used when the API cannot be reached.
///
/// A fresh unmodifiable list is returned so controllers can safely sort or
/// filter their own copy without mutating the fallback source.
List<CarModel> buildDemoCars() {
  return List.unmodifiable(
    _specs.indexed.map((entry) {
      final index = entry.$1;
      final spec = entry.$2;
      return CarModel(
        id: spec.id,
        name: spec.name,
        brand: spec.brand,
        model: spec.model,
        trim: spec.trim,
        year: spec.year,
        description: spec.description,
        price: spec.currentPrice,
        changePercent: spec.changePercent,
        marketPrice: spec.marketPrice,
        lastUpdate: spec.lastUpdate,
        typeEn: spec.typeEn,
        uniqueId: spec.uniqueId,
        history: _buildHistory(
          startPrice: spec.startPrice,
          currentPrice: spec.currentPrice,
          seed: index,
        ),
      );
    }),
  );
}

/// Builds a demo snapshot matching a historical API request.
///
/// Monthly demo points use the middle of each month. A request for another day
/// receives the latest point on or before that day (or the earliest point when
/// it predates the demo window).
List<CarModel> demoSnapshotForDate(String jalaliDate) {
  final normalised = normalizeJalaliDate(jalaliDate);
  if (normalised == null) return buildDemoCars();

  return List.unmodifiable(
    buildDemoCars().map((car) {
      var selected = car.history.first;
      for (final point in car.history) {
        if (point.date.compareTo(normalised) <= 0) {
          selected = point;
        } else {
          break;
        }
      }
      return car.copyWith(
        price: selected.price,
        changePercent: 0,
        lastUpdate: 'آرشیو ${toPersianDigits(normalised)}',
      );
    }),
  );
}

List<CarPricePoint> _buildHistory({
  required int startPrice,
  required int currentPrice,
  required int seed,
}) {
  const wiggle = <double>[
    0,
    0.011,
    -0.007,
    0.016,
    -0.012,
    0.006,
    -0.004,
    0.013,
    -0.009,
    0.008,
    -0.005,
    0.004,
    0,
  ];
  final points = <CarPricePoint>[];
  final lastIndex = _demoDates.length - 1;
  for (var index = 0; index <= lastIndex; index++) {
    final progress = index / lastIndex;
    final baseline = startPrice + (currentPrice - startPrice) * progress;
    final noise = index == 0 || index == lastIndex
        ? 0.0
        : wiggle[(index + seed) % wiggle.length];
    final rawPrice = baseline * (1 + noise);
    final rounded = (rawPrice / 1000000).round() * 1000000;
    points.add(
      CarPricePoint(
        date: _demoDates[index],
        price: index == lastIndex ? currentPrice : rounded,
      ),
    );
  }
  return points;
}

class _DemoSpec {
  const _DemoSpec({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.brand,
    required this.model,
    required this.trim,
    required this.year,
    required this.description,
    required this.startPrice,
    required this.currentPrice,
    required this.changePercent,
    required this.typeEn,
    this.lastUpdate = '۱۲ دقیقه پیش',
    this.marketPrice = true,
  });

  final int id;
  final String uniqueId;
  final String name;
  final String brand;
  final String model;
  final String trim;
  final int year;
  final String description;
  final int startPrice;
  final int currentPrice;
  final double changePercent;
  final bool marketPrice;
  final String lastUpdate;
  final String typeEn;
}

const _specs = <_DemoSpec>[
  _DemoSpec(
    id: 10982,
    uniqueId: 'bbc99',
    name: 'آریسان ۲ ارتقایافته',
    brand: 'ایران خودرو',
    model: 'آریسان ۲',
    trim: 'ارتقایافته',
    year: 1403,
    description: 'دوگانه‌سوز، ارتقایافته و مناسب کاربری شهری',
    startPrice: 600000000,
    currentPrice: 720000000,
    changePercent: 1.41,
    typeEn: 'arisun',
    lastUpdate: '۵ ساعت پیش',
  ),
  _DemoSpec(
    id: 12071,
    uniqueId: 'p207p',
    name: 'پژو ۲۰۷ پانوراما',
    brand: 'ایران خودرو',
    model: 'پژو ۲۰۷',
    trim: 'دنده‌ای پانوراما',
    year: 1404,
    description: 'فرمان برقی، سقف شیشه‌ای و رینگ آلومینیومی',
    startPrice: 920000000,
    currentPrice: 1120000000,
    changePercent: 2.3,
    typeEn: 'peugeot-207',
  ),
  _DemoSpec(
    id: 12084,
    uniqueId: 'dnpta',
    name: 'دنا پلاس توربو اتوماتیک',
    brand: 'ایران خودرو',
    model: 'دنا پلاس',
    trim: 'توربو اتوماتیک آپشنال',
    year: 1404,
    description: 'موتور EF7 توربو، گیربکس شش‌سرعته و سانروف',
    startPrice: 1280000000,
    currentPrice: 1580000000,
    changePercent: 1.1,
    typeEn: 'dena-plus',
    lastUpdate: '۲۸ دقیقه پیش',
  ),
  _DemoSpec(
    id: 12110,
    uniqueId: 'tarv4',
    name: 'تارا اتوماتیک V4 LX',
    brand: 'ایران خودرو',
    model: 'تارا',
    trim: 'V4 LX',
    year: 1404,
    description: 'گیربکس شش‌سرعته، کنترل پایداری و صندلی برقی',
    startPrice: 1360000000,
    currentPrice: 1650000000,
    changePercent: -0.6,
    typeEn: 'tara-v4',
  ),
  _DemoSpec(
    id: 22031,
    uniqueId: 'sains',
    name: 'ساینا S',
    brand: 'سایپا',
    model: 'ساینا',
    trim: 'S استاندارد ۸۵گانه',
    year: 1404,
    description: 'سدان اقتصادی با کنترل پایداری و سنسور نور',
    startPrice: 520000000,
    currentPrice: 615000000,
    changePercent: 0,
    typeEn: 'saina-s',
    lastUpdate: '۱ ساعت پیش',
  ),
  _DemoSpec(
    id: 22044,
    uniqueId: 'qgxll',
    name: 'کوییک GX-L',
    brand: 'سایپا',
    model: 'کوییک',
    trim: 'GX-L',
    year: 1404,
    description: 'هاچ‌بک اقتصادی با موتور M15i و نمایشگر لمسی',
    startPrice: 565000000,
    currentPrice: 675000000,
    changePercent: -1.5,
    typeEn: 'quick-gxl',
  ),
  _DemoSpec(
    id: 22059,
    uniqueId: 'atlsg',
    name: 'اطلس G',
    brand: 'سایپا',
    model: 'اطلس',
    trim: 'G',
    year: 1404,
    description: 'کراس‌اوور شهری با سانروف و کنترل پایداری',
    startPrice: 700000000,
    currentPrice: 845000000,
    changePercent: 1.7,
    typeEn: 'atlas-g',
  ),
  _DemoSpec(
    id: 22076,
    uniqueId: 'shnpa',
    name: 'شاهین پلاس اتوماتیک',
    brand: 'سایپا',
    model: 'شاهین پلاس',
    trim: 'اتوماتیک',
    year: 1404,
    description: 'موتور ME16، گیربکس شش‌سرعته و تجهیزات کامل ایمنی',
    startPrice: 1150000000,
    currentPrice: 1420000000,
    changePercent: 0.8,
    typeEn: 'shahin-plus',
    lastUpdate: '۴۲ دقیقه پیش',
  ),
  _DemoSpec(
    id: 31022,
    uniqueId: 'hms7p',
    name: 'هایما S7 پرو',
    brand: 'هایما',
    model: 'S7',
    trim: 'پرو ۱.۵ توربو',
    year: 1404,
    description: 'کراس‌اوور خانوادگی با دوربین ۳۶۰ و سقف پانوراما',
    startPrice: 2050000000,
    currentPrice: 2650000000,
    changePercent: 2.05,
    typeEn: 'haima-s7-pro',
  ),
  _DemoSpec(
    id: 31038,
    uniqueId: 'rera7',
    name: 'ری‌را ۱.۷ توربو',
    brand: 'ایران خودرو',
    model: 'ری‌را',
    trim: 'اتوماتیک',
    year: 1404,
    description: 'کراس‌اوور ملی با کروز تطبیقی و دستیارهای رانندگی',
    startPrice: 1900000000,
    currentPrice: 2450000000,
    changePercent: 3.2,
    typeEn: 'rira',
    marketPrice: false,
  ),
  _DemoSpec(
    id: 41015,
    uniqueId: 'kmcj7',
    name: 'KMC J7',
    brand: 'کرمان موتور',
    model: 'KMC J7',
    trim: '۱.۵ توربو',
    year: 1404,
    description: 'لیفت‌بک اسپرت با گیربکس دوکلاچه و دوربین ۳۶۰',
    startPrice: 2700000000,
    currentPrice: 2550000000,
    changePercent: -2.4,
    typeEn: 'kmc-j7',
  ),
  _DemoSpec(
    id: 51042,
    uniqueId: 'fdl7p',
    name: 'فیدلیتی پرایم ۷ نفره',
    brand: 'بهمن موتور',
    model: 'فیدلیتی پرایم',
    trim: '۷ نفره',
    year: 1404,
    description: 'کراس‌اوور جادار با سه ردیف صندلی و سقف پانوراما',
    startPrice: 2300000000,
    currentPrice: 2880000000,
    changePercent: 1.9,
    typeEn: 'fidelity-prime',
  ),
  _DemoSpec(
    id: 51061,
    uniqueId: 'dgnpr',
    name: 'دیگنیتی پرایم',
    brand: 'بهمن موتور',
    model: 'دیگنیتی',
    trim: 'پرایم',
    year: 1403,
    description: 'کراس‌اوور کوپه با صندوق برقی و دوربین ۳۶۰',
    startPrice: 2800000000,
    currentPrice: 2570000000,
    changePercent: -1.2,
    typeEn: 'dignity-prime',
  ),
  _DemoSpec(
    id: 61018,
    uniqueId: 'lmrem',
    name: 'لاماری ایما',
    brand: 'آرین پارس موتور',
    model: 'لاماری ایما',
    trim: '۱.۵ توربو',
    year: 1404,
    description: 'کراس‌اوور اسپرت با موتور توربو و طراحی فست‌بک',
    startPrice: 2450000000,
    currentPrice: 3100000000,
    changePercent: 2.8,
    typeEn: 'lamari-eama',
  ),
  _DemoSpec(
    id: 71027,
    uniqueId: 't8pmi',
    name: 'تیگو ۸ پرو مکس IE',
    brand: 'فونیکس',
    model: 'تیگو ۸ پرو مکس',
    trim: 'IE AWD',
    year: 1404,
    description: 'کراس‌اوور هفت‌نفره دو دیفرانسیل با امکانات کامل',
    startPrice: 4000000000,
    currentPrice: 5050000000,
    changePercent: 1.35,
    typeEn: 'tiggo-8-pro-max',
  ),
  _DemoSpec(
    id: 81009,
    uniqueId: 'tycrl',
    name: 'تویوتا کرولا ۱.۲ توربو',
    brand: 'تویوتا',
    model: 'کرولا',
    trim: '۱.۲ توربو وارداتی',
    year: 2024,
    description: 'سدان وارداتی کم‌مصرف با مجموعه کامل تجهیزات ایمنی',
    startPrice: 4600000000,
    currentPrice: 5850000000,
    changePercent: -0.35,
    typeEn: 'toyota-corolla',
    lastUpdate: '۲ ساعت پیش',
  ),
];
