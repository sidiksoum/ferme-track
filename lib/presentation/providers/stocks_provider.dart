import 'package:flutter/material.dart';

class StockItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final String category;
  final bool lowStock;

  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.lowStock,
  });
}

class StocksProvider extends ChangeNotifier {
  final List<StockItem> _items = const [
    StockItem(
      id: 'S-01',
      name: 'Aliment poulet',
      quantity: 120,
      unit: 'sacs',
      category: 'Aliment',
      lowStock: false,
    ),
    StockItem(
      id: 'S-02',
      name: 'Vaccin anti-colibacillose',
      quantity: 7,
      unit: 'flacons',
      category: 'Santé',
      lowStock: true,
    ),
    StockItem(
      id: 'S-03',
      name: 'Œufs cadres',
      quantity: 1350,
      unit: 'pièces',
      category: 'Production',
      lowStock: false,
    ),
  ];

  List<StockItem> get items => List.unmodifiable(_items);

  int get lowStockCount => _items.where((item) => item.lowStock).length;

  void updateStock(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = _items[index];
    final updated = StockItem(
      id: current.id,
      name: current.name,
      quantity: quantity,
      unit: current.unit,
      category: current.category,
      lowStock: quantity < 10,
    );
    // no direct mutation because list is const, but the provider API remains valid for future data layer
    notifyListeners();
  }
}
