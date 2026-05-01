import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/account.dart';
import '../utils/formatters.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _animCtrl;
  final TextEditingController _dollarRateCtrl =
      TextEditingController(text: '50.0');
  final TextEditingController _nameCtrl = TextEditingController();

  final Map<String, Map<String, dynamic>> _suggestedAccounts = {
    'فودافون كاش': {
      'icon': '📱',
      'colors': ['#FF1744', '#D50000']
    },
    'اتصالات كاش': {
      'icon': '📱',
      'colors': ['#00BFA5', '#00897B'] // تيل/زمردي
    },
    'أورانج كاش': {
      'icon': '📱',
      'colors': ['#FFB300', '#FF8F00'] // أصفر/برتقالي فاتح
    },
    'إنستاباي': {
      'icon': '⚡',
      'colors': ['#D500F9', '#AA00FF']
    },
    'حساب بنكي': {
      'icon': '🏦',
      'colors': ['#2979FF', '#1565C0']
    },
    'بنك مصر': {
      'icon': '🏦',
      'colors': ['#0081CB', '#005CB2'] // أزرق داكن
    },
    'البنك الأهلي': {
      'icon': '🏦',
      'colors': ['#00B248', '#008B3A'] // أخضر داكن
    },
    'بنك CIB': {
      'icon': '🏦',
      'colors': ['#F57C00', '#E65100'] // برتقالي داكن
    },
  };

  final List<String> _suggestedCategories = [
    'راتب 💰',
    'عمل حر 💻',
    'طعام 🍔',
    'مواصلات 🚗',
    'فواتير 🧾',
    'صحة 💊',
    'تسوق 🛍️',
    'ترفيه 🎮'
  ];

  final Set<String> _selectedAccs = {};
  final Set<String> _selectedCats = {};

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageCtrl.dispose();
    _dollarRateCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _finishOnboarding(AppProvider app) {
    final name =
        _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'مستخدم';
    app.saveDeviceName(name);
    final rate = double.tryParse(_dollarRateCtrl.text) ?? 50.0;
    app.saveDollarRate(rate);

    if (_selectedCats.isNotEmpty) {
      final formattedCats = _selectedCats.map((cat) {
        final parts = cat.split(' ');
        final icon = parts.length > 1 ? parts.last : '🏷️';
        final name = parts.length > 1
            ? parts.sublist(0, parts.length - 1).join(' ')
            : cat;
        return '$name|$icon|';
      }).toList();
      app.saveCategories(formattedCats);
    }
    if (_selectedAccs.isNotEmpty) {
      for (var accName in _selectedAccs) {
        final data = _suggestedAccounts[accName]!;
        final newAcc = Account(
          id: app.newTxId(),
          name: accName,
          icon: data['icon'],
          currency: app.appCurrency,
          balance: 0.0,
          colors: List<String>.from(data['colors']),
        );
        app.saveAccountLocally(newAcc);
      }
    }
    app.completeTutorial();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ابدأ رحلتك مع برنامج Money Bravo! 🚀',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _blurredBlob(double size, Color color, double blurRadius) {
    // تم استبدال الـ ImageFiltered الثقيل الذي يدمر الأداء بـ RadialGradient خفيف يعطي نفس المظهر
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

  Widget _buildSuggestionChip(
      String text, String? icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        context.read<AppProvider>().playClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E676)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.3),
                      blurRadius: 12)
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Text(text,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00E676), size: 20),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return _buildPageContent(
      icon: '✨',
      title: 'أهلاً بك في Money Bravo 💰',
      desc:
          'مديرك المالي الشخصي الذي يجمع بين البساطة والاحترافية. تم تصميمه ليمنحك السيطرة الكاملة على أموالك وتتبع كل مليم يدخل أو يخرج من جيبك بدقة وسهولة تامة.',
    );
  }

  Widget _buildCurrencyPage(AppProvider app) {
    return _buildPageContent(
      icon: '🌎',
      title: 'العملة الرئيسية 💵',
      desc:
          'في البداية، اختر العملة الأساسية لبلدك التي سيتم بها تقييم إجمالي ثروتك وتحليلاتك المالية. يمكنك تعديلها أو التحويل لعملات أخرى لاحقاً بكل سهولة.',
      actionWidget: _buildCurrencySelector(app),
    );
  }

  Widget _buildDollarRatePage(AppProvider app) {
    return _buildPageContent(
      icon: '💱',
      title: 'سعر الدولار',
      desc:
          'أدخل سعر صرف الدولار المتوقع لتتمكن من حساب وإظهار المعاملات بالعملات الأجنبية بدقة. يمكنك تعديله لاحقاً من الشاشة الرئيسية في أي وقت.',
      actionWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: TextField(
          controller: _dollarRateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.cairo(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'مثال: 50',
            hintStyle: GoogleFonts.cairo(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsPage() {
    return _buildPageContent(
      icon: '🏦',
      title: 'بناء هيكل حساباتك',
      desc:
          'الحسابات هي الأماكن التي تحفظ فيها أموالك (كالمحفظة النقدية أو الحساب البنكي). لراحتك، جهزنا بعض الحسابات الشائعة للبدء بها. \n\nاضغط لتحديد ما تملكه، أو تخطَّ هذه الخطوة وأضف حساباتك بنفسك لاحقاً.',
      actionWidget: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _suggestedAccounts.entries.map((e) {
          final name = e.key;
          final isSelected = _selectedAccs.contains(name);
          return _buildSuggestionChip(name, e.value['icon'], isSelected, () {
            setState(() {
              if (isSelected) {
                _selectedAccs.remove(name);
              } else {
                _selectedAccs.add(name);
              }
            });
          });
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriesPage() {
    return _buildPageContent(
      icon: '🛒',
      title: 'تخصيص الفئات',
      desc:
          'الفئات تساعدك على فهم أين تذهب أموالك بالتحديد (مثل: الطعام، المواصلات). يمكنك اختيار بعض الفئات الأساسية لبدء التصنيف فوراً، أو تجاهلها لإنشاء فئاتك الخاصة من الإعدادات.',
      actionWidget: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _suggestedCategories.map((cat) {
          final isSelected = _selectedCats.contains(cat);
          return _buildSuggestionChip(cat, null, isSelected, () {
            setState(() {
              if (isSelected) {
                _selectedCats.remove(cat);
              } else {
                _selectedCats.add(cat);
              }
            });
          });
        }).toList(),
      ),
    );
  }

  Widget _buildSecurityPage() {
    return _buildPageContent(
      icon: '🛡️',
      title: 'أمان وخصوصية تامة',
      desc:
          'لقد انتهينا! بياناتك مشفرة ومحفوظة على جهازك فقط. لحماية إضافية، نوصي بزيارة الإعدادات لاحقاً وتفعيل رمز المرور (PIN) لغلق التطبيق. \n\nاضغط "ابدأ الآن" لبدء رحلتك المالية الناجحة!',
    );
  }

  Widget _buildNamePage() {
    return _buildPageContent(
      icon: '👤',
      title: 'من أنت؟',
      desc:
          'أدخل اسمك ليتم تسجيل معاملاتك باسمك، مما يسهل على باقي الشركاء معرفة من قام بكل حركة على الحساب.',
      actionWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: TextField(
          controller: _nameCtrl,
          style: GoogleFonts.cairo(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'مثال: حسام',
            hintStyle: GoogleFonts.cairo(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(
      {required String icon,
      required String title,
      required String desc,
      Widget? actionWidget}) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 40)
                  ]),
              child: Text(icon, style: const TextStyle(fontSize: 70)),
            ),
            const SizedBox(height: 40),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text(desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.bold)),
            if (actionWidget != null) ...[
              const SizedBox(height: 32),
              actionWidget,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(AppProvider app) {
    return GestureDetector(
      onTap: () {
        app.playClick();
        String searchQuery = '';
        showDialog(
          context: context,
          builder: (c) => StatefulBuilder(builder: (context, setDialogState) {
            final filtered = globalCurrencies
                .where((cur) =>
                    cur.toLowerCase().contains(searchQuery.toLowerCase()) ||
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
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'بحث عن عملة...',
                        hintStyle: GoogleFonts.cairo(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
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
                                  : const Border(
                                      bottom: BorderSide(
                                          color: Colors.white, width: 2.0)),
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
          }),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: const Color(0xFF4C1D95).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(
                    globalCurrencies.firstWhere(
                        (c) => c.contains(app.appCurrency),
                        orElse: () => app.appCurrency),
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    overflow: TextOverflow.ellipsis)),
            const Icon(Icons.search, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                final val = _animCtrl.value * 2 * math.pi;
                return Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -80 + math.sin(val) * 60,
                        right: -60 + math.cos(val) * 60,
                        child: _blurredBlob(
                            300, const Color(0xFF7C3AED).withOpacity(0.4), 80),
                      ),
                      Positioned(
                        bottom: 50 + math.cos(val) * 60,
                        left: -60 + math.sin(val) * 60,
                        child: _blurredBlob(
                            300, const Color(0xFF9333EA).withOpacity(0.4), 80),
                      ),
                    ],
                  ),
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        app.playClick();
                        _finishOnboarding(app);
                      },
                      child: Text('تخطي',
                          style: GoogleFonts.cairo(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: 7,
                      itemBuilder: (context, i) {
                        switch (i) {
                          case 0:
                            return _buildWelcomePage();
                          case 1:
                            return _buildNamePage();
                          case 2:
                            return _buildCurrencyPage(app);
                          case 3:
                            return _buildDollarRatePage(app);
                          case 4:
                            return _buildAccountsPage();
                          case 5:
                            return _buildCategoriesPage();
                          case 6:
                            return _buildSecurityPage();
                          default:
                            return const SizedBox();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                              7,
                              (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(left: 8),
                                    width: _currentPage == i ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: _currentPage == i
                                            ? const Color(0xFF00E676)
                                            : Colors.white24,
                                        borderRadius: BorderRadius.circular(4)),
                                  )),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            app.playClick();
                            if (_currentPage == 6) {
                              _finishOnboarding(app);
                            } else {
                              _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeInOut);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 10,
                            shadowColor:
                                const Color(0xFF7C3AED).withOpacity(0.5),
                          ),
                          child: Text(
                              _currentPage == 6 ? 'ابدأ الآن 🚀' : 'التالي',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ],
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
