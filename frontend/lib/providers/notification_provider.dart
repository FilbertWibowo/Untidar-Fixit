import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../shared/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get(Endpoints.notifications);
      final list = res.data['data']['notifications'] as List;
      _notifications = list.map((n) => NotificationModel.fromJson(n)).toList();
      _unreadCount = res.data['data']['unread_count'] ?? 0;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.dio.patch('/notifications/$id/read');
      final notif = _notifications.firstWhere((n) => n.id == id);
      if (!notif.isRead) {
        notif.isRead = true;
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.dio.patch('/notifications/read-all');
      for (var n in _notifications) {
        n.isRead = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
