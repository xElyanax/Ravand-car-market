import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_model.dart';
import 'package:ravand/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SourceArena model accepts Persian digits and mixed API types', () {
    final car = CarModel.fromJson({
      'type': 'آریسان',
      'model': 2,
      'year': '۱۴۰۳',
      'cid': '۱۰۹۸۲',
      'price': '۷۲۰٬۰۰۰٬۰۰۰ تومان',
      'change_percent': '۱٫۴۱',
      'market_price': 1,
      'last_update': '۵ ساعت پیش',
      'unique_id': 'bbc99',
    });

    expect(car.id, 10982);
    expect(car.year, 1403);
    expect(car.price, 720000000);
    expect(car.changePercent, 1.41);
    expect(car.marketPrice, isTrue);
    expect(car.displayName, contains('آریسان'));
  });

  testWidgets('app opens the market pulse in Persian demo mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(RavandApp(preferences: preferences));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('نبض امروز بازار'), findsOneWidget);
    expect(find.text('ابزارهای تصمیم‌گیری'), findsOneWidget);
    expect(find.text('حالت نمایشی'), findsOneWidget);
  });
}
