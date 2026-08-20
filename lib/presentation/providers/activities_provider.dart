import 'package:flutter/material.dart';

class ActivityItem {
  final String id;
  final String title;
  final String building;
  final String date;
  final String time;
  final String status;
  final String priority;
  final String responsible;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.building,
    required this.date,
    required this.time,
    required this.status,
    required this.priority,
    required this.responsible,
  });
}

class ActivitiesProvider extends ChangeNotifier {
  final List<ActivityItem> _items = [
    const ActivityItem(
      id: 'A-101',
      title: 'Distribution d’aliment',
      building: 'Bâtiment A',
      date: '2026-01-21',
      time: '06:30',
      status: 'todo',
      priority: 'high',
      responsible: 'Ama Koffi',
    ),
    const ActivityItem(
      id: 'A-102',
      title: 'Vaccination Lot L-2026-011',
      building: 'Bâtiment A',
      date: '2026-01-21',
      time: '09:00',
      status: 'in_progress',
      priority: 'medium',
      responsible: 'B. N’Guessan',
    ),
    const ActivityItem(
      id: 'A-103',
      title: 'Contrôle hygiène',
      building: 'Bâtiment C',
      date: '2026-01-21',
      time: '12:15',
      status: 'done',
      priority: 'low',
      responsible: 'K. Yao',
    ),
  ];

  List<ActivityItem> get items => List.unmodifiable(_items);

  List<ActivityItem> byBuilding(String buildingFilter) {
    if (buildingFilter == 'all') return items;
    return _items.where((activity) => activity.building == buildingFilter).toList();
  }

  void addActivity(ActivityItem activity) {
    _items.add(activity);
    notifyListeners();
  }

  void updateStatus(String id, String status) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index] = ActivityItem(
      id: _items[index].id,
      title: _items[index].title,
      building: _items[index].building,
      date: _items[index].date,
      time: _items[index].time,
      status: status,
      priority: _items[index].priority,
      responsible: _items[index].responsible,
    );
    notifyListeners();
  }
}
