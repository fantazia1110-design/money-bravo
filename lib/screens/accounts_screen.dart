import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: dark
                    ? [
                        const Color(0xFFFF9100).withOpacity(0.9),
                        const Color(0xFFFF3D00).withOpacity(0.9)
                      ]
                    : [const Color(0xFFFFB300), const Color(0xFFFF6D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.8), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3D00).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.25,
                    child: Text('👑', style: TextStyle(fontSize: 110)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 12)
                            ],
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text('إجمالي الرصيد المتوفر',
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(formatNumber(app.netBalance),
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                shadows: [
                                  Shadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 16)
                                ])),
                        const SizedBox(width: 8),
                        Text(app.appCurrencySymbol,
                            style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('يضم ${app.accounts.length} حسابات نشطة',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // كروت إجمالي الدخل والمصروف 3D
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withOpacity(0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          left: -20,
                          top: -20,
                          child: Opacity(
                            opacity: 0.15,
                            child: Text('📈', style: TextStyle(fontSize: 90)),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 12)
                                ],
                              ),
                              child: const Icon(Icons.arrow_upward_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 16),
                            Text('إجمالي الدخل',
                                style: GoogleFonts.cairo(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(formatNumber(app.totalIncome),
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  blurRadius: 12)
                                            ])),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(app.appCurrencySymbol,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withOpacity(0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          left: -20,
                          top: -20,
                          child: Opacity(
                            opacity: 0.15,
                            child: Text('📉', style: TextStyle(fontSize: 90)),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 12)
                                ],
                              ),
                              child: const Icon(Icons.arrow_downward_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 16),
                            Text('إجمالي المصروف',
                                style: GoogleFonts.cairo(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(formatNumber(app.totalExpense),
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  blurRadius: 12)
                                            ])),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(app.appCurrencySymbol,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('تفاصيل الحسابات 🏦',
                style: GoogleFonts.cairo(
                    color: dark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),

          // Account detail cards
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
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: acc.startColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
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
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: acc.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: kIsWeb
                                          ? Image.network(acc.imagePath!,
                                              fit: BoxFit.contain)
                                          : Image.file(File(acc.imagePath!),
                                              fit: BoxFit.contain))
                                  : Center(
                                      child: Text(acc.icon,
                                          style:
                                              const TextStyle(fontSize: 38))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(acc.name,
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
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
                                          fontSize: 24,
                                          height: 1.2,
                                          fontWeight: FontWeight.w900,
                                          shadows: [
                                            Shadow(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                blurRadius: 12)
                                          ])),
                                  if (hasSecondary)
                                    Text(
                                        '${formatNumber(secondaryBalance)} $secondarySymbol',
                                        style: GoogleFonts.cairo(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 16,
                                            height: 1.2,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  blurRadius: 8)
                                            ])),
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
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text('$txCount معاملة',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      shadows: const [
                                        Shadow(
                                            color: Colors.white, blurRadius: 8)
                                      ])),
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

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, String currency,
      Color color, bool dark, String iconText,
      {bool isGlass = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: isGlass
            ? LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isGlass ? null : (dark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isGlass
                ? Colors.white.withOpacity(0.5)
                : color.withOpacity(0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isGlass ? 0.6 : 0.15),
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
                              : (dark ? Colors.white70 : Colors.black54),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Colors.black26, blurRadius: 2)
                          ])),
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
                                ? const [
                                    Shadow(color: Colors.white, blurRadius: 16)
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
}
