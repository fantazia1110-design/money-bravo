import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/category_management_screen.dart';
import '../screens/account_management_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/pin_screen.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    Widget buildSectionHeader(String title, IconData icon, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 12, right: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.cairo(
                    color: dark ? Colors.white : Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        buildSectionHeader('الحساب والأمان 🛡️',
            Icons.admin_panel_settings_rounded, const Color(0xFF7C3AED)),
        _buildSettingCard(
          context,
          title: 'الملف الشخصي والحماية 👤',
          subtitle: 'تعديل الاسم، الإيميل، وكلمة المرور',
          icon: Icons.person_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
        ),
        _buildSettingCard(
          context,
          title: 'رمز الدخول (PIN) 🔢',
          subtitle: app.appPin == null
              ? 'إعداد رمز مرور لزيادة الأمان'
              : 'تغيير أو إلغاء رمز المرور الحالي',
          icon: Icons.pin_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PinScreen(
                        isSetup: app.appPin == null,
                        isChange: app.appPin != null)));
          },
        ),
        const SizedBox(height: 24),
        buildSectionHeader('الإدارة المالية 💰',
            Icons.account_balance_wallet_rounded, const Color(0xFF00C853)),
        _buildSettingCard(
          context,
          title: 'إدارة الحسابات 🏦',
          subtitle: 'إضافة وتعديل الحسابات، الألوان، والعملات',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF00C853),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AccountManagementScreen())),
        ),
        _buildSettingCard(
          context,
          title: 'إدارة الفئات 🛒',
          subtitle: 'إضافة فئات للمصروفات والدخل',
          icon: Icons.category_rounded,
          color: const Color(0xFF00C853),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen())),
        ),
        const SizedBox(height: 24),
        buildSectionHeader('العملات والأسعار 🌍',
            Icons.currency_exchange_rounded, const Color(0xFF00B0FF)),
        _buildSettingCard(
          context,
          title: 'العملة الرئيسية للبرنامج 💵',
          subtitle:
              'العملة الحالية: ${globalCurrencies.firstWhere((c) => c.contains(app.appCurrency), orElse: () => app.appCurrencySymbol)}',
          icon: Icons.monetization_on_rounded,
          color: const Color(0xFF00B0FF),
          onTap: () {
            showDialog(
              context: context,
              builder: (c) {
                String searchQuery = '';
                return StatefulBuilder(builder: (context, setDialogState) {
                  final filtered = globalCurrencies
                      .where((cur) =>
                          cur
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()) ||
                          cur.contains(searchQuery))
                      .toList();
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                          TextField(
                            onChanged: (v) =>
                                setDialogState(() => searchQuery = v),
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'بحث عن عملة...',
                              hintStyle:
                                  GoogleFonts.cairo(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final curFull = filtered[i];
                                final curCode =
                                    curFull.split('(').last.replaceAll(')', '');
                                final isLast = i == filtered.length - 1;
                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : Border(
                                            bottom: BorderSide(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1.5)),
                                  ),
                                  child: ListTile(
                                    title: Text(curFull,
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    trailing: app.appCurrency == curCode
                                        ? const Icon(Icons.check_circle,
                                            color: Color(0xFF00E676))
                                        : null,
                                    onTap: () {
                                      app.playClick();
                                      app.setAppCurrency(curCode);
                                      Navigator.pop(c);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          },
        ),
        _buildSettingCard(
          context,
          title: 'تعديل سعر الصرف يدوياً 💱',
          subtitle: 'تعديل سعر الدولار بشكل يدوي للتحويلات',
          icon: Icons.edit_note_rounded,
          color: const Color(0xFF00B0FF),
          onTap: () {
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
                      const Icon(Icons.edit_note_rounded,
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
                                                  'تم تحديث السعر يدوياً! ✅',
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
        ),
        const SizedBox(height: 24),
        buildSectionHeader(
            'التفضيلات العامة ⚙️', Icons.tune_rounded, const Color(0xFFFF9100)),
        _buildToggleCard(
          context,
          title: 'الأصوات والاهتزاز 🔔',
          subtitle: 'تفعيل أصوات التفاعل والاهتزاز في التطبيق',
          icon: app.hapticEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          color: const Color(0xFFFF9100), // لون برتقالي مميز
          value: app.hapticEnabled,
          onChanged: (val) {
            app.toggleHaptic(val);
            if (val) {
              app.playClick(); // تجربة الصوت فور التفعيل
            }
          },
        ),
        const SizedBox(height: 24),
        buildSectionHeader('المنطقة الخطرة ⚠️', Icons.warning_rounded,
            const Color(0xFFB71C1C)),
        _buildSettingCard(
          context,
          title: 'مسح المعاملات والسجل ⚠️',
          subtitle:
              'حذف جميع المعاملات وسجل النشاطات فقط (إجراء لا يمكن التراجع عنه)',
          icon: Icons.delete_sweep_rounded,
          color: const Color(0xFFB71C1C), // أحمر داكن
          onTap: () {
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
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text('تأكيد مسح المعاملات',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'هل أنت متأكد أنك تريد مسح جميع المعاملات وسجل النشاطات؟ (سيبقى الحساب والفئات كما هي)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 14)),
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
                                      backgroundColor: const Color(0xFFB71C1C),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  onPressed: () {
                                    app.playClick();
                                    app.clearAllTransactionsAndLogs();
                                    Navigator.pop(c);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'تم مسح المعاملات والسجل بنجاح ✅',
                                                style: GoogleFonts.cairo(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            backgroundColor:
                                                const Color(0xFFB71C1C)));
                                  },
                                  child: Text('مسح',
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
          },
        ),
        _buildSettingCard(
          context,
          title: 'ضبط المصنع (مسح كل شيء) 🚨',
          subtitle: 'حذف الحسابات، المعاملات، وإعادة التطبيق للصفر (خطر جداً)',
          icon: Icons.restore_rounded,
          color: const Color(0xFFB71C1C), // أحمر داكن
          onTap: () {
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
                      const Icon(Icons.restore_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text('تأكيد ضبط المصنع',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'هل أنت متأكد أنك تريد مسح جميع الحسابات والمعاملات والعودة للبداية؟ (لا يمكن التراجع)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 14)),
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
                                      backgroundColor: const Color(0xFFB71C1C),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  onPressed: () {
                                    app.playClick();
                                    app.factoryReset();
                                    Navigator.pop(c);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'تمت إعادة ضبط التطبيق للصفر بنجاح 🗑️',
                                                style: GoogleFonts.cairo(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            backgroundColor: Colors.redAccent));
                                  },
                                  child: Text('مسح',
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
          },
        ),
        _buildSettingCard(
          context,
          title: 'تسجيل الخروج 🚪⚠️',
          subtitle: 'تسجيل الخروج من الحساب الحالي (سيطلب كلمة المرور للعودة)',
          icon: Icons.logout_rounded,
          color: const Color(0xFFB71C1C), // أحمر داكن
          onTap: () {
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
                      const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text('تأكيد الخروج',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 14)),
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
                                      backgroundColor: const Color(0xFFB71C1C),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  onPressed: () async {
                                    app.playClick();
                                    Navigator.pop(c);
                                    await context.read<AuthService>().signOut();
                                  },
                                  child: Text('تسجيل الخروج',
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
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSettingCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    // تصميم الكارت بنظام 3D المضيء مع حواف بيضاء واضحة
    return GestureDetector(
      onTap: () {
        context.read<AppProvider>().playClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2.5),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.2), blurRadius: 10)
                  ]),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Colors.black26, blurRadius: 4)
                          ])),
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.8), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () {
        context.read<AppProvider>().playClick();
        onChanged(!value);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2.5),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.2), blurRadius: 10)
                  ]),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Colors.black26, blurRadius: 4)
                          ])),
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (val) {
                context.read<AppProvider>().playClick();
                onChanged(val);
              },
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF00E676),
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
