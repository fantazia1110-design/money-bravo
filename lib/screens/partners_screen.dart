import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/manage_account_sheet.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    // فلترة وجلب حسابات الشركاء فقط
    final partners = app.accounts.where((a) => a.isPartner).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان وزر إضافة شريك جديد
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الشركاء 🤝',
                  style: GoogleFonts.cairo(
                      color: dark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              ElevatedButton.icon(
                onPressed: () {
                  app.playClick();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    // نرسل isForPartner = true لفتح وضع الشريك
                    builder: (_) =>
                        const ManageAccountSheet(isForPartner: true),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('إضافة شريك',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // حالة عدم وجود شركاء مضافين
          if (partners.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    Text('لا يوجد شركاء حالياً',
                        style: GoogleFonts.cairo(
                            color: dark ? Colors.white70 : Colors.black54,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('قم بإضافة شريك جديد لتوزيع الأرباح تلقائياً',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            color: dark ? Colors.white54 : Colors.black38,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),

          // كروت الشركاء
          ...partners.map((partner) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [partner.startColor, partner.endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: partner.startColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: partner.imagePath != null
                              ? ClipOval(
                                  child: kIsWeb
                                      ? Image.network(partner.imagePath!,
                                          fit: BoxFit.cover)
                                      : Image.file(File(partner.imagePath!),
                                          fit: BoxFit.cover))
                              : Center(
                                  child: Text(partner.icon,
                                      style: const TextStyle(fontSize: 30))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(partner.name,
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('${partner.partnerShare}%',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('الرصيد المتاح للسحب:',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  '${formatNumber(partner.balance)} ${partner.currency}',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // أزرار التحكم بالشريك
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.black.withOpacity(0.2),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              app.playClick();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddTransactionSheet(
                                  isPartnerWithdrawal: true,
                                  partnerAccountId: partner.id,
                                ),
                              );
                            },
                            icon: const Icon(Icons.money_off_rounded, size: 18),
                            label: Text('سحب أرباح',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: partner.endColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            app.playClick();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ManageAccountSheet(
                                existingAccount: partner,
                                isForPartner: true,
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded,
                              color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
