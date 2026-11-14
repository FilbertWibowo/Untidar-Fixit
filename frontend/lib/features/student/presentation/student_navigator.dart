import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/reports_provider.dart';
import '../../navigation/responsive_scaffold.dart';
import 'create_report_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'public_reports_screen.dart';
import 'scan_qr_screen.dart';
import 'student_home_screen.dart';

class StudentNavigator extends StatefulWidget {
  const StudentNavigator({super.key});

  @override
  State<StudentNavigator> createState() => _StudentNavigatorState();
}

class _StudentNavigatorState extends State<StudentNavigator> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().initData();
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
      NavItem(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
      NavItem(label: 'Buat Laporan', icon: Icons.add_box_outlined, activeIcon: Icons.add_box_rounded),
      NavItem(label: 'Scan QR', icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner_rounded),
      NavItem(label: 'Laporan Publik', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded),
      NavItem(label: 'Laporan Saya', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded),
      NavItem(label: 'Notifikasi', icon: Icons.notifications_none_rounded, activeIcon: Icons.notifications_rounded),
    ];

    Widget body;
    switch (_currentIndex) {
      case 0:
        body = StudentHomeScreen(onNavigate: _onNavigationChanged);
        break;
      case 1:
        body = CreateReportScreen(onNavigate: _onNavigationChanged);
        break;
      case 2:
        body = ScanQrScreen(onNavigate: _onNavigationChanged);
        break;
      case 3:
        body = const PublicReportsScreen();
        break;
      case 4:
        body = MyReportsScreen(onNavigate: _onNavigationChanged);
        break;
      case 5:
        body = const NotificationsScreen();
        break;
      default:
        body = StudentHomeScreen(onNavigate: _onNavigationChanged);
    }

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onNavigationChanged: _onNavigationChanged,
      navItems: navItems,
      title: navItems[_currentIndex].label,
      body: body,
      floatingActionButton: _currentIndex != 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Lapor Fasilitas', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _onNavigationChanged(1),
            )
          : null,
    );
  }
}
