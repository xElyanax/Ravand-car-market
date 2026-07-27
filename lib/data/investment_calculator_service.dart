class InvestmentResult {
  final String carName;
  final DateTime purchaseDate;
  final int purchasePrice;
  final int currentPrice;
  final int profitLoss;
  final double roiPercent;

  const InvestmentResult({
    required this.carName,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.currentPrice,
    required this.profitLoss,
    required this.roiPercent,
  });

  bool get isProfit => profitLoss >= 0;
}

class InvestmentCalculatorService {
  const InvestmentCalculatorService();

  InvestmentResult calculate({
    required String carName,
    required DateTime purchaseDate,
    required int purchasePrice,
    required int currentPrice,
  }) {
    final profitLoss = currentPrice - purchasePrice;
    final roiPercent = purchasePrice == 0
        ? 0.0
        : (profitLoss / purchasePrice) * 100.0;

    return InvestmentResult(
      carName: carName,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      currentPrice: currentPrice,
      profitLoss: profitLoss,
      roiPercent: roiPercent,
    );
  }

  /// اگر خودرو history قیمت داشته باشد، آخرین قیمت قبل/تا تاریخ خرید را پیدا می‌کند.
  /// اگر history خالی باشد، null برمی‌گرداند.
  int? findPriceAtDate(List<dynamic> priceHistory, DateTime targetDate) {
    if (priceHistory.isEmpty) return null;

    // انتظار: هر آیتم حداقل دو فیلد date و price داشته باشد.
    // اگر در مدل شما نام فیلدها فرق دارد، فقط این بخش را با مدل خودتان هماهنگ کنید.
    int? bestPrice;
    DateTime? bestDate;

    for (final item in priceHistory) {
      try {
        final date = item.date as DateTime;
        final price = item.price as int;

        if (date.isAfter(targetDate)) continue;

        if (bestDate == null || date.isAfter(bestDate)) {
          bestDate = date;
          bestPrice = price;
        }
      } catch (_) {
        // ignore invalid item
      }
    }

    return bestPrice;
  }

  /// fallback ساده برای زمانی که currentPrice را از یک قیمت آخر می‌خواهی
  int latestPriceFromHistory(List<dynamic> priceHistory) {
    if (priceHistory.isEmpty) return 0;

    dynamic latest = priceHistory.first;
    for (final item in priceHistory) {
      try {
        final a = item.date as DateTime;
        final b = latest.date as DateTime;
        if (a.isAfter(b)) latest = item;
      } catch (_) {}
    }

    try {
      return latest.price as int;
    } catch (_) {
      return 0;
    }
  }
}
