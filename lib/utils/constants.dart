import 'package:flutter/material.dart';

// ===================== APP COLORS =====================
class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color transfer = Color(0xFF3B82F6);
  static const Color pending = Color(0xFFF59E0B);

  static const Color darkBg = Color(0xFF020617); // slate-950
  static const Color darkSurface = Color(0xFF0F172A); // slate-900
  static const Color darkCard = Color(0xFF1E293B); // slate-800

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;

  static const List<Color> chart = [
    Color(0xFF7C3AED),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];
}

// ===================== DEFAULT DATA =====================
class DefaultData {
  static const List<Map<String, dynamic>> accounts = [
    {
      'id': 'vodafone',
      'name': 'فودافون كاش',
      'currency': 'EGP',
      'icon': '📱',
      'colors': ['#E60000', '#990000'],
    },
    {
      'id': 'instapay',
      'name': 'إنستاباي',
      'currency': 'EGP',
      'icon': '⚡',
      'colors': ['#6D28D9', '#4C1D95'],
    },
    {
      'id': 'dollar',
      'name': 'حساب الدولار',
      'currency': 'USD',
      'icon': '💵',
      'colors': ['#10B981', '#047857'],
    },
    {
      'id': 'cash',
      'name': 'كاش معانا',
      'currency': 'EGP',
      'icon': '💰',
      'colors': ['#F59E0B', '#B45309'],
    },
  ];

  static const List<String> categories = [
    'رواتب',
    'إعلانات',
    'مشتريات',
    'إيجار',
    'تحويلات',
    'أخرى',
  ];

  static const double defaultDollarRate = 50.0;
}
