import 'package:ravand/services/investment_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = InvestmentCalculator();

  group('InvestmentCalculator', () {
    test('سود و درصد بازده مثبت را محاسبه می‌کند', () {
      final result = calculator.calculate(
        purchasePrice: 1_000_000_000,
        currentPrice: 1_200_000_000,
      );

      expect(result.profitOrLossAmount, 200_000_000);
      expect(result.returnPercent, closeTo(20, 0.001));
      expect(result.outcome, InvestmentOutcome.profit);
      expect(result.isProfit, isTrue);
    });

    test('زیان و درصد بازده منفی را محاسبه می‌کند', () {
      final result = calculator.calculate(
        purchasePrice: 1_000_000_000,
        currentPrice: 800_000_000,
      );

      expect(result.profitOrLossAmount, -200_000_000);
      expect(result.returnPercent, closeTo(-20, 0.001));
      expect(result.outcome, InvestmentOutcome.loss);
      expect(result.isLoss, isTrue);
    });

    test('برای قیمت بدون تغییر بازده صفر برمی‌گرداند', () {
      final result = calculator.calculate(
        purchasePrice: 900_000_000,
        currentPrice: 900_000_000,
      );

      expect(result.profitOrLossAmount, 0);
      expect(result.returnPercent, 0);
      expect(result.outcome, InvestmentOutcome.unchanged);
      expect(result.isUnchanged, isTrue);
    });

    test('قیمت خرید صفر را قبول نمی‌کند', () {
      expect(
        () =>
            calculator.calculate(purchasePrice: 0, currentPrice: 1_000_000_000),
        throwsArgumentError,
      );
    });

    test('قیمت فعلی منفی را قبول نمی‌کند', () {
      expect(
        () => calculator.calculate(
          purchasePrice: 1_000_000_000,
          currentPrice: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
