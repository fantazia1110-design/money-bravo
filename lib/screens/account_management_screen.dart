import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';
import '../widgets/manage_account_sheet.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _touchPos = ValueNotifier(Offset.zero);
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
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

  void _showAccountEditor(BuildContext context, AppProvider app, bool dark,
      [Account? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageAccountSheet(existingAccount: existing),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider app, Account acc) {
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
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
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
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Text('تأكيد الحذف',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('هل أنت متأكد من حذف حساب "${acc.name}"؟',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
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
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          onPressed: () {
                            app.playClick();
                            app.deleteAccount(acc.id);
                            Navigator.pop(c);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تم حذف الحساب بنجاح 🗑️',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.redAccent));
                          },
                          child: Text('حذف',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    final textColor = dark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        title: Text('إدارة الحسابات',
            style: GoogleFonts.cairo(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(
            color: Color(0xFF7C3AED)), // زر الرجوع باللون الموف
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
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.accounts.length,
              itemBuilder: (context, index) {
                final acc = app.accounts[index];
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
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                        colors: [acc.startColor, acc.endColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: acc.startColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8))
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
                              : Text(acc.icon,
                                  style: const TextStyle(fontSize: 100)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1.5),
                                  ),
                                  child: acc.imagePath != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: kIsWeb
                                              ? Image.network(acc.imagePath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Center(
                                                      child: Text(acc.icon,
                                                          style: const TextStyle(
                                                              fontSize: 26))))
                                              : Image.file(File(acc.imagePath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Center(
                                                      child: Text(acc.icon,
                                                          style: const TextStyle(fontSize: 26)))))
                                      : Center(child: Text(acc.icon, style: const TextStyle(fontSize: 26))),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(acc.name,
                                          style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                              shadows: [
                                                Shadow(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    blurRadius: 8)
                                              ])),
                                      Text(
                                          '${formatNumber(acc.balance)} $nativeSymbol',
                                          style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    blurRadius: 10)
                                              ])),
                                      if (hasSecondary)
                                        Text(
                                            '${formatNumber(secondaryBalance)} $secondarySymbol',
                                            style: GoogleFonts.cairo(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                shadows: [
                                                  Shadow(
                                                      color: Colors.white
                                                          .withOpacity(0.4),
                                                      blurRadius: 8)
                                                ])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton.icon(
                                        icon: const Icon(Icons.edit_rounded,
                                            color: Colors.white, size: 18),
                                        label: Text('تعديل',
                                            style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.white.withOpacity(0.2),
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        onPressed: () {
                                          app.playClick();
                                          _showAccountEditor(
                                              context, app, dark, acc);
                                        })),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: ElevatedButton.icon(
                                        icon: const Icon(Icons.delete_rounded,
                                            color: Colors.white, size: 18),
                                        label: Text('حذف',
                                            style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent
                                                .withOpacity(0.8),
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        onPressed: () {
                                          app.playClick();
                                          _confirmDelete(context, app, acc);
                                        })),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          app.playClick();
          _showAccountEditor(context, app, dark);
        },
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('إضافة حساب',
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
