import 'package:flutter/material.dart';

class AppColors {
  // Official Untidar Academic Portal Colors (Elita Inspired)
  static const Color headerBlue = Color(0xFF3B5BDB);     // Elita Topbar Blue
  static const Color headerBlueDark = Color(0xFF2B44B8); // Deeper header shade
  static const Color primary = Color(0xFF1E3A8A);        // Untidar Deep Blue #1e3a8a
  static const Color secondary = Color(0xFF3B5BDB);      // Primary UI Blue
  static const Color accent = Color(0xFF3B5BDB);         // Interactive Accent
  static const Color accentGold = Color(0xFFD97706);     // Untidar Eagle Gold
  static const Color creamAccent = Color(0xFFF5E8C7);    // Untidar Cream #f5e8c7

  // Sidebar Colors (Elita Dark Slate Sidebar)
  static const Color sidebarBg = Color(0xFF1B2431);      // Dark Charcoal / Slate
  static const Color sidebarActive = Color(0xFF2C394E);  // Active menu item
  static const Color sidebarHover = Color(0xFF222D3D);
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // Background & Surfaces
  static const Color bgLight = Color(0xFFF0F4F8);        // Soft academic light gray
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFE8EEF8);         // Light blue-tinted input box
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Complaint Status Colors
  static const Color statusTerkirim = Color(0xFF2563EB);     // Blue
  static const Color statusDiverifikasi = Color(0xFF7C3AED); // Purple
  static const Color statusDitugaskan = Color(0xFFD97706);   // Amber
  static const Color statusSelesai = Color(0xFF16A34A);      // Green
  static const Color statusDitolak = Color(0xFFDC2626);      // Red

  // Priority Colors
  static const Color priorityLow = Color(0xFF16A34A);
  static const Color priorityMedium = Color(0xFFD97706);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityCritical = Color(0xFFDC2626);

  // Heatmap Indicators
  static const Color heatmapSafe = Color(0xFF16A34A);
  static const Color heatmapModerate = Color(0xFFD97706);
  static const Color heatmapCritical = Color(0xFFDC2626);

  // Category Banner Colors (For Elita-style course/card banners)
  static const List<Color> categoryBannerColors = [
    Color(0xFF3B82F6), // Blue (AC)
    Color(0xFFF97316), // Orange (Listrik)
    Color(0xFF10B981), // Teal (Air)
    Color(0xFF8B5CF6), // Purple (WiFi)
    Color(0xFFEC4899), // Pink (Furnitur)
    Color(0xFF06B6D4), // Cyan (Kebersihan)
    Color(0xFF6366F1), // Indigo (Keamanan)
    Color(0xFFF59E0B), // Amber (Proyektor)
  ];
}
