import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0; // 0: تحليلات, 1: تقارير

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'كل الأوقات';
  String _filterAccount = 'all';
  String _filterCategory = 'all';
  String _logSearchQuery = '';
  String _logFilterType = 'all'; // all, income, expense, transfer, delete

  final List<Color> _expenseColors = const [
    Color(0xFF7C3AED), // موف
    Color(0xFF00B0FF), // أزرق
    Color(0xFFFF9100), // برتقالي
    Color(0xFF00E676), // أخضر
    Color(0xFFFF1744), // أحمر
    Color(0xFFF50057), // وردي
    Color(0xFF00BFA5), // تيل
  ];

  final List<Color> _incomeColors = const [
    Color(0xFF00E676), // أخضر
    Color(0xFF00B0FF), // أزرق ساطع
    Color(0xFFFF9100), // برتقالي
    Color(0xFFE040FB), // بنفسجي
    Color(0xFFFF4081), // وردي
    Color(0xFFFFD600), // أصفر
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    final filteredTxs = app.transactions.where((tx) {
      if (_startDate != null && tx.date.isBefore(_startDate!)) return false;
      if (_endDate != null && tx.date.isAfter(_endDate!)) return false;
      if (_filterAccount != 'all' &&
          tx.accountId != _filterAccount &&
          tx.toAccountId != _filterAccount) {
        return false;
      }
      if (_filterCategory != 'all' && tx.category != _filterCategory) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Tabs Switcher
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: dark ? Colors.black.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color:
                      dark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                _buildTabButton('📊 التحليلات', 0, dark),
                _buildTabButton('📑 التقارير', 1, dark),
                _buildTabButton('📜 السجل', 2, dark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedTab != 2) ...[
            Text('الفلاتر المتقدمة 🎯',
                style: GoogleFonts.cairo(
                    color: dark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildFilterButton(),
                  const SizedBox(width: 8),
                  _buildDropdownFilter(
                    value: _filterAccount,
                    items: ['all', ...app.accounts.map((a) => a.id)],
                    labels: [
                      '🏦 كل الحسابات',
                      ...app.accounts.map((a) => '🏦 ${a.name}')
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        Provider.of<AppProvider>(context, listen: false)
                            .playClick();
                        setState(() => _filterAccount = v);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownFilter(
                    value: _filterCategory,
                    items: ['all', ...app.categories],
                    labels: [
                      '🛒 كل الفئات',
                      ...app.categories
                          .map((c) => '🛒 ${CategoryData.parse(c).name}')
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        Provider.of<AppProvider>(context, listen: false)
                            .playClick();
                        setState(() => _filterCategory = v);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_startDate != null && _endDate != null)
              Container(
                margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.5)),
                ),
                child: Text(
                  'من ${DateFormat('yyyy/MM/dd').format(_startDate!)} إلى ${DateFormat('yyyy/MM/dd').format(_endDate!)}',
                  style: GoogleFonts.cairo(
                      color: const Color(0xFFD8B4FE),
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            child: _selectedTab == 0
                ? KeyedSubtree(
                    key: const ValueKey(0),
                    child: _buildAnalyticsView(app, dark, filteredTxs))
                : _selectedTab == 1
                    ? KeyedSubtree(
                        key: const ValueKey(1),
                        child: _buildReportsView(app, dark, filteredTxs))
                    : KeyedSubtree(
                        key: const ValueKey(2),
                        child: _buildLogsView(app, dark)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          dropdownColor: const Color(0xFF4C1D95),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 20),
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          items: [
            'كل الأوقات',
            'اليوم',
            'هذا الأسبوع',
            'هذا الشهر',
            'الشهر الماضي',
            'فترة مخصصة'
          ].asMap().entries.map((entry) {
            final isLast = entry.key == 5;
            return DropdownMenuItem(
              value: entry.value,
              child: Container(
                width: 110,
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2), width: 1)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(entry.value),
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return [
              '📅 كل الأوقات',
              '📅 اليوم',
              '📅 هذا الأسبوع',
              '📅 هذا الشهر',
              '📅 الشهر الماضي',
              '📅 فترة مخصصة'
            ]
                .map((e) =>
                    Container(alignment: Alignment.centerRight, child: Text(e)))
                .toList();
          },
          onChanged: (v) async {
            Provider.of<AppProvider>(context, listen: false).playClick();
            if (v == null) return;
            DateTime now = DateTime.now();
            DateTime? start;
            DateTime? end;
            if (v == 'اليوم') {
              start = DateTime(now.year, now.month, now.day);
              end = DateTime(now.year, now.month, now.day, 23, 59, 59);
            } else if (v == 'هذا الأسبوع') {
              start = DateTime(now.year, now.month, now.day)
                  .subtract(Duration(days: now.weekday - 1));
              end = DateTime(now.year, now.month, now.day, 23, 59, 59);
            } else if (v == 'هذا الشهر') {
              start = DateTime(now.year, now.month, 1);
              end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            } else if (v == 'الشهر الماضي') {
              start = DateTime(now.year, now.month - 1, 1);
              end = DateTime(now.year, now.month, 0, 23, 59, 59);
            } else if (v == 'فترة مخصصة') {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF7C3AED), // اللون الأساسي للتحديد
                        onPrimary: Colors.white, // لون النص فوق التحديد
                        surface:
                            Color(0xFF2E1065), // خلفية النتيجة (موف غامق جداً)
                        onSurface: Colors.white, // لون النص العادي
                      ), // خلفية النافذة المنبثقة
                      scaffoldBackgroundColor: const Color(
                          0xFF2E1065), // خلفية الشاشة الكاملة للتقويم
                      appBarTheme: const AppBarTheme(
                        backgroundColor:
                            Color(0xFF4C1D95), // لون شريط العنوان العلوي
                        foregroundColor: Colors.white,
                        iconTheme: IconThemeData(color: Colors.white),
                      ),
                      dialogTheme: const DialogThemeData(
                          backgroundColor: Color(0xFF2E1065)),
                      datePickerTheme: DatePickerThemeData(
                        cancelButtonStyle: TextButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFF1744).withOpacity(0.15),
                          foregroundColor: const Color(0xFFFF1744),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        confirmButtonStyle: TextButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF00E676).withOpacity(0.15),
                          foregroundColor: const Color(0xFF00E676),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                start = picked.start;
                end = DateTime(picked.end.year, picked.end.month,
                    picked.end.day, 23, 59, 59);
              } else {
                return;
              }
            }
            setState(() {
              _selectedPeriod = v;
              _startDate = start;
              _endDate = end;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required List<String> labels,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF4C1D95),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 20),
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          items: items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return DropdownMenuItem(
              value: entry.value,
              child: Container(
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1))),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(labels[entry.key]),
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return labels
                .map((e) =>
                    Container(alignment: Alignment.centerRight, child: Text(e)))
                .toList();
          },
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, bool dark) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Provider.of<AppProvider>(context, listen: false).playClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? null : Colors.transparent,
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  active ? Colors.white.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: active
                      ? const Color(0xFF7C3AED).withOpacity(0.6)
                      : Colors.transparent,
                  blurRadius: active ? 16.0 : 0.0,
                  offset: active ? const Offset(0, 6) : Offset.zero)
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                color: active
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.black54),
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                fontSize: 16,
                shadows: active
                    ? [
                        Shadow(
                            color: Colors.black.withOpacity(0.3), blurRadius: 4)
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsView(
      AppProvider app, bool dark, List<Transaction> filteredTxs) {
    final expenses =
        filteredTxs.where((t) => t.isExpense && t.isCountable).toList();
    final incomes =
        filteredTxs.where((t) => t.isIncome && t.isCountable).toList();
    final transfers =
        filteredTxs.where((t) => t.isTransfer && t.isCountable).toList();

    // توحيد كل المعاملات للعملة الأساسية لكي يتم حساب الإجماليات بدقة
    double getInAppCurrency(Transaction t) {
      final acc = app.accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => app.accounts.first);
      return app.convertCurrency(t.amount, acc.currency, app.appCurrency);
    }

    final filteredTotalIncome =
        incomes.fold(0.0, (s, t) => s + getInAppCurrency(t));
    final filteredTotalExpense =
        expenses.fold(0.0, (s, t) => s + getInAppCurrency(t));
    final totalTransfer =
        transfers.fold(0.0, (s, t) => s + getInAppCurrency(t));

    if (expenses.isEmpty && incomes.isEmpty) {
      return _buildEmptyState('لا توجد بيانات كافية للتحليل حالياً');
    }

    final Map<String, double> expenseData = {};
    final Map<String, CategoryData> expenseCats = {};
    for (var tx in expenses) {
      if (tx.amount > 0) {
        final catData = CategoryData.parse(tx.category);
        final catName = catData.name;
        expenseData[catName] =
            (expenseData[catName] ?? 0) + getInAppCurrency(tx);
        expenseCats[catName] = catData;
      }
    }
    final sortedExpenses = expenseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, double> incomeData = {};
    final Map<String, CategoryData> incomeCats = {};
    for (var tx in incomes) {
      if (tx.amount > 0) {
        final catData = CategoryData.parse(tx.category);
        final catName = catData.name;
        incomeData[catName] = (incomeData[catName] ?? 0) + getInAppCurrency(tx);
        incomeCats[catName] = catData;
      }
    }
    final sortedIncomes = incomeData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: _buildSummaryMiniCard(
                      'الدخل',
                      filteredTotalIncome,
                      app.appCurrencySymbol,
                      const Color(0xFF00E676),
                      const Color(0xFF00C853),
                      '⬆️')),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildSummaryMiniCard(
                      'المصروف',
                      filteredTotalExpense,
                      app.appCurrencySymbol,
                      const Color(0xFFFF1744),
                      const Color(0xFFD50000),
                      '⬇️')),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildSummaryMiniCard(
                      'التحويلات',
                      totalTransfer,
                      app.appCurrencySymbol,
                      const Color(0xFF00B0FF),
                      const Color(0xFF0091EA),
                      '↔️')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (sortedExpenses.isNotEmpty) ...[
          _buildAIInsightCard(sortedExpenses.first.key,
              sortedExpenses.first.value, filteredTotalExpense, dark),
          Text('تحليل المصروفات 🍩',
              style: GoogleFonts.cairo(
                  color: dark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _DonutChartWidget(
            dark: dark,
            app: app,
            data: sortedExpenses,
            catDataMap: expenseCats,
            total: filteredTotalExpense,
            colors: _expenseColors,
          ),
          const SizedBox(height: 32),
        ],
        if (sortedIncomes.isNotEmpty) ...[
          Text('تحليل مصادر الدخل 💰',
              style: GoogleFonts.cairo(
                  color: dark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _DonutChartWidget(
            dark: dark,
            app: app,
            data: sortedIncomes,
            catDataMap: incomeCats,
            total: filteredTotalIncome,
            colors: _incomeColors,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryMiniCard(String title, double amount, String currency,
      Color color1, Color color2, String icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color1.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 0,
              spreadRadius: 1,
              offset: const Offset(1, 1)) // 3D bevel
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            bottom: -10,
            child: Opacity(
                opacity: 0.3,
                child: Text(icon, style: const TextStyle(fontSize: 45))),
          ),
          // Glass reflection
          Positioned(
            top: -15,
            left: -15,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(icon, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatNumber(amount),
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 10)
                          ]),
                    ),
                    const SizedBox(width: 4),
                    Text(currency,
                        style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard(
      String category, double amount, double totalExpense, bool dark) {
    final pct = totalExpense > 0
        ? ((amount / totalExpense) * 100).toStringAsFixed(1)
        : '0';
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7C3AED).withOpacity(0.15),
              const Color(0xFF4C1D95).withOpacity(0.15)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF7C3AED).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5)),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المحلل الذكي (AI)',
                    style: GoogleFonts.cairo(
                        color: dark
                            ? const Color(0xFFD8B4FE)
                            : const Color(0xFF6D28D9),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'أعلى سحب للأموال كان في قسم "$category" ويمثل %$pct من إجمالي مصروفاتك.',
                  style: GoogleFonts.cairo(
                      color: dark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView(
      AppProvider app, bool dark, List<Transaction> filteredTxs) {
    final Map<String, Map<String, double>> monthlyData = {};

    double getInAppCurrency(Transaction t) {
      final acc = app.accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => app.accounts.first);
      return app.convertCurrency(t.amount, acc.currency, app.appCurrency);
    }

    final arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    for (var tx in filteredTxs.where((t) => t.isCountable)) {
      // تفادي انهيار التطبيق في حال لم يتم تهيئة حزمة intl للغة العربية
      final monthKey = '${arabicMonths[tx.date.month - 1]} ${tx.date.year}';
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'income': 0.0,
          'expense': 0.0,
          'transfer': 0.0
        };
      }
      final amountInAppCurrency = getInAppCurrency(tx);
      if (tx.isIncome) {
        monthlyData[monthKey]!['income'] =
            monthlyData[monthKey]!['income']! + amountInAppCurrency;
      } else if (tx.isExpense)
        monthlyData[monthKey]!['expense'] =
            monthlyData[monthKey]!['expense']! + amountInAppCurrency;
      else
        monthlyData[monthKey]!['transfer'] =
            monthlyData[monthKey]!['transfer']! + amountInAppCurrency;
    }

    if (monthlyData.isEmpty) {
      return _buildEmptyState('لا توجد تقارير متاحة حالياً');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    app.playClick();
                    _exportPDF(app, filteredTxs);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.white, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('تصدير PDF',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900)),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    app.playClick();
                    _exportExcel(app, filteredTxs);
                  },
                  icon: const Icon(Icons.table_chart_rounded,
                      color: Colors.white, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('تصدير Excel',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900)),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('التقارير الشهرية 📆',
            style: GoogleFonts.cairo(
                color: dark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ...monthlyData.entries.map((entry) {
          final month = entry.key;
          final income = entry.value['income']!;
          final expense = entry.value['expense']!;
          final transfer = entry.value['transfer']!;
          final net = income - expense;
          final isPositive = net >= 0;
          final totalVolume = income + expense;
          final incPercent = totalVolume > 0 ? income / totalVolume : 0.0;
          final expPercent = totalVolume > 0 ? expense / totalVolume : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: dark
                      ? [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05)
                        ]
                      : [Colors.white, Colors.grey[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color:
                      dark ? Colors.white.withOpacity(0.2) : Colors.grey[200]!,
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.2 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(month,
                          style: GoogleFonts.cairo(
                              color:
                                  dark ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFF00E676).withOpacity(0.2)
                              : const Color(0xFFFF1744).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isPositive
                                  ? const Color(0xFF00E676).withOpacity(0.5)
                                  : const Color(0xFFFF1744).withOpacity(0.5),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: isPositive
                                    ? const Color(0xFF00E676).withOpacity(0.3)
                                    : const Color(0xFFFF1744).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Text(
                            'الصافي: ${isPositive ? '+' : ''}${formatNumber(net)} ${app.appCurrencySymbol}',
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                shadows: [
                                  Shadow(
                                      color: isPositive
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF1744),
                                      blurRadius: 8)
                                ])),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: dark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey[100]),
                  child: Column(children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFF00E676),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Color(0xFF00E676),
                                                blurRadius: 6)
                                          ])),
                                  const SizedBox(width: 6),
                                  Text('إجمالي الدخل',
                                      style: GoogleFonts.cairo(
                                          color: dark
                                              ? Colors.white70
                                              : Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('+${formatNumber(income)}',
                                        style: GoogleFonts.cairo(
                                            color: const Color(0xFF00E676),
                                            fontSize: 18,
                                            height: 1,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                  color: const Color(0xFF00E676)
                                                      .withOpacity(0.5),
                                                  blurRadius: 10)
                                            ])),
                                    const SizedBox(width: 4),
                                    Text(app.appCurrencySymbol,
                                        style: GoogleFonts.cairo(
                                            color: const Color(0xFF00E676)
                                                .withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: dark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey[300]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFFF1744),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Color(0xFFFF1744),
                                                  blurRadius: 6)
                                            ])),
                                    const SizedBox(width: 6),
                                    Text('إجمالي المصروف',
                                        style: GoogleFonts.cairo(
                                            color: dark
                                                ? Colors.white70
                                                : Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(formatNumber(expense),
                                          style: GoogleFonts.cairo(
                                              color: const Color(0xFFFF1744),
                                              fontSize: 18,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                    color:
                                                        const Color(0xFFFF1744)
                                                            .withOpacity(0.5),
                                                    blurRadius: 10)
                                              ])),
                                      const SizedBox(width: 4),
                                      Text(app.appCurrencySymbol,
                                          style: GoogleFonts.cairo(
                                              color: const Color(0xFFFF1744)
                                                  .withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Segmented Bar (Income vs Expense)
                    Container(
                      height: 10,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          if (incPercent > 0)
                            Expanded(
                              flex: (incPercent * 100).toInt().clamp(1, 100),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF00E676)
                                            .withOpacity(0.8),
                                        blurRadius: 10)
                                  ],
                                ),
                              ),
                            ),
                          if (incPercent > 0 && expPercent > 0)
                            Container(
                                width: 2,
                                color: dark
                                    ? Colors.black
                                    : Colors.white), // Divider
                          if (expPercent > 0)
                            Expanded(
                              flex: (expPercent * 100).toInt().clamp(1, 100),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF1744),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFFF1744)
                                            .withOpacity(0.8),
                                        blurRadius: 10)
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
                if (transfer > 0)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B0FF).withOpacity(0.15),
                      border: Border(
                          top: BorderSide(
                              color: const Color(0xFF00B0FF).withOpacity(0.3),
                              width: 1)),
                    ),
                    child: Text(
                        '↔️ إجمالي التحويلات: ${formatNumber(transfer)} ${app.appCurrencySymbol}',
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF00B0FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        Text('موقف الحسابات الحالي 🏦',
            style: GoogleFonts.cairo(
                color: dark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ...app.accounts.map((acc) {
          final accTxs = app.transactions.where((t) => t.accountId == acc.id);
          final income = accTxs
              .where((t) => t.isIncome && t.isCountable)
              .fold(0.0, (s, t) => s + t.amount);
          final expense = accTxs
              .where((t) => t.isExpense && t.isCountable)
              .fold(0.0, (s, t) => s + t.amount);
          final txCount = accTxs.length;

          final String nativeCurrency = acc.currency;
          final String nativeSymbol =
              nativeCurrency == 'EGP' ? 'جنية' : nativeCurrency;

          final bool hasSecondary = acc.secondaryCurrency != null &&
              acc.secondaryCurrency!.isNotEmpty;
          double secondaryBalance = 0.0;
          String secondarySymbol = '';
          if (hasSecondary) {
            secondaryBalance = app.convertCurrency(
                acc.balance, nativeCurrency, acc.secondaryCurrency!);
            secondarySymbol = acc.secondaryCurrency == 'EGP'
                ? 'جنية'
                : acc.secondaryCurrency!;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                  colors: [acc.startColor, acc.endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: acc.startColor.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
                BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    spreadRadius: 1,
                    offset: const Offset(1, 1)) // 3D Top highlight
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.15,
                    child: acc.imagePath != null
                        ? SizedBox(
                            width: 120,
                            height: 120,
                            child: kIsWeb
                                ? Image.network(acc.imagePath!,
                                    fit: BoxFit.cover)
                                : Image.file(File(acc.imagePath!),
                                    fit: BoxFit.cover),
                          )
                        : Text(acc.icon, style: const TextStyle(fontSize: 100)),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: acc.imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: kIsWeb
                                        ? Image.network(acc.imagePath!,
                                            fit: BoxFit.cover)
                                        : Image.file(File(acc.imagePath!),
                                            fit: BoxFit.cover))
                                : Center(
                                    child: Text(acc.icon,
                                        style: const TextStyle(fontSize: 26))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(acc.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        height: 1.3,
                                        shadows: [
                                          Shadow(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              blurRadius: 8)
                                        ])),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(formatNumber(acc.balance),
                                          style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontSize: 24,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    blurRadius: 12)
                                              ])),
                                      const SizedBox(width: 4),
                                      Text(nativeSymbol,
                                          style: GoogleFonts.cairo(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                if (hasSecondary)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                        '${formatNumber(secondaryBalance)} $secondarySymbol',
                                        style: GoogleFonts.cairo(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            height: 1.2,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  blurRadius: 8)
                                            ])),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text('$txCount معاملة',
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildStatChip(
                                  'إجمالي الدخل',
                                  formatNumber(income),
                                  nativeSymbol,
                                  const Color(0xFF00E676),
                                  dark,
                                  '⬆️',
                                  isGlass: true),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatChip(
                                  'إجمالي المصروف',
                                  formatNumber(expense),
                                  nativeSymbol,
                                  const Color(0xFFFF1744),
                                  dark,
                                  '⬇️',
                                  isGlass: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 80), // مساحة إضافية للنافجيشن بار
      ],
    );
  }

  Widget _buildLogsView(AppProvider app, bool dark) {
    final allLogs = app.actionLogs;

    final logs = allLogs.where((log) {
      final ts = log['timestamp'];
      final DateTime logDate =
          ts != null ? (ts as dynamic).toDate() : DateTime.now();
      if (_startDate != null && logDate.isBefore(_startDate!)) return false;
      if (_endDate != null && logDate.isAfter(_endDate!)) return false;

      final by = log['by'] ?? 'مجهول';
      final action = log['action'] ?? '';
      if (_logSearchQuery.isNotEmpty) {
        final q = _logSearchQuery.toLowerCase();
        if (!by.toLowerCase().contains(q) &&
            !action.toLowerCase().contains(q)) {
          return false;
        }
      }

      final txType = log['tx_type'] as String?;
      if (_logFilterType != 'all') {
        if (_logFilterType == 'delete' &&
            !(action.contains('حذف') || action.contains('مسح'))) {
          return false;
        }
        if (_logFilterType != 'delete' && txType != _logFilterType) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('سجل مراقبة النشاطات اللحظي ⏱️',
            style: GoogleFonts.cairo(
                color: dark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),

        // الفلاتر والبحث الخاصة بالسجل
        Container(
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: dark ? Colors.white24 : Colors.grey[300]!),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _logSearchQuery = v),
            style: GoogleFonts.cairo(
                color: dark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'بحث عن شخص أو حركة...',
              hintStyle: GoogleFonts.cairo(
                  color: dark ? Colors.white38 : Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _logTypeChip('الكل', 'all', const Color(0xFF7C3AED), dark),
              _logTypeChip('دخل', 'income', const Color(0xFF16A34A), dark),
              _logTypeChip('مصروف', 'expense', const Color(0xFFDC2626), dark),
              _logTypeChip('تحويل', 'transfer', const Color(0xFF00B0FF), dark),
              _logTypeChip('حذف', 'delete', const Color(0xFFFF1744), dark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (logs.isEmpty) _buildEmptyState('لا توجد نشاطات مطابقة للبحث'),
        ...logs.map((log) {
          final timeStr = log['timestamp'] != null
              ? DateFormat('d/M/yyyy - h:mm a')
                  .format((log['timestamp'] as dynamic).toDate())
                  .replaceAll('AM', 'ص')
                  .replaceAll('PM', 'م')
              : 'الآن';
          final by = log['by'] ?? 'مجهول';
          final isMe = by == app.displayName;
          final action = log['action'] ?? '';

          final txAmount = (log['tx_amount'] as num?)?.toDouble();
          final txType = log['tx_type'] as String?;
          final txCategory = log['tx_category'] as String?;
          final accountName = log['account_name'] as String?;
          final toAccountName = log['to_account_name'] as String?;
          final colorHex = log['color_hex'] as String?;

          Color iconColor = Colors.white;
          Color boxColor =
              dark ? Colors.black.withOpacity(0.4) : const Color(0xFF4C1D95);
          IconData mainIcon = Icons.info_outline_rounded;

          if (txType != null) {
            if (txType == 'income') {
              boxColor = const Color(0xFF16A34A);
              mainIcon = Icons.arrow_upward_rounded;
            } else if (txType == 'expense') {
              boxColor = const Color(0xFFDC2626);
              mainIcon = Icons.arrow_downward_rounded;
            } else if (txType == 'transfer') {
              boxColor = const Color(0xFF00B0FF);
              mainIcon = Icons.sync_alt_rounded;
            }
          } else if (colorHex != null) {
            boxColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
            mainIcon = Icons.account_balance_wallet_rounded;
          } else if (action.contains('حذف') || action.contains('مسح')) {
            boxColor = const Color(0xFFFF1744);
            mainIcon = Icons.delete_outline_rounded;
          } else if (action.contains('تسجيل الدخول')) {
            boxColor = const Color(0xFF7C3AED);
            mainIcon = Icons.login_rounded;
          }

          Widget buildAccBadge(String name, String? hexColor) {
            Color c = const Color(0xFF4C1D95);
            if (hexColor != null && hexColor.isNotEmpty) {
              try {
                c = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
              } catch (_) {}
            } else {
              try {
                final acc = app.accounts.firstWhere((a) => a.name == name);
                c = acc.startColor;
              } catch (_) {}
            }
            return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: c, // لون الحساب الثابت
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: c.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(name,
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ]));
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: boxColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(mainIcon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(action,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900)),
                              ),
                              if (txAmount != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                      '${txType == 'expense' ? '-' : (txType == 'income' ? '+' : '')}${formatNumber(txAmount)} ${app.appCurrencySymbol}',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (txCategory != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Builder(
                                          builder: (ctx) {
                                            final cData =
                                                CategoryData.parse(txCategory);
                                            if (cData.imagePath != null) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: kIsWeb
                                                    ? Image.network(
                                                        cData.imagePath!,
                                                        width: 12,
                                                        height: 12,
                                                        fit: BoxFit.cover)
                                                    : Image.file(
                                                        File(cData.imagePath!),
                                                        width: 12,
                                                        height: 12,
                                                        fit: BoxFit.cover),
                                              );
                                            }
                                            return Text(cData.icon,
                                                style: const TextStyle(
                                                    fontSize: 11));
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                            CategoryData.parse(txCategory).name,
                                            style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                ),
                              if (accountName != null)
                                buildAccBadge(accountName, colorHex),
                              if (toAccountName != null)
                                buildAccBadge(toAccountName, null),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(
                                0xFF7C3AED), // خلفية موف صلبة لاسم الشخص
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF7C3AED).withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Row(
                          children: [
                            Icon(
                                isMe
                                    ? Icons.person_rounded
                                    : Icons.phone_android_rounded,
                                color: Colors.white,
                                size: 14),
                            const SizedBox(width: 4),
                            Text('بواسطة: $by',
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      Text(timeStr,
                          style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _logTypeChip(String label, String value, Color color, bool dark) {
    final active = _logFilterType == value;
    return GestureDetector(
      onTap: () {
        Provider.of<AppProvider>(context, listen: false).playClick();
        setState(() => _logFilterType = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : (dark ? Colors.white12 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                color: active
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, String currency,
      Color color, bool dark, String iconText,
      {bool isGlass = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isGlass
            ? Colors.white.withOpacity(0.15)
            : (dark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isGlass ? 0.3 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(iconText, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(label,
                      maxLines: 1,
                      style: GoogleFonts.cairo(
                          color: isGlass
                              ? Colors.white.withOpacity(0.9)
                              : (dark ? Colors.white70 : Colors.black87),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.cairo(
                            color: isGlass
                                ? Colors.white
                                : (dark ? Colors.white : Colors.black),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            shadows: isGlass
                                ? [
                                    Shadow(
                                        color: Colors.white.withOpacity(0.6),
                                        blurRadius: 12)
                                  ]
                                : []),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currency,
                        style: GoogleFonts.cairo(
                            color: isGlass
                                ? Colors.white.withOpacity(0.9)
                                : (dark ? Colors.white70 : Colors.black87),
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPDF(
      AppProvider app, List<Transaction> filteredTxs) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('جاري إنشاء ملف PDF... 📄',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold))));

    final pdf = pw.Document();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final fontRegular = await PdfGoogleFonts.cairoRegular();

    final primaryColor = PdfColor.fromHex('#7C3AED');
    final incomeColor = PdfColor.fromHex('#00E676');
    final expenseColor = PdfColor.fromHex('#FF1744');
    const textMuted = PdfColors.black; // لون أسود قوي وواضح بدلاً من الرمادي

    // دالة لتنظيف النصوص من الإيموجي والرموز غير المدعومة في الـ PDF
    String cleanText(String text) {
      return text
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s\-_]', unicode: true), '')
          .trim();
    }

    final safeName = cleanText(app.displayName);

    double getInAppCurrency(Transaction t) {
      final acc = app.accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => app.accounts.first);
      return app.convertCurrency(t.amount, acc.currency, app.appCurrency);
    }

    // حساب التحليلات والنسب المئوية
    final expenses =
        filteredTxs.where((t) => t.isExpense && t.isCountable).toList();
    final incomes =
        filteredTxs.where((t) => t.isIncome && t.isCountable).toList();

    final filteredTotalIncome =
        incomes.fold(0.0, (s, t) => s + getInAppCurrency(t));
    final filteredTotalExpense =
        expenses.fold(0.0, (s, t) => s + getInAppCurrency(t));
    final filteredNetBalance = filteredTotalIncome - filteredTotalExpense;
    final totalVolume = filteredTotalIncome + filteredTotalExpense;

    final Map<String, double> expenseData = {};
    for (var tx in expenses) {
      final catName = CategoryData.parse(tx.category).name;
      expenseData[catName] = (expenseData[catName] ?? 0) + getInAppCurrency(tx);
    }
    final sortedExpenses = expenseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, double> incomeData = {};
    for (var tx in incomes) {
      final catName = CategoryData.parse(tx.category).name;
      incomeData[catName] = (incomeData[catName] ?? 0) + getInAppCurrency(tx);
    }
    final sortedIncomes = incomeData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final incPct = totalVolume > 0
        ? ((filteredTotalIncome / totalVolume) * 100).toStringAsFixed(1)
        : '0';
    final expPct = totalVolume > 0
        ? ((filteredTotalExpense / totalVolume) * 100).toStringAsFixed(1)
        : '0';

    pw.Widget buildPdfSummaryCard(String title, double amount, PdfColor color) {
      return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white, // خلفية بيضاء ناصعة
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: color, width: 2.0), // حدود قوية وواضحة
          ),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(
                    '${formatNumber(amount)} ${cleanText(app.appCurrencySymbol)}',
                    style: pw.TextStyle(
                        fontSize: 18,
                        color: color,
                        fontWeight: pw.FontWeight.bold)),
              ]));
    }

    final periodText = _selectedPeriod == 'كل الأوقات'
        ? 'الفترة: كل الأوقات'
        : 'الفترة: ${DateFormat('yyyy/MM/dd').format(_startDate!)} إلى ${DateFormat('yyyy/MM/dd').format(_endDate!)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: fontBold, // الخط الأساسي أصبح عريض (Bold) بالكامل
          bold: fontBold, // الخط العريض
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 15),
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('تقرير الحسابات لـ: $safeName',
                      style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('تقرير مالي وتفصيلي شامل',
                      style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.black,
                          fontWeight: pw.FontWeight.normal)),
                  pw.SizedBox(height: 2),
                  pw.Text(periodText,
                      style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text(DateFormat('yyyy/MM/dd').format(DateTime.now()),
                  style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.black,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('الصفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  children: [
                    buildPdfSummaryCard(
                        'إجمالي الدخل', filteredTotalIncome, incomeColor),
                    pw.SizedBox(height: 8),
                    buildPdfSummaryCard(
                        'إجمالي المصروف', filteredTotalExpense, expenseColor),
                    pw.SizedBox(height: 8),
                    buildPdfSummaryCard('الرصيد الصافي', filteredNetBalance,
                        filteredNetBalance >= 0 ? incomeColor : expenseColor),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              // الرسم البياني داخل الـ PDF
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  height: 190,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: primaryColor, width: 2.0),
                  ),
                  child: pw.Chart(
                    title: pw.Text('نظرة عامة (دخل / مصروف)',
                        style: pw.TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: pw.FontWeight.bold)),
                    grid: pw.PieGrid(),
                    datasets: [
                      if (filteredTotalIncome > 0)
                        pw.PieDataSet(
                          value: filteredTotalIncome,
                          color: incomeColor,
                          legend: 'الدخل ($incPct%)',
                        ),
                      if (filteredTotalExpense > 0)
                        pw.PieDataSet(
                          value: filteredTotalExpense,
                          color: expenseColor,
                          legend: 'المصروف ($expPct%)',
                        ),
                    ],
                  ),
                ),
              ),
            ]),
            if (sortedExpenses.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: primaryColor, width: 2.0),
                  ),
                  child: pw.Row(children: [
                    pw.Text('رؤية تحليلية 💡: ',
                        style: pw.TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'أعلى سحب للأموال كان في قسم "${cleanText(sortedExpenses.first.key)}" ويمثل %${filteredTotalExpense > 0 ? ((sortedExpenses.first.value / filteredTotalExpense) * 100).toStringAsFixed(1) : '0'} من إجمالي المصروفات.',
                        style: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                  ])),
            ],
            pw.SizedBox(height: 15),
            pw.Text('الأرصدة الحالية لكل حساب:',
                style: pw.TextStyle(
                    fontSize: 18,
                    color: primaryColor,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: app.accounts.map((acc) {
                final accColor =
                    PdfColor.fromHex(acc.colors.last.replaceAll('#', ''));
                return pw.Container(
                    width: 140,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                          color: accColor, width: 2.0), // حدود واضحة وقوية
                    ),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(cleanText(acc.name),
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  color: PdfColors.black,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                              '${formatNumber(acc.balance)} ${cleanText(acc.currency)}',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accColor))
                        ]));
              }).toList(),
            ),
            if (sortedExpenses.isNotEmpty) ...[
              pw.SizedBox(height: 25),
              pw.Text('تحليل المصروفات حسب الفئة:',
                  style: pw.TextStyle(
                      fontSize: 18,
                      color: expenseColor,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                cellAlignment: pw.Alignment.center,
                headerDecoration: pw.BoxDecoration(
                  color: expenseColor,
                  borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(6)),
                ),
                headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.black,
                    fontWeight: pw.FontWeight.bold),
                rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey400, width: 1.0))),
                data: <List<String>>[
                  <String>['الفئة', 'المبلغ', 'النسبة'],
                  ...sortedExpenses.map((e) {
                    final pct = filteredTotalExpense > 0
                        ? (e.value / filteredTotalExpense * 100)
                            .toStringAsFixed(1)
                        : '0';
                    return [
                      cleanText(e.key),
                      '${formatNumber(e.value)} ${cleanText(app.appCurrencySymbol)}',
                      '%$pct'
                    ];
                  }),
                ],
              ),
            ],
            if (sortedIncomes.isNotEmpty) ...[
              pw.SizedBox(height: 25),
              pw.Text('تحليل مصادر الدخل:',
                  style: pw.TextStyle(
                      fontSize: 18,
                      color: incomeColor,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                cellAlignment: pw.Alignment.center,
                headerDecoration: pw.BoxDecoration(
                  color: incomeColor,
                  borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(6)),
                ),
                headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.black,
                    fontWeight: pw.FontWeight.bold),
                rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey400, width: 1.0))),
                data: <List<String>>[
                  <String>['الفئة', 'المبلغ', 'النسبة'],
                  ...sortedIncomes.map((e) {
                    final pct = filteredTotalIncome > 0
                        ? (e.value / filteredTotalIncome * 100)
                            .toStringAsFixed(1)
                        : '0';
                    return [
                      cleanText(e.key),
                      '${formatNumber(e.value)} ${cleanText(app.appCurrencySymbol)}',
                      '%$pct'
                    ];
                  }),
                ],
              ),
            ],
            pw.SizedBox(height: 25),
            pw.Text('سجل المعاملات التفصيلي:',
                style: pw.TextStyle(
                    fontSize: 18,
                    color: primaryColor,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.center,
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius:
                    const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
              ),
              headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                  fontWeight: pw.FontWeight.bold),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom:
                        pw.BorderSide(color: PdfColors.grey400, width: 1.0)),
              ),
              data: <List<String>>[
                <String>['التاريخ', 'النوع', 'الفئة', 'المبلغ', 'ملاحظات'],
                ...filteredTxs.map((tx) {
                  final acc = app.accounts.firstWhere(
                      (a) => a.id == tx.accountId,
                      orElse: () => app.accounts.first);
                  final sym = acc.currency == 'EGP' ? 'جنية' : acc.currency;
                  return [
                    DateFormat('yyyy-MM-dd').format(tx.date),
                    tx.isIncome
                        ? "دخل"
                        : tx.isExpense
                            ? "مصروف"
                            : "تحويل",
                    cleanText(CategoryData.parse(tx.category).name),
                    '${formatNumber(tx.amount)} ${cleanText(sym)}',
                    tx.notes.isEmpty ? '-' : cleanText(tx.notes),
                  ];
                }),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Money_Bravo_Report.pdf');
  }

  Future<void> _exportExcel(
      AppProvider app, List<Transaction> filteredTxs) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('جاري إنشاء ملف Excel... 📊',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold))));

    String csv = "\uFEFF"; // لدعم اللغة العربية في Excel

    String cleanText(String text) {
      return text
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s\-_]', unicode: true), '')
          .trim();
    }

    final periodText = _selectedPeriod == 'كل الأوقات'
        ? 'الفترة: كل الأوقات'
        : 'الفترة: ${DateFormat('yyyy/MM/dd').format(_startDate!)} إلى ${DateFormat('yyyy/MM/dd').format(_endDate!)}';

    csv += "تقرير مالي شامل لـ: ${cleanText(app.displayName)}\n\n";
    csv += "$periodText\n\n";

    double getInAppCurrency(Transaction t) {
      final acc = app.accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => app.accounts.first);
      return app.convertCurrency(t.amount, acc.currency, app.appCurrency);
    }

    final expenses =
        filteredTxs.where((t) => t.isExpense && t.isCountable).toList();
    final incomes =
        filteredTxs.where((t) => t.isIncome && t.isCountable).toList();

    final filteredTotalIncome =
        incomes.fold(0.0, (s, t) => s + getInAppCurrency(t));
    final filteredTotalExpense =
        expenses.fold(0.0, (s, t) => s + getInAppCurrency(t));
    final filteredNetBalance = filteredTotalIncome - filteredTotalExpense;

    csv += "ملخص الإجماليات للفترة المحددة\n";
    csv +=
        "إجمالي الدخل,${formatNumber(filteredTotalIncome)} ${app.appCurrencySymbol}\n";
    csv +=
        "إجمالي المصروف,${formatNumber(filteredTotalExpense)} ${app.appCurrencySymbol}\n";
    csv +=
        "الرصيد الصافي,${formatNumber(filteredNetBalance)} ${app.appCurrencySymbol}\n\n";

    csv += "موقف الأرصدة لكل حساب\n";
    for (var acc in app.accounts) {
      csv +=
          "${cleanText(acc.name)},${formatNumber(acc.balance)} ${cleanText(acc.currency)}\n";
    }
    csv += "\n";

    csv += "التاريخ,النوع,الفئة,المبلغ,ملاحظات\n";
    for (var tx in filteredTxs) {
      final acc = app.accounts.firstWhere((a) => a.id == tx.accountId,
          orElse: () => app.accounts.first);
      final sym = acc.currency == 'EGP' ? 'جنية' : acc.currency;
      final type = tx.isIncome
          ? "دخل"
          : tx.isExpense
              ? "مصروف"
              : "تحويل";
      final notes = tx.notes.replaceAll(',', '،').replaceAll('\n', ' ');
      csv +=
          "${DateFormat('yyyy-MM-dd').format(tx.date)},$type,${cleanText(CategoryData.parse(tx.category).name)},${tx.amount} ${cleanText(sym)},${cleanText(notes)}\n";
    }

    final bytes = Uint8List.fromList(utf8.encode(csv));
    await Share.shareXFiles(
      [
        XFile.fromData(bytes,
            mimeType: 'text/csv', name: 'Money_Bravo_Report.csv')
      ],
      text: 'تقرير المعاملات (Excel)',
    );
  }
}

class _DonutChartWidget extends StatefulWidget {
  final List<MapEntry<String, double>> data;
  final Map<String, CategoryData> catDataMap;
  final double total;
  final List<Color> colors;
  final bool dark;
  final AppProvider app;

  const _DonutChartWidget({
    required this.data,
    required this.catDataMap,
    required this.total,
    required this.colors,
    required this.dark,
    required this.app,
  });

  @override
  State<_DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<_DonutChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.dark
              ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color:
                widget.dark ? Colors.white.withOpacity(0.2) : Colors.grey[200]!,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(widget.dark ? 0.3 : 0.05),
              blurRadius: 30,
              offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: widget.colors.first.withOpacity(0.3),
                        blurRadius: 30)
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: PieChart(
                  swapAnimationDuration: const Duration(milliseconds: 250),
                  swapAnimationCurve: Curves.easeOutCubic,
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          setState(() => _touchedIndex = -1);
                          return;
                        }
                        setState(() => _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex);
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: widget.data.asMap().entries.map((entry) {
                      final isTouched = entry.key == _touchedIndex;
                      final color =
                          widget.colors[entry.key % widget.colors.length];
                      final percentage = widget.total > 0
                          ? (entry.value.value / widget.total) * 100
                          : 0;
                      return PieChartSectionData(
                        color: color,
                        value: entry.value.value > 0 ? entry.value.value : 0.01,
                        showTitle: isTouched || percentage > 5,
                        title: '%${percentage.toStringAsFixed(1)}',
                        radius: isTouched ? 55.0 : 45.0,
                        titlePositionPercentageOffset: 0.5,
                        titleStyle: GoogleFonts.cairo(
                            fontSize: isTouched ? 16.0 : 12.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 4)
                            ]),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(
                width: 75,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الإجمالي',
                        style: GoogleFonts.cairo(
                            color:
                                widget.dark ? Colors.white54 : Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          '${formatNumber(widget.total)} ${widget.app.appCurrencySymbol}',
                          style: GoogleFonts.cairo(
                              color: widget.dark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              shadows: widget.dark
                                  ? [
                                      Shadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 10)
                                    ]
                                  : null)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            children: widget.data.asMap().entries.map((entry) {
              final color = widget.colors[entry.key % widget.colors.length];
              final percentage =
                  widget.total > 0 ? (entry.value.value / widget.total) : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Row(
                            children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: color, blurRadius: 8)
                                      ])),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (ctx) {
                                  final catData =
                                      widget.catDataMap[entry.value.key];
                                  if (catData != null) {
                                    if (catData.imagePath != null) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: kIsWeb
                                              ? Image.network(
                                                  catData.imagePath!,
                                                  width: 16,
                                                  height: 16,
                                                  fit: BoxFit.cover)
                                              : Image.file(
                                                  File(catData.imagePath!),
                                                  width: 16,
                                                  height: 16,
                                                  fit: BoxFit.cover),
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(catData.icon,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      );
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              Expanded(
                                child: Text(entry.value.key,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                        color: widget.dark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 7,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '%${(percentage * 100).toStringAsFixed(1)}',
                                  style: GoogleFonts.cairo(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(formatNumber(entry.value.value),
                                          style: GoogleFonts.cairo(
                                              color: widget.dark
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              shadows: widget.dark
                                                  ? [
                                                      Shadow(
                                                          color: Colors.white
                                                              .withOpacity(0.5),
                                                          blurRadius: 8)
                                                    ]
                                                  : null)),
                                      const SizedBox(width: 4),
                                      Text(widget.app.appCurrencySymbol,
                                          style: GoogleFonts.cairo(
                                              color: widget.dark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: widget.dark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.transparent),
                      ),
                      child: percentage > 0.0
                          ? FractionallySizedBox(
                              alignment: Alignment.centerRight,
                              widthFactor: percentage.clamp(0.01, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [color.withOpacity(0.6), color]),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
