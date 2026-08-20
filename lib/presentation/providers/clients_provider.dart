import 'package:flutter/material.dart';

class ClientRecord {
  final String id;
  final String name;
  final String type;
  final double balance;

  const ClientRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });
}

class ClientsProvider extends ChangeNotifier {
  final List<ClientRecord> _items = const [
    ClientRecord(id: 'C-01', name: 'Mme Adjoua T.', type: 'Détaillante', balance: 125000),
    ClientRecord(id: 'C-02', name: 'Akon Market', type: 'Grossiste', balance: 50000),
    ClientRecord(id: 'C-03', name: 'Restaurant K', type: 'Restaurant', balance: 80000),
  ];

  List<ClientRecord> get items => List.unmodifiable(_items);

  double get totalReceivables => _items.fold(0, (sum, item) => sum + item.balance);

  void addClient(ClientRecord client) {
    notifyListeners();
  }
}
