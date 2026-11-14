import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../navigation/responsive_scaffold.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_locations_screen.dart';
import 'admin_queue_screen.dart';
import 'admin_stats_export_screen.dart';
import 'admin_technicians_screen.dart';
import 'admin_users_screen.dart';

class AdminNavigator extends StatefulWidget {
  const AdminNavigator({super.key});

  @override
  State<AdminNavigator> createState() => _AdminNavigatorState();
}

class _AdminNavigatorState extends State<AdminNavigator> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AdminProvider>();
      p.fetchDashboardStats();
      p.fetchReportQueue();
      p.fetchLocations();
      p.fetchTechnicians();
    });
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navItems = const [
      NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
      NavItem(label: 'Antrian Laporan', icon: Icons.format_list_bulleted_rounded, activeIcon: Icons.format_list_bulleted_rounded),
      NavItem(label: 'Lokasi & QR', icon: Icons.qr_code_2_outlined, activeIcon: Icons.qr_code_2_rounded),
      NavItem(label: 'Data Teknisi', icon: Icons.handyman_outlined, activeIcon: Icons.handyman_rounded),
      NavItem(label: 'Statistik & Ekspor', icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded),
      NavItem(label: 'Log Aktivitas', icon: Icons.security_outlined, activeIcon: Icons.security_rounded),
      NavItem(label: 'Kelola Pengguna', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded),
    ];

    Widget body;
    switch (_currentIndex) {
      case 0:
        body = AdminDashboardScreen(onNavigate: _onNavigationChanged);
        break;
      case 1:
        body = const AdminQueueScreen();
        break;
      case 2:
        body = const AdminLocationsScreen();
        break;
      case 3:
        body = const AdminTechniciansScreen();
        break;
      case 4:
        body = const AdminStatsExportScreen();
        break;
      case 5:
        body = const AdminAuditLogsScreen();
        break;
      case 6:
        body = const AdminUsersScreen();
        break;
      default:
        body = AdminDashboardScreen(onNavigate: _onNavigationChanged);
    }

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onNavigationChanged: _onNavigationChanged,
      navItems: navItems,
      title: navItems[_currentIndex].label,
      body: body,
    );
  }
}
