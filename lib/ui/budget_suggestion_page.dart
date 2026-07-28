import 'package:flutter/material.dart';
import '../data/car_model.dart';
import '../state/app_controller.dart';

class BudgetSuggestionPage extends StatefulWidget {
  const BudgetSuggestionPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<BudgetSuggestionPage> createState() => _BudgetSuggestionPageState();
}

class _BudgetSuggestionPageState extends State<BudgetSuggestionPage> {
  final _budgetController = TextEditingController();
  List<CarModel> _filteredCars = [];

  void _filterCars() {
    final budget = int.tryParse(_budgetController.text.replaceAll(',', ''));
    if (budget == null) {
      setState(() => _filteredCars = []);
      return;
    }
    setState(() {
      _filteredCars = widget.controller.cars
          .where((car) => car.price <= budget)
          .toList()
        ..sort((a, b) => b.price.compareTo(a.price)); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'حداکثر بودجه (تومان)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
            onChanged: (_) => _filterCars(),
          ),
        ),
        Expanded(
          child: _filteredCars.isEmpty
              ? const Center(child: Text('خودرویی با این بودجه یافت نشد.'))
              : ListView.builder(
                  itemCount: _filteredCars.length,
                  itemBuilder: (context, index) {
                    final car = _filteredCars[index];
                    return ListTile(
                      title: Text(car.displayName), 
                      subtitle: Text('${car.price} تومان'),
                      leading: const Icon(Icons.directions_car),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
