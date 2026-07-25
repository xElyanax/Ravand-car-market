enum InvestmentOutcome { profit, loss, unchanged }

class InvestmentCalculationResult {
  const InvestmentCalculationResult({
    required this.purchasePrice,
    required this.currentPrice,
    required this.profitOrLossAmount,
    required this.returnPercent,
    required this.outcome,
  });

  /// قیمت خودرو در تاریخ خرید فرضی.
  final int purchasePrice;

  /// قیمت فعلی خودرو.
  final int currentPrice;

  /// عدد مثبت یعنی سود و عدد منفی یعنی زیان.
  final int profitOrLossAmount;

  /// درصد بازده نسبت به قیمت خرید.
  final double returnPercent;

  final InvestmentOutcome outcome;

  bool get isProfit => outcome == InvestmentOutcome.profit;

  bool get isLoss => outcome == InvestmentOutcome.loss;

  bool get isUnchanged => outcome == InvestmentOutcome.unchanged;
}

class InvestmentCalculator {
  const InvestmentCalculator();

  InvestmentCalculationResult calculate({
    required int purchasePrice,
    required int currentPrice,
  }) {
    if (purchasePrice <= 0) {
      throw ArgumentError.value(
        purchasePrice,
        'purchasePrice',
        'قیمت خرید باید بیشتر از صفر باشد.',
      );
    }

    if (currentPrice < 0) {
      throw ArgumentError.value(
        currentPrice,
        'currentPrice',
        'قیمت فعلی نمی‌تواند منفی باشد.',
      );
    }

    final profitOrLossAmount = currentPrice - purchasePrice;

    final returnPercent = (profitOrLossAmount / purchasePrice) * 100;

    final outcome = switch (profitOrLossAmount.compareTo(0)) {
      1 => InvestmentOutcome.profit,
      -1 => InvestmentOutcome.loss,
      _ => InvestmentOutcome.unchanged,
    };

    return InvestmentCalculationResult(
      purchasePrice: purchasePrice,
      currentPrice: currentPrice,
      profitOrLossAmount: profitOrLossAmount,
      returnPercent: returnPercent,
      outcome: outcome,
    );
  }
}
