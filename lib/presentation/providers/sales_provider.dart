import 'package:flutter/material.dart';

class SaleTransaction {
  final String id;
  final String customer;
  final String product;
  final double amount;
  final bool isCash;

  const SaleTransaction({
    required this.id,
    required this.customer,
    required this.product,
    required this.amount,
    required this.isCash,
  });
}

class SalesProvider extends ChangeNotifier {
  final List<SaleTransaction> _items = const [
    SaleTransaction(
      id: 'V-01',
      customer: 'Mme Adjoua',
      product: 'Plateau d’œufs',
      amount: 1800,
      isCash: true,
    ),
    SaleTransaction(
      id: 'V-02',
      customer: 'Akon Market',
      product: 'Alvéole (30)',
      amount: 2500,
      isCash: false,
    ),
  ];

  List<SaleTransaction> get items => List.unmodifiable(_items);

  double get dailyTotal => _items.fold(0, (sum, item) => sum + item.amount);

  void addSale(SaleTransaction sale) {
    notifyListeners();
  }
}
