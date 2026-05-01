import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';
import 'manage_account_sheet.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = newValue.text.replaceAll(',', '');
    List<String> parts = cleanText.split('.');
    if (parts.length > 2) return oldValue;

    String wholePart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (wholePart.isEmpty && decimalPart.isNotEmpty) wholePart = '0';

    final intValue = int.tryParse(wholePart);
    if (intValue == null && wholePart.isNotEmpty) return oldValue;

    String formatted =
        wholePart.isNotEmpty ? NumberFormat('#,###').format(intValue) : '';
    String finalString = formatted + decimalPart;

    return TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final Transaction? existingTx;
  const AddTransactionSheet({super.key, this.existingTx});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TransactionType _type = TransactionType.income;
  TransactionStatus _status = TransactionStatus.completed;

  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  String _fromAccountId = '';
  String _toAccountId = '';
  String _category = '';
  bool _isCustomCategory = false;
  DateTime _date = DateTime.now();
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingTx != null) {
      final tx = widget.existingTx!;
      _type = tx.type;
      _status = tx.status;
      _notesCtrl.text = tx.notes;
      _fromAccountId = tx.accountId;
      if (tx.isTransfer && tx.toAccountId != null) {
        _toAccountId = tx.toAccountId!;
      }
      _category = tx.category;
      _date = tx.date;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();

    if (widget.existingTx != null && _amountCtrl.text.isEmpty) {
      final tx = widget.existingTx!;
      String amtStr = (tx.amount == tx.amount.truncateToDouble()
          ? tx.amount.toInt().toString()
          : tx.amount.toString());
      List<String> parts = amtStr.split('.');
      String wholePart = parts[0];
      String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
      final intValue = int.tryParse(wholePart);
      String formatted =
          intValue != null ? NumberFormat('#,###').format(intValue) : wholePart;
      _amountCtrl.text = formatted + decimalPart;
    }

    if (_fromAccountId.isEmpty && app.accounts.isNotEmpty) {
      _fromAccountId = app.accounts[0].id;
      _toAccountId =
          app.accounts.length > 1 ? app.accounts[1].id : app.accounts[0].id;
    }
    if (_category.isEmpty && app.categories.isNotEmpty) {
      _category = app.categories[0];
    } else if (_category.isNotEmpty && widget.existingTx != null) {
      final catName = CategoryData.parse(_category).name;
      final match = app.categories.firstWhere(
          (c) => CategoryData.parse(c).name == catName,
          orElse: () => '');

      if (match.isNotEmpty) {
        _category = match;
        _isCustomCategory = false;
      } else {
        _isCustomCategory = true;
        _customCategoryCtrl.text = catName;
        _category = '➕ إضافة فئة جديدة...';
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<AppProvider>().playClick(); // صوت تفاعلي عند محاولة الحفظ
    setState(() => _error = '');
    final app = context.read<AppProvider>();

    final inputAmount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (inputAmount <= 0) {
      setState(() => _error = 'يرجى إدخال مبلغ صحيح أكبر من صفر.');
      return;
    }
    if (_type == TransactionType.transfer && _fromAccountId == _toAccountId) {
      setState(() => _error = 'يجب أن يكون حساب المصدر مختلفًا عن الوجهة.');
      return;
    }

    final fromAcc = app.accounts.firstWhere((a) => a.id == _fromAccountId);
    final finalAmount = inputAmount;

    // --- التحقق من توفر رصيد كافٍ للسحب والتحويل ---
    if (_type == TransactionType.expense || _type == TransactionType.transfer) {
      double availableBalance = fromAcc.balance;
      // إذا كنا نعدل معاملة، نعيد حساب الرصيد المتاح الفعلي
      if (widget.existingTx != null &&
          widget.existingTx!.accountId == _fromAccountId) {
        if (widget.existingTx!.type == TransactionType.expense ||
            widget.existingTx!.type == TransactionType.transfer) {
          availableBalance += widget.existingTx!.amount;
        } else if (widget.existingTx!.type == TransactionType.income) {
          availableBalance -= widget.existingTx!.amount;
        }
      }

      if (finalAmount > availableBalance) {
        setState(() => _error =
            'لا يمكن إتمام العملية! المبلغ المطلوب يتخطى الرصيد المتاح بالحساب.');
        return;
      }
    }

    final txs = <Transaction>[];
    // تم استخدام التاريخ والوقت الذي اختاره المستخدم بالكامل
    final now = _date;

    String finalDesc = '';
    String finalCat = _category;

    if (_type == TransactionType.transfer) {
      final toAcc = app.accounts.firstWhere((a) => a.id == _toAccountId,
          orElse: () => app.accounts.first);
      finalDesc = 'تحويل إلى ${toAcc.name}';
      finalCat = 'تحويلات';
    } else {
      if (_isCustomCategory) {
        final customName = _customCategoryCtrl.text.trim();
        if (customName.isEmpty) {
          setState(() => _error = 'يرجى كتابة اسم الفئة الجديدة.');
          return;
        }
        finalCat = CategoryData(name: customName, icon: '🏷️').encode();
        if (!app.categories.contains(finalCat)) {
          app.saveCategories([...app.categories, finalCat]);
        }
      } else if (finalCat.isEmpty || finalCat == '➕ إضافة فئة جديدة...') {
        setState(() => _error = 'يرجى اختيار الفئة.');
        return;
      }
      finalDesc = CategoryData.parse(finalCat).name;
    }

    if (_type == TransactionType.transfer) {
      txs.add(Transaction(
        id: widget.existingTx?.id ?? generateId(),
        description: finalDesc,
        amount: finalAmount,
        type: TransactionType.transfer,
        accountId: _fromAccountId,
        toAccountId: _toAccountId, // ربط حساب المستقبل
        date: now,
        status: _status,
        category: finalCat,
        notes: _notesCtrl.text.trim(),
      ));
    } else {
      txs.add(Transaction(
        id: widget.existingTx?.id ?? generateId(),
        description: finalDesc,
        amount: finalAmount,
        type: _type,
        accountId: _fromAccountId,
        date: now,
        status: _status,
        category: finalCat,
        notes: _notesCtrl.text.trim(),
        createdBy: app.displayName,
      ));
    }

    await app.addTransactions(txs);
    app.playVibrate(); // اهتزاز قوي عند نجاح الإضافة
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;

    // حائط صد لمنع انهيار التطبيق إذا حاول المستخدم إضافة معاملة قبل إنشاء أي حساب
    if (app.accounts.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('يجب إضافة حساب أولاً',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'لا يمكنك إضافة معاملة بدون حساب. يرجى الذهاب إلى "إدارة الحسابات" في الإعدادات لإضافة حساب جديد.',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.cairo(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  app.playClick();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7C3AED),
                    minimumSize: const Size(double.infinity, 50)),
                child: Text('حسناً، فهمت',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      );
    }

    final inputFill = Colors.white.withOpacity(0.15);
    const textColor = Colors.white;
    const subColor = Colors.white70;
    final borderColor = Colors.white.withOpacity(0.3);

    final fromAcc = app.accounts.firstWhere((a) => a.id == _fromAccountId,
        orElse: () => app.accounts.first);
    final nativeCurrency = fromAcc.currency;
    final nativeSymbol = nativeCurrency == 'EGP' ? 'جنية' : nativeCurrency;

    final inputAmt = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

    bool isBalanceInsufficient = false;
    double availableBalance = fromAcc.balance;
    if (widget.existingTx != null &&
        widget.existingTx!.accountId == _fromAccountId) {
      if (widget.existingTx!.type == TransactionType.expense ||
          widget.existingTx!.type == TransactionType.transfer) {
        availableBalance += widget.existingTx!.amount;
      } else if (widget.existingTx!.type == TransactionType.income) {
        availableBalance -= widget.existingTx!.amount;
      }
    }
    if ((_type == TransactionType.expense ||
            _type == TransactionType.transfer) &&
        inputAmt > availableBalance) {
      isBalanceInsufficient = true;
    }

    final hasSecondary = fromAcc.secondaryCurrency != null &&
        fromAcc.secondaryCurrency!.isNotEmpty;
    final secondaryCurrency = fromAcc.secondaryCurrency ?? '';
    final secondarySymbol =
        secondaryCurrency == 'EGP' ? 'جنية' : secondaryCurrency;

    final secondaryAmt = hasSecondary
        ? app.convertCurrency(inputAmt, nativeCurrency, secondaryCurrency)
        : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white24 : Colors.grey[300]!,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                        widget.existingTx == null
                            ? '✨ إضافة حركة جديدة'
                            : '✏️ تعديل المعاملة',
                        style: GoogleFonts.cairo(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          app.playClick();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type tabs
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            _typeTab('دخل', '⬆️', TransactionType.income,
                                const Color(0xFF00E676)),
                            const SizedBox(width: 8),
                            _typeTab('مصروف', '⬇️', TransactionType.expense,
                                const Color(0xFFFF1744)),
                            const SizedBox(width: 8),
                            _typeTab('تحويل', '↔️', TransactionType.transfer,
                                const Color(0xFF00B0FF)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Amount (3D)
                      _label('💰 المبلغ *', subColor),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF00E676)
                                            .withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]),
                              child: const Icon(Icons.attach_money_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _amountCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.cairo(
                                    color: textColor,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                          color: Colors.white.withOpacity(0.6),
                                          blurRadius: 12)
                                    ]),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: GoogleFonts.cairo(
                                      color: subColor.withOpacity(0.5),
                                      fontSize: 32),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Text(
                              nativeSymbol,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 10)
                                  ]),
                            ),
                          ],
                        ),
                      ),
                      if (isBalanceInsufficient)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF1744).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.warning_amber_rounded,
                                      color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الرصيد غير كافٍ!',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'المتاح: ${formatNumber(availableBalance)} $nativeSymbol${hasSecondary ? ' (≈ ${formatNumber(app.convertCurrency(availableBalance, nativeCurrency, secondaryCurrency))} $secondarySymbol)' : ''}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'ينقصك: ${formatNumber(inputAmt - availableBalance)} $nativeSymbol${hasSecondary ? ' (≈ ${formatNumber(app.convertCurrency(inputAmt - availableBalance, nativeCurrency, secondaryCurrency))} $secondarySymbol)' : ''}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // From Account
                      _labelWithAdd(
                          _type == TransactionType.transfer
                              ? '📤 من حساب *'
                              : '🏦 الحساب *',
                          subColor, () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ManageAccountSheet(),
                        );
                      }),
                      Column(
                        children: app.accounts.map((acc) {
                          final accNativeSym =
                              acc.currency == 'EGP' ? 'جنية' : acc.currency;
                          final accHasSec = acc.secondaryCurrency != null &&
                              acc.secondaryCurrency!.isNotEmpty;
                          double accSecAmt = 0.0;
                          String accSecSym = '';
                          if (accHasSec) {
                            accSecAmt = app.convertCurrency(acc.balance,
                                acc.currency, acc.secondaryCurrency!);
                            accSecSym = acc.secondaryCurrency == 'EGP'
                                ? 'جنية'
                                : acc.secondaryCurrency!;
                          }
                          final active = _fromAccountId == acc.id;
                          return GestureDetector(
                            onTap: () {
                              app.playClick();
                              setState(() => _fromAccountId = acc.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: active
                                    ? LinearGradient(
                                        colors: [acc.startColor, acc.endColor])
                                    : null,
                                color: active ? null : inputFill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: active
                                      ? Colors.white.withOpacity(0.5)
                                      : borderColor,
                                  width: active ? 1.5 : 1,
                                ),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                            color:
                                                acc.endColor.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white.withOpacity(0.25)
                                          : Colors.black.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(acc.icon,
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(acc.name,
                                            style: GoogleFonts.cairo(
                                                color: active
                                                    ? Colors.white
                                                    : textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                height: 1.2)),
                                        const SizedBox(height: 4),
                                        Text(
                                            '${formatNumber(acc.balance)} $accNativeSym',
                                            style: GoogleFonts.cairo(
                                                color: active
                                                    ? Colors.white
                                                    : subColor,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                                height: 1.2)),
                                        if (accHasSec)
                                          Text(
                                              '≈ ${formatNumber(accSecAmt)} $accSecSym',
                                              style: GoogleFonts.cairo(
                                                  color: active
                                                      ? Colors.white
                                                          .withOpacity(0.8)
                                                      : subColor
                                                          .withOpacity(0.7),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  height: 1.2)),
                                      ],
                                    ),
                                  ),
                                  if (active)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 28),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // To Account (transfer only)
                      if (_type == TransactionType.transfer) ...[
                        _labelWithAdd('📥 إلى حساب *', subColor, () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ManageAccountSheet(),
                          );
                        }),
                        Builder(builder: (context) {
                          final toAccounts = app.accounts
                              .where((a) => a.id != _fromAccountId)
                              .toList();
                          return Column(
                            children: toAccounts.map((acc) {
                              final accNativeSym =
                                  acc.currency == 'EGP' ? 'جنية' : acc.currency;
                              final accHasSec = acc.secondaryCurrency != null &&
                                  acc.secondaryCurrency!.isNotEmpty;
                              double accSecAmt = 0.0;
                              String accSecSym = '';
                              if (accHasSec) {
                                accSecAmt = app.convertCurrency(acc.balance,
                                    acc.currency, acc.secondaryCurrency!);
                                accSecSym = acc.secondaryCurrency == 'EGP'
                                    ? 'جنية'
                                    : acc.secondaryCurrency!;
                              }
                              final active = _toAccountId == acc.id;
                              return GestureDetector(
                                onTap: () {
                                  app.playClick();
                                  setState(() => _toAccountId = acc.id);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? LinearGradient(colors: [
                                            acc.startColor,
                                            acc.endColor
                                          ])
                                        : null,
                                    color: active ? null : inputFill,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: active
                                          ? Colors.white.withOpacity(0.5)
                                          : borderColor,
                                      width: active ? 1.5 : 1,
                                    ),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                                color: acc.endColor
                                                    .withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4))
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? Colors.white.withOpacity(0.25)
                                              : Colors.black.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(acc.icon,
                                            style:
                                                const TextStyle(fontSize: 24)),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(acc.name,
                                                style: GoogleFonts.cairo(
                                                    color: active
                                                        ? Colors.white
                                                        : textColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    height: 1.2)),
                                            const SizedBox(height: 4),
                                            Text(
                                                '${formatNumber(acc.balance)} $accNativeSym',
                                                style: GoogleFonts.cairo(
                                                    color: active
                                                        ? Colors.white
                                                        : subColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                    height: 1.2)),
                                            if (accHasSec)
                                              Text(
                                                  '≈ ${formatNumber(accSecAmt)} $accSecSym',
                                                  style: GoogleFonts.cairo(
                                                      color: active
                                                          ? Colors.white
                                                              .withOpacity(0.8)
                                                          : subColor
                                                              .withOpacity(0.7),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      height: 1.2)),
                                          ],
                                        ),
                                      ),
                                      if (active)
                                        const Icon(Icons.check_circle_rounded,
                                            color: Colors.white, size: 28),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // Category + Status (non-transfer)
                      if (_type != TransactionType.transfer) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('🏷️ الفئة', subColor),
                                  Builder(builder: (context) {
                                    List<String> catOptions = [
                                      ...app.categories
                                    ];
                                    if (!catOptions
                                        .contains('➕ إضافة فئة جديدة...')) {
                                      catOptions.add('➕ إضافة فئة جديدة...');
                                    }
                                    return _build3DDropdown<String>(
                                      value: catOptions.contains(_category)
                                          ? _category
                                          : catOptions.first,
                                      items: catOptions,
                                      label: (c) {
                                        if (c == '➕ إضافة فئة جديدة...') {
                                          return c;
                                        }
                                        return CategoryData.parse(c).name;
                                      },
                                      leading: (c) {
                                        if (c == '➕ إضافة فئة جديدة...') {
                                          return const SizedBox.shrink();
                                        }
                                        final cat = CategoryData.parse(c);
                                        if (cat.imagePath != null) {
                                          return ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: kIsWeb
                                                ? Image.network(cat.imagePath!,
                                                    width: 20,
                                                    height: 20,
                                                    fit: BoxFit.cover)
                                                : Image.file(
                                                    File(cat.imagePath!),
                                                    width: 20,
                                                    height: 20,
                                                    fit: BoxFit.cover),
                                          );
                                        }
                                        return Text(cat.icon,
                                            style:
                                                const TextStyle(fontSize: 16));
                                      },
                                      onChanged: (v) => setState(() {
                                        if (v != null) {
                                          _category = v;
                                          _isCustomCategory =
                                              v == '➕ إضافة فئة جديدة...';
                                        }
                                      }),
                                      color: const Color(0xFF8B5CF6),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('📌 الحالة', subColor),
                                  _build3DDropdown<TransactionStatus>(
                                    value: _status,
                                    items: [
                                      TransactionStatus.completed,
                                      TransactionStatus.pending,
                                    ],
                                    label: (s) =>
                                        s == TransactionStatus.completed
                                            ? 'مكتملة'
                                            : 'معلقة',
                                    leading: (s) =>
                                        s == TransactionStatus.completed
                                            ? const Text('✅',
                                                style: TextStyle(fontSize: 14))
                                            : const Text('⏳',
                                                style: TextStyle(fontSize: 14)),
                                    onChanged: (v) =>
                                        setState(() => _status = v!),
                                    color:
                                        _status == TransactionStatus.completed
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFFF9100),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_isCustomCategory &&
                          _type != TransactionType.transfer) ...[
                        _label('✍️ الفئة الجديدة', subColor),
                        _build3DInput(
                          ctrl: _customCategoryCtrl,
                          hint: 'اكتب اسم الفئة الجديدة هنا...',
                          icon: Icons.category_rounded,
                          inputFill: inputFill,
                          textColor: textColor,
                          dark: dark,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Date & Time Row (Separate 3D Pickers)
                      Row(
                        children: [
                          Expanded(
                            child: _build3DDateTimeButton(
                              label: '📅 التاريخ',
                              value: formatDate(_date),
                              icon: Icons.calendar_month_rounded,
                              color: const Color(0xFF00B0FF),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
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
                                  setState(() => _date = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      _date.hour,
                                      _date.minute));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _build3DDateTimeButton(
                              label: '⏰ الوقت',
                              value: TimeOfDay.fromDateTime(_date)
                                  .format(context)
                                  .replaceAll('AM', 'ص')
                                  .replaceAll('PM', 'م'),
                              icon: Icons.access_time_rounded,
                              color: const Color(0xFFFF9100),
                              onTap: () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(_date),
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
                                if (pickedTime != null) {
                                  setState(() => _date = DateTime(
                                      _date.year,
                                      _date.month,
                                      _date.day,
                                      pickedTime.hour,
                                      pickedTime.minute));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      _label('✍️ ملاحظات إضافية', subColor),
                      _build3DInput(
                        ctrl: _notesCtrl,
                        hint: 'أي تفاصيل إضافية...',
                        icon: Icons.notes_rounded,
                        inputFill: inputFill,
                        textColor: textColor,
                        maxLines: 2,
                        dark: dark,
                      ),
                      const SizedBox(height: 12),

                      // Dollar conversion preview
                      if (hasSecondary && inputAmt > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00E676),
                                Color(0xFF00B248)
                              ], // تدرج أخضر ساطع
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.currency_exchange_rounded,
                                        color: Color(0xFF00B248),
                                        size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Text('تحويل تقريبي للعملة',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4)
                                          ])),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _row(
                                  'القيمة المدخلة',
                                  '${formatNumber(inputAmt)} $nativeSymbol',
                                  Colors.white.withOpacity(0.95)),
                              _row(
                                  'سعر الصرف',
                                  '1 $nativeSymbol = ${app.convertCurrency(1, nativeCurrency, secondaryCurrency).toStringAsFixed(3)} $secondarySymbol',
                                  Colors.white.withOpacity(0.95)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                    color: Colors.white.withOpacity(0.4),
                                    height: 1,
                                    thickness: 1.5),
                              ),
                              _row(
                                  'المبلغ المعادل',
                                  '${formatNumber(secondaryAmt)} $secondarySymbol',
                                  Colors.white,
                                  bold: true,
                                  size: 22), // تكبير الخط ليكون أوضح
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Error
                      if (_error.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1744).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFF1744).withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1744).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child:
                                    Text('⚠️', style: TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_error,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              widget.existingTx == null
                                  ? '✅ إضافة المعاملة'
                                  : '💾 حفظ التعديلات',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(
      String label, String icon, TransactionType type, Color activeColor) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<AppProvider>().playClick();
          setState(() => _type = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, active ? -4 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    active ? activeColor.withOpacity(0.4) : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
            border: Border.all(
                color:
                    active ? Colors.transparent : Colors.white.withOpacity(0.3),
                width: active ? 0 : 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: active ? 18 : 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                  fontSize: active ? 15 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.cairo(
              color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }

  Widget _build3DDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    Widget Function(T)? leading,
    required ValueChanged<T?> onChanged,
    Color? color,
  }) {
    final safeValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: color != null
            ? color.withOpacity(0.8)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color != null
                ? color.withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
            color: color != null
                ? Colors.transparent
                : Colors.white.withOpacity(0.4),
            width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          dropdownColor: color ?? const Color(0xFF4C1D95),
          borderRadius: BorderRadius.circular(20),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white),
          isExpanded: true,
          isDense: true,
          style: GoogleFonts.cairo(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
          items: items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            final i = entry.value;
            return DropdownMenuItem(
              value: i,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    if (safeValue == i) ...[
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    if (leading != null) ...[
                      leading(i),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(label(i),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: safeValue == i ? 15 : 14,
                              fontWeight: safeValue == i
                                  ? FontWeight.w900
                                  : FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            context.read<AppProvider>().playClick();
            onChanged(val);
          },
          selectedItemBuilder: (context) {
            return items.map((i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading(i),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(label(i),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _build3DInput({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color inputFill,
    required Color textColor,
    Color iconColor = Colors.white70,
    TextInputType? inputType,
    int maxLines = 1,
    void Function(String)? onChanged,
    required bool dark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: GoogleFonts.cairo(color: textColor, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: Colors.white54),
          prefixIcon: Icon(icon, color: iconColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color,
      {bool bold = false, double size = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value,
              style: GoogleFonts.cairo(
                  color: color,
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _build3DDateTimeButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, Colors.white),
        GestureDetector(
          onTap: () {
            context.read<AppProvider>().playClick();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: color != null
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color != null
                        ? color.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
              border: Border.all(
                  color: color != null
                      ? color.withOpacity(0.5)
                      : Colors.white.withOpacity(0.4),
                  width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: color ?? Colors.white70, size: 22),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(value,
                        style: GoogleFonts.cairo(
                            color: Colors.white,
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

  Widget _labelWithAdd(String text, Color color, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          GestureDetector(
            onTap: () {
              context.read<AppProvider>().playClick();
              onAdd();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('إضافة حساب',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
