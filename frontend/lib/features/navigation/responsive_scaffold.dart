import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/theme_provider.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class ResponsiveScaffold extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final List<NavItem> navItems;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.navItems,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final isTablet = Breakpoints.isTablet(context);
    final isMobile = !isDesktop && !isTablet;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final reportsProvider = context.watch<ReportsProvider>();
    final isDark = themeProvider.isDarkMode;
    final user = auth.user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF13171F) : const Color(0xFFF8FAFC),
      // Mobile Drawer Menu
      drawer: isMobile
          ? Drawer(
              backgroundColor: isDark ? const Color(0xFF161B24) : Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Drawer Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/logo_untidar.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(Icons.school, color: Colors.white, size: 36),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Text(
                                        'UNTIDAR ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'Fixit',
                                        style: GoogleFonts.caveat(
                                          color: const Color(0xFFFDE68A),
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'Universitas Tidar',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'Pengguna',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user?.npm ?? (user?.role == 'admin' ? 'Sarpras' : ''),
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation Items in Drawer
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.navItems.length,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        itemBuilder: (context, index) {
                          final item = widget.navItems[index];
                          final isSelected = widget.currentIndex == index;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              selected: isSelected,
                              selectedTileColor: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEFF6FF),
                              leading: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? const Color(0xFF3B5BDB) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                              title: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onNavigationChanged(index);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Logout in Drawer
                    Divider(height: 1, color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.statusDitolak),
                        title: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(color: AppColors.statusDitolak, fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await auth.logout();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      // Clean & Spacious Topbar (IT-Tools Header Structure with Untidar Identity)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F2B) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Desktop / Mobile Collapse Toggle (Hamburger)
                  IconButton(
                    icon: Icon(
                      _isSidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                      size: 25,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                    tooltip: 'Menu',
                    onPressed: () {
                      if (isDesktop) {
                        setState(() {
                          _isSidebarCollapsed = !_isSidebarCollapsed;
                        });
                      } else {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                  ),

                  const SizedBox(width: 4),

                  // Brand Logo & Stylized Fixit Title
                  InkWell(
                    onTap: () => widget.onNavigationChanged(0),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo_untidar.png',
                              width: isMobile ? 32 : 38,
                              height: isMobile ? 32 : 38,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 30),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'UNTIDAR ',
                                    style: TextStyle(
                                      fontSize: isMobile ? 15.5 : 18.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  Text(
                                    'Fixit',
                                    style: GoogleFonts.caveat(
                                      fontSize: isMobile ? 24 : 28,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2563EB),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (isDesktop) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Pusat Pengaduan & Fasilitas Kampus',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Notification Bell with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 24),
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        tooltip: 'Notifikasi',
                        onPressed: () {
                          if (user?.role == 'mahasiswa') {
                            widget.onNavigationChanged(5);
                          }
                        },
                      ),
                      if (notifProvider.unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.statusDitolak,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${notifProvider.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 4),

                  // User Profile Pill (Compact & zero-overflow in Mobile)
                  if (user != null)
                    PopupMenuButton<String>(
                      offset: const Offset(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) async {
                        if (val == 'logout') {
                          await auth.logout();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 11.5)),
                              const SizedBox(height: 4),
                              Text('Role: ${user.role.toUpperCase()}', style: const TextStyle(color: Color(0xFF3B5BDB), fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 18, color: AppColors.statusDitolak),
                              SizedBox(width: 8),
                              Text('Keluar', style: TextStyle(color: AppColors.statusDitolak)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF13171F) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C3548) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color(0xFF1E3A8A),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    user.npm ?? "Sarpras Untidar",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          // Clean Left Sidebar without redundant top banner
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isSidebarCollapsed ? 76 : 240,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B24) : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Menu Items (Grouped like IT-Tools)
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.navItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      itemBuilder: (context, index) {
                        final item = widget.navItems[index];
                        final isSelected = widget.currentIndex == index;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2.5),
                          child: InkWell(
                            onTap: () => widget.onNavigationChanged(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEFF6FF))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3B5BDB)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 19,
                                    color: isSelected
                                        ? const Color(0xFF3B5BDB)
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                  if (!_isSidebarCollapsed) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
                                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ),
                                    // Count badge for My Reports
                                    if (index == 4 && reportsProvider.myReports.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B5BDB),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${reportsProvider.myReports.length}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Logout
                  Divider(height: 1, color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const Icon(Icons.logout_rounded, color: AppColors.statusDitolak, size: 20),
                      title: _isSidebarCollapsed
                          ? null
                          : const Text(
                              'Keluar',
                              style: TextStyle(color: AppColors.statusDitolak, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                      onTap: () async {
                        await auth.logout();
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Tablet NavigationRail
          if (isTablet)
            NavigationRail(
              backgroundColor: isDark ? const Color(0xFF161B24) : Colors.white,
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onNavigationChanged,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFF3B5BDB)),
              unselectedIconTheme: IconThemeData(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
              selectedLabelTextStyle: const TextStyle(color: Color(0xFF3B5BDB), fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 11),
              destinations: widget.navItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                );
              }).toList(),
            ),

          // Main Content Area
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: Breakpoints.contentMaxWidth(context),
                ),
                child: widget.body,
              ),
            ),
          ),
        ],
      ),
      // Mobile BottomNavigationBar (Icon Only, Clean & Modern without overflowing text labels)
      bottomNavigationBar: !isDesktop && !isTablet
          ? Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B24) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: widget.currentIndex >= widget.navItems.length ? 0 : widget.currentIndex,
                onTap: widget.onNavigationChanged,
                type: BottomNavigationBarType.fixed,
                backgroundColor: isDark ? const Color(0xFF161B24) : Colors.white,
                selectedItemColor: const Color(0xFF3B5BDB),
                unselectedItemColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                showSelectedLabels: false,
                showUnselectedLabels: false,
                iconSize: 26,
                elevation: 0,
                items: widget.navItems.map((item) {
                  return BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Icon(item.icon),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.activeIcon, color: const Color(0xFF3B5BDB)),
                    ),
                    label: '',
                    tooltip: item.label,
                  );
                }).toList(),
              ),
            )
          : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
