import 'package:flutter/material.dart';

import '../data/car_model.dart';
import '../state/app_controller.dart';

class InvestmentPage extends StatefulWidget {
  const InvestmentPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  CarModel? _selectedCar;
  final _purchasePriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cars = widget.controller.cars;
    if (cars.isNotEmpty) {
      _selectedCar = cars.first;
    }
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    super.dispose();
  }

  int? get _purchasePrice {
    final text = _purchasePriceController.text.trim().replaceAll(',', '');
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  int? get _currentPrice => _selectedCar?.price;

  int? get _profit {
    final purchase = _purchasePrice;
    final current = _currentPrice;
    if (purchase == null || current == null) return null;
    return current - purchase;
  }

  double? get _roiPercent {
    final purchase = _purchasePrice;
    final profit = _profit;
    if (purchase == null || profit == null || purchase == 0) return null;
    return (profit / purchase) * 100;
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  String _formatPercent(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cars = widget.controller.cars;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'صفحه سرمایه‌گذاری',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<CarModel>(
            initialValue: _selectedCar,
            items: cars
                .map(
                  (car) => DropdownMenuItem<CarModel>(
                    value: car,
                    child: Text(car.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCar = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'انتخاب خودرو',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          if (_selectedCar != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCar!.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قیمت فعلی: ${_formatNumber(_selectedCar!.price)} تومان',
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _purchasePriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'قیمت خرید',
              hintText: 'مثلاً 1200000000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _selectedCar == null || _purchasePrice == null
                ? null
                : () => setState(() {}),
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('محاسبه سود / زیان'),
          ),

          const SizedBox(height: 16),

          if (_selectedCar != null && _purchasePrice != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(
                      title: 'قیمت خرید',
                      value: '${_formatNumber(_purchasePrice!)} تومان',
                    ),
                    const SizedBox(height: 8),
                    _ResultRow(
                      title: 'قیمت فعلی',
                      value: '${_formatNumber(_selectedCar!.price)} تومان',
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      title: 'سود / زیان',
                      value: '${_formatNumber(_profit!)} تومان',
                      valueColor: _profit! >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _ResultRow(
                      title: 'ROI',
                      value: '${_formatPercent(_roiPercent ?? 0)}%',
                      valueColor: _profit! >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.value,
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
