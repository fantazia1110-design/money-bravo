import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/account.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';

class ManageAccountSheet extends StatefulWidget {
  final Account? existingAccount;
  const ManageAccountSheet({super.key, this.existingAccount});

  @override
  State<ManageAccountSheet> createState() => _ManageAccountSheetState();
}

class _ManageAccountSheetState extends State<ManageAccountSheet> {
  final _nameCtrl = TextEditingController();

  String _currency = 'جنية مصري (EGP)';
  String _secondaryCurrency = 'بدون عملة ثانوية';
  String _icon = '💰';
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  List<String> _selectedColors = ['#4C1D95', '#312E81'];

  final List<String> _icons = [
    '💰',
    '🏦',
    '💳',
    '💵',
    '💶',
    '🪙',
    '💸',
    '🧾',
    '💎',
    '💡',
    '💧',
    '🔥',
    '📱',
    '☎️',
    '🌐',
    '📡',
    '📺',
    '🛒',
    '🍔',
    '🍕',
    '🍗',
    '🍟',
    '🍩',
    '☕',
    '🍹',
    '🍽️',
    '🚗',
    '🚕',
    '🚌',
    '🚆',
    '✈️',
    '🚲',
    '⛽',
    '🅿️',
    '🔧',
    '🛍️',
    '👗',
    '👕',
    '👟',
    '👜',
    '🏠',
    '🛋️',
    '🛠️',
    '🧹',
    '🪴',
    '🏥',
    '💊',
    '🩺',
    '💈',
    '🛁',
    '🧴',
    '🎓',
    '📚',
    '🎒',
    '💻',
    '💼',
    '🎮',
    '🎬',
    '🎧',
    '⚽',
    '🏋️',
    '🎫',
    '👶',
    '🍼',
    '🧸',
    '🐶',
    '🐱',
    '👨',
    '👩',
    '👦',
    '👧',
    '👴',
    '👵',
    '👨‍🔧',
    '👨‍⚕️',
    '👨‍🏫',
    '👮‍♂️',
  ];

  final List<List<String>> _colorGradients = [
    ['#4C1D95', '#312E81'], // موف داكن
    ['#00B248', '#008B3A'], // أخضر داكن
    ['#0081CB', '#005CB2'], // أزرق داكن
    ['#F57C00', '#E65100'], // برتقالي داكن
    ['#D50000', '#B71C1C'], // أحمر داكن
    ['#111827', '#020617'], // أسود فخم
    ['#D500F9', '#6A1B9A'], // وردي/بنفسجي داكن
    ['#FFB300', '#FF8F00'], // أصفر داكن
    ['#00BFA5', '#00897B'], // تيل داكن
    ['#C51162', '#880E4F'], // بينك داكن
    ['#5D4037', '#3E2723'], // بني داكن
    ['#455A64', '#263238'], // رمادي مزرق داكن
    ['#BE123C', '#881337'], // وردي داكن
    ['#1D4ED8', '#1E3A8A'], // أزرق ملكي داكن
    ['#0F766E', '#115E59'], // زمردي داكن
    ['#4D7C0F', '#3F6212'], // ليموني داكن
    ['#B45309', '#78350F'], // عنبري داكن
    ['#5B21B6', '#4C1D95'], // بنفسجي داكن
    ['#0E7490', '#164E63'], // سماوي داكن
    ['#7E22CE', '#581C87'], // فوشيا داكن
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingAccount != null) {
      final acc = widget.existingAccount!;
      _nameCtrl.text = acc.name;

      if (globalCurrencies.any((c) => c.contains(acc.currency))) {
        _currency = globalCurrencies.firstWhere(
          (c) => c.contains(acc.currency),
        );
      } else {
        _currency = globalCurrencies[0];
      }

      if (acc.secondaryCurrency != null && acc.secondaryCurrency!.isNotEmpty) {
        if (globalCurrencies.any((c) => c.contains(acc.secondaryCurrency!))) {
          _secondaryCurrency = globalCurrencies.firstWhere(
            (c) => c.contains(acc.secondaryCurrency!),
          );
        } else {
          _secondaryCurrency = 'بدون عملة ثانوية';
        }
      }
      _icon = acc.icon;
      _imagePath = acc.imagePath;
      _selectedColors = acc.colors;
    }
  }

  Future<void> _pickImage() async {
    context.read<AppProvider>().playClick();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imagePath = image.path;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    context.read<AppProvider>().playClick();
    final app = context.read<AppProvider>();
    final name = _nameCtrl.text.trim();

    final currencySymbol = _currency.split('(').last.replaceAll(')', '').trim();

    final secondarySymbol = _secondaryCurrency == 'بدون عملة ثانوية'
        ? null
        : _secondaryCurrency.split('(').last.replaceAll(')', '').trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال اسم الحساب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? finalImagePath = _imagePath;
    if (_imageBytes != null) {
      final uploadedUrl = await app.uploadImageBytes(_imageBytes!, 'accounts');
      if (uploadedUrl != null) {
        finalImagePath = uploadedUrl;
      }
    }

    final newAccount = Account(
      id: widget.existingAccount?.id ?? generateId(),
      name: name,
      currency: currencySymbol,
      secondaryCurrency: secondarySymbol,
      icon: _icon,
      imagePath: finalImagePath,
      colors: _selectedColors,
      balance: widget.existingAccount?.balance ?? 0.0,
    );

    // حفظ محلي (ستحتاج لاحقاً لربطها بـ Firestore)
    app.saveAccountLocally(newAccount);
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  void _showCurrencyDialog(
    String currentValue,
    List<String> options,
    ValueChanged<String> onSelected,
  ) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = options
              .where(
                (cur) =>
                    cur.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    cur.contains(searchQuery),
              )
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
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (v) => setDialogState(() => searchQuery = v),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث عن عملة...',
                      hintStyle: GoogleFonts.cairo(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
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
                        final isLast = i == filtered.length - 1;
                        return Container(
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                          ),
                          child: ListTile(
                            title: Text(
                              curFull,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: currentValue == curFull
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF00E676),
                                  )
                                : null,
                            onTap: () {
                              context.read<AppProvider>().playClick();
                              onSelected(curFull);
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().darkMode;
    final inputFill = Colors.white.withOpacity(0.15);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(hexToColorInt(_selectedColors[0])),
              Color(hexToColorInt(_selectedColors[1])),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Color(
                hexToColorInt(_selectedColors[0]),
              ).withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      widget.existingAccount == null
                          ? '✨ حساب جديد'
                          : '✏️ تعديل الحساب',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        context.read<AppProvider>().playClick();
                        Navigator.pop(context);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image / Icon Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: _imagePath != null
                                    ? ClipOval(
                                        child: kIsWeb
                                            ? Image.network(
                                                _imagePath!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_imagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : Center(
                                        child: Text(
                                          _icon,
                                          style: const TextStyle(fontSize: 40),
                                        ),
                                      ),
                              ),
                              if (_imagePath != null)
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: GestureDetector(
                                    onTap: () {
                                      context.read<AppProvider>().playClick();
                                      setState(() {
                                        _imagePath = null;
                                        _imageBytes = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.5)),
                                      child: const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'اختيار صورة من المعرض',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('اسم الحساب *'),
                      _buildInput(
                        ctrl: _nameCtrl,
                        hint: 'مثال: محفظة فودافون، بنك مصر...',
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                      const SizedBox(height: 16),

                      _label('عملة الحساب'),
                      GestureDetector(
                        onTap: () {
                          context.read<AppProvider>().playClick();
                          _showCurrencyDialog(
                            _currency,
                            globalCurrencies,
                            (v) {
                              setState(() {
                                _currency = v;
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currency,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.search, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('عملة ثانوية للمقارنة (اختياري)'),
                      GestureDetector(
                        onTap: () {
                          context.read<AppProvider>().playClick();
                          _showCurrencyDialog(
                            _secondaryCurrency,
                            ['بدون عملة ثانوية', ...globalCurrencies],
                            (v) {
                              setState(() {
                                _secondaryCurrency = v;
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _secondaryCurrency,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.search, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('لون الحساب'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _colorGradients.map((grad) {
                          final isSelected = _selectedColors[0] == grad[0];
                          return GestureDetector(
                            onTap: () {
                              context.read<AppProvider>().playClick();
                              setState(() => _selectedColors = grad);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(hexToColorInt(grad[0])),
                                    Color(hexToColorInt(grad[1])),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      _label('أيقونة (في حال عدم وجود صورة)'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _icons.map((i) {
                          final isSelected = _icon == i;
                          return GestureDetector(
                            onTap: () {
                              context.read<AppProvider>().playClick();
                              setState(() => _icon = i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                i,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(
                                        hexToColorInt(_selectedColors[0])),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.existingAccount == null
                                      ? '✅ إنشاء الحساب'
                                      : '💾 حفظ التعديلات',
                                  style: GoogleFonts.cairo(
                                    color: Color(
                                        hexToColorInt(_selectedColors[0])),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _buildInput({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
