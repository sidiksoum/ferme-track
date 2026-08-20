import 'package:flutter/material.dart';

class BuildingSummary {
  final String id;
  final String name;
  final int birds;
  final int eggsPerDay;
  final double mortalityRate;
  final String state;

  const BuildingSummary({
    required this.id,
    required this.name,
    required this.birds,
    required this.eggsPerDay,
    required this.mortalityRate,
    required this.state,
  });
}

class BuildingsProvider extends ChangeNotifier {
  final List<BuildingSummary> _items = const [
    BuildingSummary(
      id: 'B-01',
      name: 'Bâtiment A',
      birds: 3400,
      eggsPerDay: 2850,
      mortalityRate: 0.3,
      state: 'Stable',
    ),
    BuildingSummary(
      id: 'B-02',
      name: 'Bâtiment B',
      birds: 2650,
      eggsPerDay: 2100,
      mortalityRate: 0.5,
      state: 'À surveiller',
    ),
    BuildingSummary(
      id: 'B-03',
      name: 'Bâtiment C',
      birds: 2280,
      eggsPerDay: 1700,
      mortalityRate: 0.7,
      state: 'Alert',
    ),
  ];

  List<BuildingSummary> get items => List.unmodifiable(_items);

  void addBuilding(BuildingSummary building) {
    // no-op in mock, but keeps provider API valid
    notifyListeners();
  }
}
