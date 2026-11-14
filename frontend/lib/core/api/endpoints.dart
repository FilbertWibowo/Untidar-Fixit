import 'package:flutter/foundation.dart';

class Endpoints {
  // Dynamically adapt between local development and production aaPanel (untidar-fixit.duckdns.org)
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      // If running locally in browser (any port: 5000, 8000, random debug port)
      if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
        return 'http://127.0.0.1:8000/api';
      }
      // On aaPanel or web deployment, match the exact browser origin (http or https)
      if (Uri.base.origin.isNotEmpty && !Uri.base.origin.startsWith('null')) {
        return '${Uri.base.origin}/api';
      }
      return 'https://untidar-fixit.duckdns.org/api';
    }
    // Mobile Android APK connects to the live production domain
    return 'https://untidar-fixit.duckdns.org/api';
  }

  static String get uploadsBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
        return 'http://127.0.0.1:8000/';
      }
      if (Uri.base.origin.isNotEmpty && !Uri.base.origin.startsWith('null')) {
        return '${Uri.base.origin}/';
      }
      return 'https://untidar-fixit.duckdns.org/';
    }
    return 'https://untidar-fixit.duckdns.org/';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Locations & Categories
  static const String locations = '/locations';
  static const String resolveQr = '/locations/resolve';
  static const String categories = '/categories';

  // Reports
  static const String reports = '/reports';
  static const String myReports = '/reports/mine';
  static const String similarReports = '/reports/similar';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminExport = '/admin/export';
  static const String adminTechnicians = '/admin/technicians';
  static const String adminUsers = '/admin/users';
  static const String adminAuditLogs = '/admin/audit-logs';

  // Notifications
  static const String notifications = '/notifications';
}
