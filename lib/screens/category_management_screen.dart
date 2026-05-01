import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';
import '../widgets/manage_category_sheet.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final ValueNotifier<Offset> _touchPos = ValueNotifier(Offset.zero);

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
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

  @override
  void dispose() {
    _animCtrl.dispose();
    _touchPos.dispose();
    super.dispose();
  }

  void _showEditor(BuildContext context, [String? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageCategorySheet(existingCategory: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dark = context.watch<ThemeProvider>().darkMode;
    final textColor = dark ? Colors.white : const Color(0xFF1E293B);

    List<String> displayCats = [...app.categories];

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        title: Text('إدارة الفئات',
            style: GoogleFonts.cairo(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF7C3AED)),
      ),
      body: Listener(
        onPointerHover: (event) => _touchPos.value = event.localPosition,
        onPointerMove: (event) => _touchPos.value = event.localPosition,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Animated Background Blobs
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
              itemCount: displayCats.length,
              itemBuilder: (context, index) {
                final catRaw = displayCats[index];
                final catData = CategoryData.parse(catRaw);
                final txCount = app.transactions
                    .where((t) =>
                        t.category == catRaw ||
                        CategoryData.parse(t.category).name == catData.name)
                    .length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: dark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF7C3AED).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ]),
                        child: catData.imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: kIsWeb
                                    ? Image.network(catData.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Center(
                                            child: Text(catData.icon,
                                                style: const TextStyle(
                                                    fontSize: 28))))
                                    : Image.file(File(catData.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Center(
                                            child: Text(catData.icon,
                                                style: const TextStyle(
                                                    fontSize: 28)))))
                            : Center(
                                child: Text(catData.icon, style: const TextStyle(fontSize: 28, color: Colors.white))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(catData.name,
                                style: GoogleFonts.cairo(
                                    color: textColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                            Text('$txCount معاملة مرتبطة',
                                style: GoogleFonts.cairo(
                                    color: dark
                                        ? Colors.white54
                                        : Colors.grey[500],
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              const Color(0xFF7C3AED).withOpacity(0.2),
                              const Color(0xFF4C1D95).withOpacity(0.1)
                            ]),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF7C3AED).withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF7C3AED).withOpacity(0.3),
                                  blurRadius: 8)
                            ]),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              color: Color(0xFF7C3AED), size: 20),
                          onPressed: () {
                            app.playClick();
                            _showEditor(context, catRaw);
                          },
                        ),
                      ),
                      if (displayCats.length > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                const Color(0xFFFF1744).withOpacity(0.2),
                                const Color(0xFFD50000).withOpacity(0.1)
                              ]),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      const Color(0xFFFF1744).withOpacity(0.5),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFFF1744)
                                        .withOpacity(0.3),
                                    blurRadius: 8)
                              ]),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFFF1744), size: 20),
                            onPressed: () {
                              app.playClick();
                              showDialog(
                                context: context,
                                builder: (c) => Dialog(
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
                                            'هل أنت متأكد من حذف هذه الفئة نهائياً؟',
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
                                                      app.playClick();
                                                      Navigator.pop(c);
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
                                                  app.playClick();
                                                  final updated =
                                                      List<String>.from(
                                                          app.categories)
                                                        ..removeWhere((cat) =>
                                                            cat == catRaw);
                                                  app.saveCategories(updated);
                                                  Navigator.pop(c);
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
          _showEditor(context);
        },
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('إضافة فئة',
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
