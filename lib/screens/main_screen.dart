// تم تنظيف الملف بالكامل وإضافة مؤثرات الـ 3D
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';
import 'onboarding_screen.dart';
import 'pin_screen.dart';
import '../utils/formatters.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final ValueNotifier<Offset> _touchPos = ValueNotifier(Offset.zero);
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _touchPos.dispose();
    super.dispose();
  }

  Widget _blurredBlob(double size, Color color, double blurRadius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _titles = [
    'MONEY BRAVO',
    'سجل المعاملات',
    'الحسابات',
    'التحليلات',
    'الإعدادات'
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: '🏠', label: 'الرئيسية'),
    _NavItem(icon: '📋', label: 'المعاملات'),
    _NavItem(icon: '🏦', label: 'الحسابات'),
    _NavItem(icon: '📊', label: 'التحليلات'),
    _NavItem(icon: '⚙️', label: 'الإعدادات'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddTransactionSheet() {
    context.read<AppProvider>().playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    if (app.loading) {
      return Scaffold(
        backgroundColor:
            dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
      );
    }
    if (!app.hasSeenTutorial) {
      return const OnboardingScreen();
    }
    if (app.appPin != null && !app.isPinUnlocked) {
      return const PinScreen(isSetup: false);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: Colors.transparent,
        elevation: 12,
        shadowColor: const Color(0xFF7C3AED).withOpacity(0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _titles[_selectedIndex],
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: _selectedIndex == 0 ? 24 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: _selectedIndex == 0 ? 2.0 : 0.0,
              shadows: const [
                Shadow(
                    color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
              ],
            ),
          ),
        ),
        leadingWidth: 130,
        leading: GestureDetector(
          onTap: () {
            app.playClick();
            final ctrl = TextEditingController(text: app.dollarRate.toString());
            showDialog(
              context: context,
              builder: (c) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.currency_exchange_rounded,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      Text('تعديل سعر الدولار',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                              child: TextButton(
                                  onPressed: () {
                                    app.playClick();
                                    Navigator.pop(c);
                                  },
                                  child: Text('إلغاء',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  onPressed: () {
                                    app.playClick();
                                    final val = double.tryParse(ctrl.text);
                                    if (val != null && val > 0) {
                                      app.saveDollarRate(val);
                                      Navigator.pop(c);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'تم تحديث السعر بنجاح! ✅',
                                                  style: GoogleFonts.cairo(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              backgroundColor: Colors.green));
                                    }
                                  },
                                  child: Text('حفظ',
                                      style: GoogleFonts.cairo(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF00E676).withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.currency_exchange_rounded,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سعر الدولار',
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                      Text(
                        // يحذف الأصفار الزائدة بذكاء (يعرض 50 أو 50.85)
                        '\$${app.dollarRate.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '')}',
                        textDirection: TextDirection.ltr,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              final notifCount = app.pendingCount;
              return GestureDetector(
                onTap: () {
                  app.playClick();
                  _showNotificationsMenu(context, app);
                },
                child: Container(
                  width: 76,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9100).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              color: Colors.white, size: 22),
                          if (notifCount > 0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF1744),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                        offset: Offset(0, 3))
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$notifCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('الإشعارات',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              height: 1)),
                    ],
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              app.playClick();
              context.read<ThemeProvider>().toggle();
            },
            child: Container(
              width: 76,
              margin:
                  const EdgeInsets.only(left: 8, right: 4, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF2979FF), const Color(0xFF311B92)]
                      : [const Color(0xFFFFC107), const Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: dark
                        ? const Color(0xFF2979FF).withOpacity(0.4)
                        : const Color(0xFFFFC107).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(dark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(height: 6),
                  Text(dark ? 'ليلي' : 'نهاري',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Listener(
        onPointerHover: (event) => _touchPos.value = event.localPosition,
        onPointerMove: (event) => _touchPos.value = event.localPosition,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_animCtrl, _touchPos]),
              builder: (context, child) {
                final val = _animCtrl.value * 2 * math.pi;
                final px = (_touchPos.value.dx -
                        MediaQuery.of(context).size.width / 2) *
                    0.05;
                final py = (_touchPos.value.dy -
                        MediaQuery.of(context).size.height / 2) *
                    0.05;

                return Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -100 + math.sin(val) * 50 + py,
                        right: -50 + math.cos(val) * 50 + px,
                        child: _blurredBlob(
                            300,
                            const Color(0xFF7C3AED)
                                .withOpacity(dark ? 0.3 : 0.2),
                            80),
                      ),
                      Positioned(
                        bottom: 100 + math.cos(val) * 50 - py,
                        left: -50 + math.sin(val) * 50 - px,
                        child: _blurredBlob(
                            300,
                            const Color(0xFF9333EA)
                                .withOpacity(dark ? 0.3 : 0.2),
                            80),
                      ),
                    ],
                  ),
                );
              },
            ),
            IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex != 4
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: FloatingActionButton(
                onPressed: _showAddTransactionSheet,
                backgroundColor: Colors.transparent,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 32),
              ),
            )
          : null,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.read<AppProvider>().playClick();
                      setState(() => _selectedIndex = i);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.all(isActive ? 6 : 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isActive
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.transparent,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                              border: isActive
                                  ? Border.all(
                                      color: Colors.white.withOpacity(0.6),
                                      width: 1.5)
                                  : Border.all(
                                      color: Colors.transparent, width: 1.5),
                            ),
                            child: Text(item.icon,
                                style: TextStyle(fontSize: isActive ? 28 : 24)),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.cairo(
                              fontSize: isActive ? 13 : 11,
                              fontWeight:
                                  isActive ? FontWeight.w900 : FontWeight.w600,
                              color: isActive ? Colors.white : Colors.white70,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsMenu(BuildContext context, AppProvider app) {
    final pendingTxs = app.transactions.where((t) => t.isPending).toList();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 8, sigmaY: 8), // تقليل لتسريع ظهور الإشعارات
          child: SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED).withOpacity(0.9),
                          const Color(0xFF4C1D95).withOpacity(0.95)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.25),
                          blurRadius: 50,
                          offset: const Offset(0, 20),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32)),
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.2))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Colors.white,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('مركز الإشعارات',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900)),
                                    Text(
                                        pendingTxs.isEmpty
                                            ? 'لا توجد تنبيهات جديدة'
                                            : 'لديك ${pendingTxs.length} تنبيهات',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white70, size: 22),
                                onPressed: () {
                                  app.playClick();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Body
                        if (pendingTxs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40, horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📭',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text('صندوق الإشعارات فارغ',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('كل شيء على ما يرام!',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: pendingTxs.length,
                              itemBuilder: (context, index) {
                                final tx = pendingTxs[index];
                                final acc = app.accounts.firstWhere(
                                    (a) => a.id == tx.accountId,
                                    orElse: () => app.accounts.first);

                                final sym = acc.currency == 'EGP'
                                    ? 'جنية'
                                    : acc.currency;
                                final bool hasSecondary =
                                    acc.secondaryCurrency != null &&
                                        acc.secondaryCurrency!.isNotEmpty;
                                double secondaryAmount = 0.0;
                                String secondarySymbol = '';
                                if (hasSecondary) {
                                  secondaryAmount = app.convertCurrency(
                                      tx.amount,
                                      acc.currency,
                                      acc.secondaryCurrency!);
                                  secondarySymbol =
                                      acc.secondaryCurrency == 'EGP'
                                          ? 'جنية'
                                          : acc.secondaryCurrency!;
                                }

                                Widget buildAccChip(Account a) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: [a.startColor, a.endColor]),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.8),
                                          width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                            color: a.endColor.withOpacity(0.4),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: Text(
                                      a.name,
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF9100)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                                Icons.hourglass_top_rounded,
                                                color: Color(0xFFFF9100),
                                                size: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                                'معاملة معلقة للـ ${tx.isIncome ? 'إيداع' : tx.isTransfer ? 'تحويل' : 'سحب'}',
                                                style: GoogleFonts.cairo(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _rowDetail(
                                                'الوصف:', tx.description),
                                            _rowDetail('المبلغ:',
                                                '${formatNumber(tx.amount)} $sym ${hasSecondary ? '(${formatNumber(secondaryAmount)} $secondarySymbol)' : ''}'),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('الحساب:',
                                                      style: GoogleFonts.cairo(
                                                          color: Colors.white54,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w800)),
                                                  const SizedBox(width: 8),
                                                  buildAccChip(acc),
                                                ],
                                              ),
                                            ),
                                            if (tx.isTransfer)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 6),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('إلى حساب:',
                                                        style:
                                                            GoogleFonts.cairo(
                                                                color: Colors
                                                                    .white54,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800)),
                                                    const SizedBox(width: 8),
                                                    buildAccChip(app.accounts
                                                        .firstWhere(
                                                            (a) =>
                                                                a.id ==
                                                                tx.toAccountId,
                                                            orElse: () => app
                                                                .accounts
                                                                .first)),
                                                  ],
                                                ),
                                              )
                                            else
                                              _rowDetail(
                                                  'الفئة:',
                                                  CategoryData.parse(
                                                          tx.category)
                                                      .name),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF10B981),
                                                    Color(0xFF047857)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF10B981)
                                                            .withOpacity(0.6),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  )
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  app.playClick();
                                                  app.approveTransaction(tx.id);
                                                  if (pendingTxs.length == 1) {
                                                    Navigator.pop(context);
                                                  }
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              'تم الاعتماد بنجاح ✅',
                                                              style: GoogleFonts.cairo(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFF10B981)));
                                                },
                                                icon: const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Colors.white,
                                                    size: 22),
                                                label: Text('إكمال',
                                                    style: GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white,
                                                        fontSize: 15)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF1744),
                                                    Color(0xFFC62828)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFFF1744)
                                                            .withOpacity(0.6),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  )
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  app.playClick();
                                                  app.deleteTransaction(tx.id);
                                                  if (pendingTxs.length == 1) {
                                                    Navigator.pop(context);
                                                  }
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              'تم الحذف 🗑️',
                                                              style: GoogleFonts.cairo(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFFFF1744)));
                                                },
                                                icon: const Icon(
                                                    Icons.delete_rounded,
                                                    color: Colors.white,
                                                    size: 22),
                                                label: Text('حذف',
                                                    style: GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white,
                                                        fontSize: 15)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * anim1.value),
            alignment: AlignmentDirectional.topStart,
            child: child,
          ),
        );
      },
    );
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
