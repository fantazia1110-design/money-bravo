import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/account.dart';
import '../utils/formatters.dart';
import '../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _search = '';
  String _filterType = 'all'; // all, income, expense, transfer, pending
  String _filterAccount = 'all';
  String _filterCategory = 'all';
  String _filterDate = 'all'; // all, today, week, month
  DateTime? _manualStartDate;
  DateTime? _manualEndDate;
  TimeOfDay? _manualStartTime;
  TimeOfDay? _manualEndTime;

  void _showFilterSheet(BuildContext context, AppProvider app, bool dark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('فلاتر البحث 🎯',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {
                              app.playClick();
                              setState(() {
                                _filterType = 'all';
                                _filterAccount = 'all';
                                _filterCategory = 'all';
                                _filterDate = 'all';
                                _manualStartDate = null;
                                _manualEndDate = null;
                                _manualStartTime = null;
                                _manualEndTime = null;
                              });
                              setSheetState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF1744).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFFF1744)
                                        .withOpacity(0.5),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFFFF1744)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cleaning_services_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text('مسح الكل',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('تصنيف الفئات 🛒',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _catChipBtn(
                                'all', 'كل الفئات', 'all', _filterCategory,
                                (v) {
                              setState(() => _filterCategory = v);
                              setSheetState(() {});
                            }, true),
                            ...app.categories.map((c) => _catChipBtn(
                                    c,
                                    CategoryData.parse(c).name,
                                    c,
                                    _filterCategory, (v) {
                                  setState(() => _filterCategory = v);
                                  setSheetState(() {});
                                }, true)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('تحديد سريع للتاريخ',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _dateChip('كل الأوقات', '📅', 'all',
                                const Color(0xFF7C3AED), true, setSheetState),
                            _dateChip('اليوم', '☀️', 'today',
                                const Color(0xFF00B0FF), true, setSheetState),
                            _dateChip('أمس', '⏰', 'yesterday',
                                const Color(0xFFEC4899), true, setSheetState),
                            _dateChip('هذا الأسبوع', '📆', 'week',
                                const Color(0xFF10B981), true, setSheetState),
                            _dateChip('هذا الشهر', '🌙', 'month',
                                const Color(0xFFFF9100), true, setSheetState),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('تحديد يدوي',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerButton(
                              label: 'من تاريخ',
                              date: _manualStartDate,
                              color: const Color(0xFF00B0FF),
                              dark: true,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _manualStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF7C3AED),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF2E1065),
                                          onSurface: Colors.white,
                                        ),
                                        dialogTheme: const DialogThemeData(
                                            backgroundColor: Color(0xFF2E1065)),
                                        datePickerTheme: DatePickerThemeData(
                                          cancelButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFF1744)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFFFF1744),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          confirmButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00E676)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFF00E676),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _manualStartDate = picked;
                                    _filterDate = 'all'; // Clear quick filter
                                  });
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDatePickerButton(
                              label: 'إلى تاريخ',
                              date: _manualEndDate,
                              color: const Color(0xFFFF9100),
                              dark: true,
                              onTap: () async {
                                app.playClick();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _manualEndDate ??
                                      _manualStartDate ??
                                      DateTime.now(),
                                  firstDate: _manualStartDate ?? DateTime(2020),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF7C3AED),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF2E1065),
                                          onSurface: Colors.white,
                                        ),
                                        dialogTheme: const DialogThemeData(
                                            backgroundColor: Color(0xFF2E1065)),
                                        datePickerTheme: DatePickerThemeData(
                                          cancelButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFF1744)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFFFF1744),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          confirmButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00E676)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFF00E676),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _manualEndDate = picked;
                                    _filterDate = 'all'; // Clear quick filter
                                  });
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTimePickerButton(
                              label: 'من وقت',
                              time: _manualStartTime,
                              color: const Color(0xFF00B0FF),
                              dark: true,
                              onTap: () async {
                                app.playClick();
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      _manualStartTime ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF7C3AED),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF2E1065),
                                          onSurface: Colors.white,
                                        ),
                                        dialogTheme: const DialogThemeData(
                                            backgroundColor: Color(0xFF2E1065)),
                                        timePickerTheme: TimePickerThemeData(
                                          cancelButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFF1744)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFFFF1744),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          confirmButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00E676)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFF00E676),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _manualStartTime = picked;
                                    _filterDate = 'all';
                                  });
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimePickerButton(
                              label: 'إلى وقت',
                              time: _manualEndTime,
                              color: const Color(0xFFFF9100),
                              dark: true,
                              onTap: () async {
                                app.playClick();
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _manualEndTime ??
                                      _manualStartTime ??
                                      TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF7C3AED),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF2E1065),
                                          onSurface: Colors.white,
                                        ),
                                        dialogTheme: const DialogThemeData(
                                            backgroundColor: Color(0xFF2E1065)),
                                        timePickerTheme: TimePickerThemeData(
                                          cancelButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFF1744)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFFFF1744),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          confirmButtonStyle:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00E676)
                                                    .withOpacity(0.15),
                                            foregroundColor:
                                                const Color(0xFF00E676),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            textStyle: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _manualEndTime = picked;
                                    _filterDate = 'all';
                                  });
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            app.playClick();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text('عرض النتائج',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF7C3AED),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    // دالة لتنظيف وتوحيد النصوص العربية للبحث الذكي (تتجاهل الهمزات والتاء المربوطة)
    String normalizeArabic(String text) {
      return text
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي')
          .toLowerCase();
    }

    final searchLower = normalizeArabic(_search);
    final isSearching = searchLower.isNotEmpty;

    final filtered = app.transactions.where((tx) {
      final matchSearch = !isSearching ||
          (normalizeArabic(tx.description).contains(searchLower) ||
              normalizeArabic(CategoryData.parse(tx.category).name)
                  .contains(searchLower) ||
              normalizeArabic(formatDate(tx.date)).contains(searchLower) ||
              formatNumber(tx.amount).contains(searchLower) ||
              tx.amount.toString().contains(searchLower));

      final matchType = _filterType == 'all'
          ? true
          : _filterType == 'pending'
              ? tx.isPending
              : tx.type.name == _filterType;
      final matchAcc = _filterAccount == 'all' ||
          tx.accountId == _filterAccount ||
          (tx.isTransfer && tx.toAccountId == _filterAccount);
      final matchCat =
          _filterCategory == 'all' || tx.category == _filterCategory;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);

      bool matchDate;
      if (_manualStartDate != null) {
        DateTime start = DateTime(
            _manualStartDate!.year,
            _manualStartDate!.month,
            _manualStartDate!.day,
            _manualStartTime?.hour ?? 0,
            _manualStartTime?.minute ?? 0);

        DateTime end;
        if (_manualEndDate != null) {
          end = DateTime(
              _manualEndDate!.year,
              _manualEndDate!.month,
              _manualEndDate!.day,
              _manualEndTime?.hour ?? 23,
              _manualEndTime?.minute ?? 59,
              59);
        } else {
          end = DateTime(
              _manualStartDate!.year,
              _manualStartDate!.month,
              _manualStartDate!.day,
              _manualEndTime?.hour ?? 23,
              _manualEndTime?.minute ?? 59,
              59);
        }

        matchDate = !tx.date.isBefore(start) && !tx.date.isAfter(end);
      } else {
        matchDate = _filterDate == 'all'
            ? true
            : _filterDate == 'today'
                ? txDateOnly.isAtSameMomentAs(today)
                : _filterDate == 'yesterday'
                    ? txDateOnly.isAtSameMomentAs(yesterday)
                    : _filterDate == 'week'
                        ? tx.date.isAfter(now.subtract(const Duration(days: 7)))
                        : _filterDate == 'month'
                            ? (tx.date.year == now.year &&
                                tx.date.month == now.month)
                            : true;
      }
      return matchSearch && matchType && matchAcc && matchCat && matchDate;
    }).toList();

    // حساب إجماليات الفلتر الحالي للملخص
    double filteredIncome = 0;
    double filteredExpense = 0;
    for (var t in filtered) {
      if (!t.isCountable || t.isTransfer) continue;
      final acc = app.accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => app.accounts.first);
      final amtInAppCur =
          app.convertCurrency(t.amount, acc.currency, app.appCurrency);
      if (t.isIncome) filteredIncome += amtInAppCur;
      if (t.isExpense) filteredExpense += amtInAppCur;
    }

    final inputColor = dark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        dark ? Colors.white.withOpacity(0.07) : Colors.grey[200]!;
    final textColor = dark ? Colors.white : const Color(0xFF1E293B);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Search
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color:
                            dark ? Colors.white.withOpacity(0.1) : Colors.white,
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED)
                            .withOpacity(dark ? 0.15 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.cairo(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم، الفئة، التاريخ، أو المبلغ...',
                      hintStyle: GoogleFonts.cairo(
                          color: dark ? Colors.white38 : Colors.grey[400]),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF7C3AED)),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          app.playClick();
                          _showFilterSheet(context, app, dark);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF00B0FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF7C3AED).withOpacity(0.6),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.tune_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Account filter chips (Wrap instead of Horizontal Scroll)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      _chipBtn(null, 'الكل', 'all', _filterAccount, (v) {
                        setState(() => _filterAccount = v);
                      }, dark),
                      ...app.accounts.map(
                          (a) => _chipBtn(a, a.name, a.id, _filterAccount, (v) {
                                setState(() => _filterAccount = v);
                              }, dark)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // الفاصل المضيء 🌟
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED).withOpacity(0.0),
                          const Color(0xFF7C3AED),
                          const Color(0xFF7C3AED).withOpacity(0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]),
                ),
                const SizedBox(height: 16),

                // Type filter chips (Wrap instead of Horizontal Scroll)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      _typeChip('الكل', Icons.grid_view_rounded, 'all',
                          const Color(0xFF7C3AED), dark),
                      _typeChip('دخل', Icons.trending_up_rounded, 'income',
                          const Color(0xFF00E676), dark),
                      _typeChip('مصروف', Icons.trending_down_rounded, 'expense',
                          const Color(0xFFFF1744), dark),
                      _typeChip('تحويل', Icons.sync_alt_rounded, 'transfer',
                          const Color(0xFF00B0FF), dark),
                      _typeChip('معلقة', Icons.hourglass_top_rounded, 'pending',
                          const Color(0xFFFF9100), dark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📊 ${filtered.length} معاملة',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          if (filteredIncome > 0)
                            Text(
                                '+${formatNumber(filteredIncome)} ${app.appCurrencySymbol}',
                                style: GoogleFonts.cairo(
                                    color: const Color(0xFF00E676),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                          if (filteredIncome > 0 && filteredExpense > 0)
                            const SizedBox(width: 12),
                          if (filteredExpense > 0)
                            Text(
                                '-${formatNumber(filteredExpense)} ${app.appCurrencySymbol}',
                                style: GoogleFonts.cairo(
                                    color: const Color(0xFFFF1744),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // List
        filtered.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text('لا توجد نتائج مطابقة',
                          style: GoogleFonts.cairo(
                              color: dark ? Colors.white38 : Colors.grey[400])),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final tx = filtered[i];
                      return _TxCard(
                        tx: tx,
                        app: app,
                        dark: dark,
                        onApprove: () => app.approveTransaction(tx.id),
                        onDelete: () => app.deleteTransaction(tx.id),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _chipBtn(Account? acc, String label, String value, String current,
      ValueChanged<String> onTap, bool dark) {
    final active = current == value;

    final color = acc != null ? acc.startColor : const Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () {
        Provider.of<AppProvider>(context, listen: false).playClick();
        onTap(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, active ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [color, acc != null ? acc.endColor : const Color(0xFF4C1D95)]
                : dark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? Colors.white.withOpacity(0.5)
                : (dark ? Colors.white12 : Colors.grey[200]!),
            width: active ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? color.withOpacity(0.5)
                  : Colors.black.withOpacity(0.05),
              blurRadius: active ? 12 : 4,
              offset: Offset(0, active ? 6 : 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (acc != null) ...[
              Text(acc.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ] else ...[
              Icon(Icons.account_balance_wallet_rounded,
                  size: 16,
                  color: active
                      ? Colors.white
                      : (dark ? Colors.white70 : Colors.grey[700])),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                color: active
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.grey[700]),
                fontSize: 13,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catChipBtn(String catRaw, String label, String value, String current,
      ValueChanged<String> onTap, bool dark) {
    final active = current == value;
    const color = Color(0xFF00E676);

    Widget leading;
    if (catRaw == 'all') {
      leading = Icon(Icons.category_rounded,
          size: 16,
          color: active
              ? Colors.white
              : (dark ? Colors.white70 : Colors.grey[700]));
    } else {
      final cData = CategoryData.parse(catRaw);
      if (cData.imagePath != null) {
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: kIsWeb
              ? Image.network(cData.imagePath!,
                  width: 16, height: 16, fit: BoxFit.cover)
              : Image.file(File(cData.imagePath!),
                  width: 16, height: 16, fit: BoxFit.cover),
        );
      } else {
        leading = Text(cData.icon, style: const TextStyle(fontSize: 14));
      }
    }

    return GestureDetector(
      onTap: () {
        Provider.of<AppProvider>(context, listen: false).playClick();
        onTap(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, active ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [color, const Color(0xFF00C853)]
                : dark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active
                  ? Colors.white.withOpacity(0.5)
                  : (dark ? Colors.white12 : Colors.grey[200]!),
              width: active ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
                color: active
                    ? color.withOpacity(0.5)
                    : Colors.black.withOpacity(0.05),
                blurRadius: active ? 12 : 4,
                offset: Offset(0, active ? 6 : 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.cairo(
                    color: active
                        ? Colors.white
                        : (dark ? Colors.white70 : Colors.grey[700]),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(
      String label, String icon, String value, Color color, bool dark,
      [StateSetter? setSheetState]) {
    final active = _filterDate == value;
    return GestureDetector(
      onTap: () {
        Provider.of<AppProvider>(context, listen: false).playClick();
        setState(() {
          _filterDate = value;
          _manualStartDate = null;
          _manualEndDate = null;
          _manualStartTime = null;
          _manualEndTime = null;
        });
        if (setSheetState != null) setSheetState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, active ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [color, color.withOpacity(0.8)]
                : dark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? Colors.white.withOpacity(0.5)
                : (dark ? Colors.white12 : Colors.grey[200]!),
            width: active ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: active
                    ? color.withOpacity(0.5)
                    : Colors.black.withOpacity(0.05),
                blurRadius: active ? 12 : 4,
                offset: Offset(0, active ? 6 : 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: active
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.grey[700]),
                fontSize: 13,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(
      String label, IconData icon, String value, Color color, bool dark) {
    // Made setSheetState optional
    final active = _filterType == value;
    return GestureDetector(
      onTap: () {
        // This will only be called from the main screen now
        Provider.of<AppProvider>(context, listen: false).playClick();
        setState(() {
          _filterType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, active ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [color, color.withOpacity(0.8)]
                : dark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? Colors.white.withOpacity(0.5)
                : (dark ? Colors.white12 : Colors.grey[200]!),
            width: active ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: active
                    ? color.withOpacity(0.5)
                    : Colors.black.withOpacity(0.05),
                blurRadius: active ? 12 : 4,
                offset: Offset(0, active ? 6 : 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: active
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.grey[700]),
                fontSize: 13,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? date,
    required Color color,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [color.withOpacity(0.2), color.withOpacity(0.05)]
                    : [color.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6))
              ],
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(date != null ? formatDate(date) : 'اختر تاريخ',
                        style: GoogleFonts.cairo(
                            color: dark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerButton({
    required String label,
    required TimeOfDay? time,
    required Color color,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [color.withOpacity(0.2), color.withOpacity(0.05)]
                    : [color.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6))
              ],
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        time != null
                            ? time
                                .format(context)
                                .replaceAll('AM', 'ص')
                                .replaceAll('PM', 'م')
                            : 'اختر وقت',
                        style: GoogleFonts.cairo(
                            color: dark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TxCard extends StatefulWidget {
  final Transaction tx;
  final AppProvider app;
  final bool dark;
  final VoidCallback onApprove, onDelete;

  const _TxCard({
    required this.tx,
    required this.app,
    required this.dark,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  State<_TxCard> createState() => _TxCardState();
}

class _TxCardState extends State<_TxCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final dark = widget.dark;
    final cardColor = dark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        dark ? Colors.white.withOpacity(0.07) : Colors.grey[200]!;

    // توحيد الألوان القوية لجميع الشاشات
    final isTransfer = tx.isTransfer;
    final isPending = tx.isPending;
    final isIncome = tx.isIncome;

    Color txColor;
    IconData txIcon;

    if (isTransfer) {
      txColor = const Color(0xFF00B0FF); // أزرق ساطع للتحويلات
      txIcon = Icons.sync_alt_rounded;
    } else if (isPending) {
      txColor = const Color(0xFFFF9100); // برتقالي للمعلق
      txIcon = Icons.hourglass_top_rounded;
    } else if (isIncome) {
      txColor = const Color(0xFF16A34A); // أخضر غامق واضح
      txIcon = Icons.arrow_upward_rounded;
    } else {
      txColor = const Color(0xFFDC2626); // أحمر غامق واضح
      txIcon = Icons.arrow_downward_rounded;
    }

    final acc = widget.app.accounts.firstWhere((a) => a.id == tx.accountId,
        orElse: () => widget.app.accounts.first);
    final sym = acc.currency == 'EGP' ? 'جنية' : acc.currency;

    final bool hasSecondary =
        acc.secondaryCurrency != null && acc.secondaryCurrency!.isNotEmpty;
    double secondaryAmount = 0.0;
    String secondarySymbol = '';
    if (hasSecondary) {
      secondaryAmount = widget.app
          .convertCurrency(tx.amount, acc.currency, acc.secondaryCurrency!);
      secondarySymbol =
          acc.secondaryCurrency == 'EGP' ? 'جنية' : acc.secondaryCurrency!;
    }

    final defaultStyle = GoogleFonts.cairo(
        color: dark ? Colors.white70 : Colors.grey[700],
        fontSize: 13,
        fontWeight: FontWeight.w700);

    final categoryName = CategoryData.parse(tx.category).name;

    Widget buildBadge(Widget leading, String text, [Color? color]) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 4),
            Text(text,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    List<Widget> buildAccBadges() {
      Widget makeBadge(Account a, {String? prefix}) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: a.startColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                  color: a.startColor.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 11, color: Colors.white),
              const SizedBox(width: 4),
              Text('${prefix ?? ''}${a.name}',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 2)
                      ])),
            ],
          ),
        );
      }

      if (tx.isTransfer) {
        final toAcc = widget.app.accounts.firstWhere(
            (a) => a.id == tx.toAccountId,
            orElse: () => widget.app.accounts.first);
        return [
          makeBadge(acc, prefix: 'من: '),
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9100), Color(0xFFFF1744)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFF1744).withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                textDirection: TextDirection.ltr, // إجبار السهم لليسار دائماً
                size: 18,
                color: Colors.white),
          ),
          makeBadge(toAcc, prefix: 'إلى: '),
        ];
      }
      return [makeBadge(acc, prefix: 'الحساب: ')];
    }

    final days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    final dayName = days[tx.date.weekday - 1];
    final time = DateFormat('h:mm a')
        .format(tx.date)
        .replaceAll('AM', 'ص')
        .replaceAll('PM', 'م');
    final dateStr = DateFormat('d/M/yyyy').format(tx.date);
    final detailedDate = '$dayName $dateStr، $time';

    return GestureDetector(
      onTap: () {
        if (tx.notes.isNotEmpty) {
          widget.app.playClick();
          setState(() => _expanded = !_expanded);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: txColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: txColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(txIcon, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(tx.description,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    shadows: [
                                      const Shadow(
                                          color: Colors.black26, blurRadius: 2)
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isTransfer ? '' : (isIncome ? '+' : '-')}${formatNumber(tx.amount)} $sym',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    shadows: [
                                      const Shadow(
                                          color: Colors.black26, blurRadius: 2)
                                    ],
                                  ),
                                ),
                                if (hasSecondary)
                                  Text(
                                    '${formatNumber(secondaryAmount)} $secondarySymbol',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...buildAccBadges(),
                            Builder(builder: (ctx) {
                              final cData = CategoryData.parse(tx.category);
                              Widget leading;
                              if (cData.imagePath != null) {
                                leading = ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: kIsWeb
                                      ? Image.network(cData.imagePath!,
                                          width: 12,
                                          height: 12,
                                          fit: BoxFit.cover)
                                      : Image.file(File(cData.imagePath!),
                                          width: 12,
                                          height: 12,
                                          fit: BoxFit.cover),
                                );
                              } else {
                                leading = Text(cData.icon,
                                    style: const TextStyle(fontSize: 11));
                              }
                              return buildBadge(
                                  leading, 'الفئة: $categoryName');
                            }),
                            buildBadge(
                                const Icon(Icons.calendar_today_rounded,
                                    size: 11, color: Colors.white),
                                'التاريخ: $detailedDate'),
                            buildBadge(
                                Icon(
                                    isPending
                                        ? Icons.hourglass_empty
                                        : Icons.check_circle,
                                    size: 11,
                                    color: Colors.white),
                                isPending ? 'الحالة: معلقة' : 'الحالة: مكتملة'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_expanded && tx.notes.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text('📝 ملاحظات: ${tx.notes}',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),

            // Always Visible Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  Divider(color: Colors.white.withOpacity(0.2), height: 12),
                  Row(
                    children: [
                      if (tx.isPending) ...[
                        Expanded(
                          child: Container(
                            height: 32, // تصغير صندوق الزر
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                widget.app.playClick();
                                widget.onApprove();
                              },
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 16, color: Color(0xFF16A34A)),
                              label: Text('اعتماد',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: const Color(0xFF16A34A))),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: const Color(0xFF16A34A),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Container(
                          height: 32, // تصغير صندوق الزر
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.app.playClick();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    AddTransactionSheet(existingTx: tx),
                              );
                            },
                            icon: const Icon(Icons.edit_rounded,
                                size: 16, color: Color(0xFF7C3AED)),
                            label: Text('تعديل',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: const Color(0xFF7C3AED))),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: const Color(0xFF7C3AED),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 32, // تصغير صندوق الزر
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.app.playClick();
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFF4C1D95)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: const Color(0xFF7C3AED)
                                                .withOpacity(0.5),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10))
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            color: Colors.amber, size: 48),
                                        const SizedBox(height: 16),
                                        Text('تأكيد الحذف',
                                            style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(
                                            'هل أنت متأكد أنك تريد حذف هذه المعاملة بشكل نهائي؟',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.cairo(
                                                color: Colors.white70,
                                                fontSize: 14)),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                                child: TextButton(
                                                    onPressed: () {
                                                      widget.app.playClick();
                                                      Navigator.pop(ctx);
                                                    },
                                                    child: Text('إلغاء',
                                                        style: GoogleFonts.cairo(
                                                            color:
                                                                Colors.white70,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)))),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12))),
                                                onPressed: () {
                                                  widget.app.playClick();
                                                  widget.app
                                                      .playVibrate(); // اهتزاز عند الحذف
                                                  Navigator.pop(ctx);
                                                  widget.onDelete();
                                                },
                                                child: Text('حذف',
                                                    style: GoogleFonts.cairo(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: Color(0xFFDC2626)),
                            label: Text('حذف',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: const Color(0xFFDC2626))),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: const Color(0xFFDC2626),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
