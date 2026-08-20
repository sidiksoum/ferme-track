import 'package:flutter/material.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
  });
}

class NotificationsProvider extends ChangeNotifier {
  final List<AppNotificationItem> _items = const [
    AppNotificationItem(
      id: 'N-01',
      title: 'Rupture d’aliments',
      message: 'Stock à 4 % — réapprovisionnement requis',
      type: 'stock_rupture',
      read: false,
    ),
    AppNotificationItem(
      id: 'N-02',
      title: 'Échéance client',
      message: '2 comptes à échéance sous 3 jours',
      type: 'payment_due',
      read: false,
    ),
  ];

  List<AppNotificationItem> get items => List.unmodifiable(_items);

  void markAsRead(String id) {
    notifyListeners();
  }
}
