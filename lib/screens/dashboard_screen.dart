import 'dart:io';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // ربط مستلم الإشعارات بمجرد فتح الشاشة الرئيسية
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<AppProvider>().onNewNotification = _showNotificationPopup;

      // فحص ذكي: إذا كان هذا الهاتف جديداً ولم يسجل اسمه بعد
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('device_user_name') == null && mounted) {
        _showNamePrompt();
      }
    });
  }

  void _showNamePrompt() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible:
          false, // إجبار المستخدم على إدخال اسمه ولا يمكنه تخطيها
      builder: (c) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF4C1D95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👤', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                Text('من أنت؟',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    'يبدو أنك تستخدم التطبيق من هاتف جديد، يرجى إدخال اسمك لتمييز معاملاتك عن باقي الشركاء.',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'اكتب اسمك هنا...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        context
                            .read<AppProvider>()
                            .saveDeviceName(nameCtrl.text.trim());
                        Navigator.pop(c);
                      }
                    },
                    child: Text('حفظ والمتابعة',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationPopup(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        backgroundColor: const Color(0xFF4C1D95),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(body,
                      style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    if (app.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
    }

    final cardColor = dark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder =
        dark ? Colors.white.withOpacity(0.07) : Colors.grey[200]!;
    final textColor = dark ? Colors.white : const Color(0xFF1E293B);
    final subColor = dark ? Colors.white38 : Colors.grey[400]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('مرحباً، ${app.displayName} 👋',
                    style: GoogleFonts.cairo(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF00E676).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('متصل',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${app.activeUsersCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              height: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _heroCard(app, app.netBalance, app.totalIncome, app.totalExpense),
          const SizedBox(height: 24),
          Text('حساباتي 🏦',
              style: GoogleFonts.cairo(
                  color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  0.70, // إعطاء مساحة طولية أكبر لمنع تداخل النصوص
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: app.accounts.length,
            itemBuilder: (_, i) =>
                _AccountMiniCard(account: app.accounts[i], app: app),
          ),
          const SizedBox(height: 24),
          _WeeklyChartCard(app: app, dark: dark, textColor: textColor),
          const SizedBox(height: 24),
          Text('أحدث المعاملات 🕐',
              style: GoogleFonts.cairo(
                  color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final displayTxs = app.transactions.take(5).toList();
            if (displayTxs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
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
                      color: Colors.white.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text('لا توجد معاملات بعد',
                        style:
                            GoogleFonts.cairo(color: subColor, fontSize: 14)),
                    Text('اضغط على + لإضافة أول حركة',
                        style:
                            GoogleFonts.cairo(color: subColor, fontSize: 12)),
                  ],
                ),
              );
            }
            return Column(
              children: displayTxs
                  .map((tx) => _RecentTxRow(tx: tx, app: app, dark: dark))
                  .toList(),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _heroCard(
      AppProvider app, double netBalance, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF7E22CE),
            Color(0xFF3730A3)
          ], // from-violet-600 via-purple-700 to-indigo-800
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.0)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -32,
            child: Container(
              width: 160, // w-40
              height: 160, // h-40
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.0)
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('إجمالي الرصيد الصافي',
                      style: GoogleFonts.cairo(
                          color: Colors.purple[100],
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
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
                      formatNumber(netBalance),
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: [
                            Shadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 20)
                          ]),
                    ),
                    const SizedBox(width: 8),
                    Text(app.appCurrencySymbol,
                        style: GoogleFonts.cairo(
                            color: Colors.purple[100],
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                  color: Colors.purple[100]!.withOpacity(0.5),
                                  blurRadius: 10)
                            ])),
                  ],
                ),
              ),
              if (app.pendingCount > 0) ...[
                const SizedBox(height: 16), // mb-4
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4), // px-3 py-1
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24), // rounded-full
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  ),
                  child: Text('⏳ ${app.pendingCount} معاملة معلقة',
                      style: GoogleFonts.cairo(
                          color: const Color(0xFFFCD34D),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
              const SizedBox(height: 16),
              Column(
                children: [
                  _statChip(
                      'إجمالي الدخل',
                      formatNumber(income),
                      app.appCurrencySymbol,
                      const Color(0xFF00E676),
                      Colors.white.withOpacity(0.9),
                      '⬆️'),
                  const SizedBox(height: 16),
                  _statChip(
                      'إجمالي المصروف',
                      formatNumber(expense),
                      app.appCurrencySymbol,
                      const Color(0xFFFF1744),
                      Colors.white.withOpacity(0.9),
                      '⬇️'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, String currency, Color color,
      Color titleColor, String iconText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(iconText, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: GoogleFonts.cairo(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            shadows: [
                              Shadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 12)
                            ]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currency,
                        style: GoogleFonts.cairo(
                            color: titleColor,
                            fontSize: 16,
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
}

class _AccountMiniCard extends StatelessWidget {
  final Account account;
  final AppProvider app;
  const _AccountMiniCard({required this.account, required this.app});

  @override
  Widget build(BuildContext context) {
    final String nativeCurrency = account.currency;
    final String nativeSymbol =
        nativeCurrency == 'EGP' ? 'جنية' : nativeCurrency;

    final bool hasSecondary = account.secondaryCurrency != null &&
        account.secondaryCurrency!.isNotEmpty;
    double secondaryBalance = 0.0;
    String secondarySymbol = '';
    if (hasSecondary) {
      secondaryBalance = app.convertCurrency(
          account.balance, nativeCurrency, account.secondaryCurrency!);
      secondarySymbol = account.secondaryCurrency == 'EGP'
          ? 'جنية'
          : account.secondaryCurrency!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [account.startColor, account.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: account.startColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            top: -10,
            child: Opacity(
              opacity: 0.15,
              child: account.imagePath != null
                  ? SizedBox(
                      width: 80,
                      height: 80,
                      child: kIsWeb
                          ? Image.network(account.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Text(account.icon,
                                  style: const TextStyle(fontSize: 70)))
                          : Image.file(File(account.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Text(account.icon,
                                  style: const TextStyle(fontSize: 70))),
                    )
                  : Text(account.icon, style: const TextStyle(fontSize: 70)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: account.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(account.imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Center(
                                        child: Text(account.icon,
                                            style:
                                                const TextStyle(fontSize: 20))))
                                : Image.file(File(account.imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Center(
                                        child: Text(account.icon,
                                            style: const TextStyle(
                                                fontSize: 20)))))
                        : Center(
                            child: Text(account.icon,
                                style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      account.name,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                          shadows: [
                            Shadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8)
                          ]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasSecondary) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                            '${formatNumber(account.balance)} $nativeSymbol',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                    color: Colors.white.withOpacity(0.6),
                                    blurRadius: 10)
                              ],
                            )),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                            '${formatNumber(secondaryBalance)} $secondarySymbol',
                            style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 8)
                                ])),
                      ),
                    ] else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                            '${formatNumber(account.balance)} $nativeSymbol',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                    color: Colors.white.withOpacity(0.6),
                                    blurRadius: 10)
                              ],
                            )),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTxRow extends StatefulWidget {
  final Transaction tx;
  final AppProvider app;
  final bool dark;

  const _RecentTxRow({
    required this.tx,
    required this.app,
    required this.dark,
  });

  @override
  State<_RecentTxRow> createState() => _RecentTxRowState();
}

class _RecentTxRowState extends State<_RecentTxRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final app = widget.app;
    final dark = widget.dark;

    final isTransfer = tx.isTransfer;
    final isPending = tx.isPending;
    final isIncome = tx.isIncome;

    Color txColor;
    IconData txIcon;

    if (isTransfer) {
      txColor = const Color(0xFF00B0FF);
      txIcon = Icons.sync_alt_rounded;
    } else if (isPending) {
      txColor = const Color(0xFFFF9100);
      txIcon = Icons.hourglass_top_rounded;
    } else if (isIncome) {
      txColor = const Color(0xFF16A34A); // أخضر غامق واضح
      txIcon = Icons.arrow_upward_rounded;
    } else {
      txColor = const Color(0xFFDC2626); // أحمر غامق واضح
      txIcon = Icons.arrow_downward_rounded;
    }

    final acc = app.accounts.firstWhere((a) => a.id == tx.accountId,
        orElse: () => app.accounts.first);
    final sym = acc.currency == 'EGP' ? 'جنية' : acc.currency;

    final bool hasSecondary =
        acc.secondaryCurrency != null && acc.secondaryCurrency!.isNotEmpty;
    double secondaryAmount = 0.0;
    String secondarySymbol = '';
    if (hasSecondary) {
      secondaryAmount =
          app.convertCurrency(tx.amount, acc.currency, acc.secondaryCurrency!);
      secondarySymbol =
          acc.secondaryCurrency == 'EGP' ? 'جنية' : acc.secondaryCurrency!;
    }

    final categoryName = CategoryData.parse(tx.category).name;

    Widget buildBadge(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
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
        final toAcc = app.accounts.firstWhere((a) => a.id == tx.toAccountId,
            orElse: () => app.accounts.first);
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

    final borderColor =
        dark ? Colors.white.withOpacity(0.07) : Colors.grey[200]!;

    return GestureDetector(
      onTap: () {
        if (tx.notes.isNotEmpty) {
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
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(txIcon, color: Colors.white, size: 14),
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
                                    fontSize: 14,
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
                                    fontSize: 15,
                                    shadows: [
                                      const Shadow(
                                          color: Colors.black26, blurRadius: 2)
                                    ],
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
                            buildBadge(
                                Icons.category_rounded, 'الفئة: $categoryName'),
                            buildBadge(Icons.calendar_today_rounded,
                                'التاريخ: $detailedDate'),
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
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
          ],
        ),
      ),
    );
  }
}

class _WeeklyChartCard extends StatefulWidget {
  final AppProvider app;
  final bool dark;
  final Color textColor;
  const _WeeklyChartCard(
      {required this.app, required this.dark, required this.textColor});

  @override
  State<_WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<_WeeklyChartCard>
    with SingleTickerProviderStateMixin {
  bool showIncome = true;
  bool showExpense = true;
  bool showTransfer = true;

  final ValueNotifier<Offset> _touchPos = ValueNotifier(Offset.zero);
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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

  Widget _buildLegend(
      Color color, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: active ? 1.0 : 0.3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.cairo(
                    color: widget.dark ? Colors.white70 : Colors.grey[800],
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) => _touchPos.value = event.localPosition,
      onPointerMove: (event) => _touchPos.value = event.localPosition,
      behavior: HitTestBehavior.translucent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.dark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[200]!,
              width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7C3AED)
                    .withOpacity(widget.dark ? 0.15 : 0.05),
                blurRadius: 30,
                offset: const Offset(0, 15))
          ],
        ),
        child: Stack(
          children: [
            // الخلفية العائمة 3D (Animated Aurora) التفاعلية
            AnimatedBuilder(
              animation: Listenable.merge([_animCtrl, _touchPos]),
              builder: (context, child) {
                final val = _animCtrl.value * 2 * math.pi;
                // حساب تأثير اختلاف المنظور (Parallax) بناءً على موقع اللمس
                final px = (_touchPos.value.dx - 150) * 0.05;
                final py = (_touchPos.value.dy - 150) * 0.05;

                return Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -60 + math.sin(val) * 40 + py,
                        right: -40 + math.cos(val) * 40 + px,
                        child: _blurredBlob(
                            200,
                            const Color(0xFF7C3AED)
                                .withOpacity(widget.dark ? 0.2 : 0.1),
                            80),
                      ),
                      Positioned(
                        bottom: -60 + math.cos(val) * 40 - py,
                        left: -40 + math.sin(val * 2) * 30 - px,
                        child: _blurredBlob(
                            220,
                            const Color(0xFF9333EA)
                                .withOpacity(widget.dark ? 0.2 : 0.1),
                            80),
                      ),
                      Positioned(
                        top: 40 + math.sin(val + math.pi) * 50 + py * 0.5,
                        left: 20 + math.cos(val + math.pi) * 50 + px * 0.5,
                        child: _blurredBlob(
                            160,
                            const Color(0xFF6D28D9)
                                .withOpacity(widget.dark ? 0.15 : 0.05),
                            80),
                      ),
                    ],
                  ),
                );
              },
            ),
            // محتوى الرسم البياني (النصوص والخطوط)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الرسم البياني للأسبوع 📈',
                          style: GoogleFonts.cairo(
                              color: widget.textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildLegend(
                              const Color(0xFF00E676), 'دخل', showIncome, () {
                            setState(() => showIncome = !showIncome);
                          }),
                          _buildLegend(
                              const Color(0xFFFF1744), 'مصروف', showExpense,
                              () {
                            setState(() => showExpense = !showExpense);
                          }),
                          _buildLegend(
                              const Color(0xFF00B0FF), 'تحويل', showTransfer,
                              () {
                            setState(() => showTransfer = !showTransfer);
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: _WeeklyChart(
                      app: widget.app,
                      dark: widget.dark,
                      showIncome: showIncome,
                      showExpense: showExpense,
                      showTransfer: showTransfer,
                    ),
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

class _WeeklyChart extends StatelessWidget {
  final AppProvider app;
  final bool dark;
  final bool showIncome;
  final bool showExpense;
  final bool showTransfer;

  const _WeeklyChart({
    required this.app,
    required this.dark,
    required this.showIncome,
    required this.showExpense,
    required this.showTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final data = _buildData();

    double maxY = 0;
    for (var d in data) {
      if (showIncome && d.income > maxY) maxY = d.income;
      if (showExpense && d.expense > maxY) maxY = d.expense;
      if (showTransfer && d.transfer > maxY) maxY = d.transfer;
    }
    if (maxY == 0) maxY = 1000;
    maxY = maxY * 1.25; // إعطاء مساحة إضافية أعلى الخطوط
    double minY = 0; // تم تعديل الصفر ليكون ثابتاً لحل مشكلة التدرج اللوني

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: minY,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => dark
                ? const Color(0xFF0F172A).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            fitInsideHorizontally: true, // يمنع خروج مربع التفاصيل من الشاشة
            fitInsideVertically: true, // يمنع خروجه من الأعلى أو الأسفل
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tooltipMargin: 16,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                final isExpense = spot.barIndex == 1;
                final color = isIncome
                    ? const Color(0xFF00E676)
                    : isExpense
                        ? const Color(0xFFFF1744)
                        : const Color(0xFF00B0FF);
                final title = isIncome
                    ? 'إجمالي الدخل'
                    : isExpense
                        ? 'إجمالي المصروف'
                        : 'إجمالي التحويلات';
                return LineTooltipItem(
                  '$title\n',
                  GoogleFonts.cairo(
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: formatNumber(spot.y),
                      style: GoogleFonts.cairo(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: ' ${app.appCurrencySymbol}',
                      style: GoogleFonts.cairo(
                        color: dark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: false, // جعل الرسم البياني يسبح في الهواء
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(data[i].label,
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white54 : Colors.grey[500])),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (showIncome)
            _buildLineChartBarData(
              values: data.map((e) => e.income).toList(),
              colors: const [
                Color(0xFF00E676),
                Color(0xFF00C853)
              ], // أخضر طبيعي صافي
              isCurved: true,
              barWidth: 4.0,
            ),
          if (showExpense)
            _buildLineChartBarData(
              values: data.map((e) => e.expense).toList(),
              colors: const [
                Color(0xFFFF1744),
                Color(0xFFD50000)
              ], // أحمر طبيعي صافي
              isCurved: true,
              barWidth: 4.0,
            ),
          if (showTransfer)
            _buildLineChartBarData(
              values: data.map((e) => e.transfer).toList(),
              colors: const [Color(0xFF00B0FF), Color(0xFF0081CB)], // أزرق ساطع
              isCurved: true,
              barWidth: 4.0,
            ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  LineChartBarData _buildLineChartBarData({
    required List<double> values,
    required List<Color> colors,
    bool isCurved = false,
    bool isStepLineChart = false,
    List<int>? dashArray,
    double barWidth = 4.5,
  }) {
    return LineChartBarData(
      spots: values
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: isCurved,
      isStepLineChart: isStepLineChart,
      curveSmoothness: isCurved ? 0.35 : 0.0,
      dashArray: dashArray,
      gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight),
      barWidth: barWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: isStepLineChart ? 3 : 4,
          color: Colors.white,
          strokeWidth: isStepLineChart ? 2 : 3,
          strokeColor: colors.first,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.15)).toList(),
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  List<_DayData> _buildData() {
    double getInMainCurrency(Transaction t) {
      final acc = app.accounts.firstWhere((a) => a.id == t.accountId,
          orElse: () => app.accounts.first);
      return app.convertCurrency(t.amount, acc.currency, app.appCurrency);
    }

    final transactions = app.transactions;

    DateTime refDate = DateTime.now();
    final hasRecent = transactions.any((t) =>
        t.date.isAfter(DateTime.now().subtract(const Duration(days: 7))));
    if (!hasRecent && transactions.isNotEmpty) {
      refDate = transactions
          .map((t) => t.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    return List.generate(7, (i) {
      final day = refDate.subtract(Duration(days: 6 - i));
      final dayTxs = transactions.where((t) =>
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day &&
          !t.isPending);
      return _DayData(
        label: '${day.day}/${day.month}',
        income: dayTxs
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + getInMainCurrency(t)),
        expense: dayTxs
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + getInMainCurrency(t)),
        transfer: dayTxs
            .where((t) => t.isTransfer)
            .fold(0.0, (s, t) => s + getInMainCurrency(t)),
      );
    });
  }
}

class _DayData {
  final String label;
  final double income, expense, transfer;
  _DayData(
      {required this.label,
      required this.income,
      required this.expense,
      required this.transfer});
}
