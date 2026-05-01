import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/app_provider.dart';
import '../utils/formatters.dart';

class ManageCategorySheet extends StatefulWidget {
  final String? existingCategory;
  const ManageCategorySheet({super.key, this.existingCategory});

  @override
  State<ManageCategorySheet> createState() => _ManageCategorySheetState();
}

class _ManageCategorySheetState extends State<ManageCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '🛒';
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _isLoading = false;

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
    '👮‍♂️'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      final cat = CategoryData.parse(widget.existingCategory!);
      _nameCtrl.text = cat.name;
      _icon = cat.icon;
      _imagePath = cat.imagePath;
    }
  }

  Future<void> _pickImage() async {
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

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال اسم الفئة',
                style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? finalImagePath = _imagePath;
    if (_imageBytes != null) {
      final uploadedUrl =
          await app.uploadImageBytes(_imageBytes!, 'categories');
      if (uploadedUrl != null) {
        finalImagePath = uploadedUrl;
      }
    }

    final newCategory =
        CategoryData(name: name, icon: _icon, imagePath: finalImagePath)
            .encode();
    final updatedCategories = List<String>.from(app.categories);

    if (widget.existingCategory != null) {
      final idx = updatedCategories.indexOf(widget.existingCategory!);
      if (idx != -1) {
        updatedCategories[idx] = newCategory;
      } else {
        updatedCategories.add(newCategory);
      }
    } else {
      if (!updatedCategories.contains(newCategory)) {
        updatedCategories.add(newCategory);
      }
    }

    app.saveCategories(updatedCategories);
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
              color: const Color(0xFF00E676).withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00E676).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10))
          ],
        ),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                        widget.existingCategory != null
                            ? '✏️ تعديل الفئة'
                            : '✨ إضافة فئة جديدة',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        context.read<AppProvider>().playClick();
                        Navigator.pop(context);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // منتقي الصورة والأيقونة
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            context.read<AppProvider>().playClick();
                            _pickImage();
                          },
                          child: Container(
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676)
                                        .withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF00E676)
                                            .withOpacity(0.5),
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10)
                                    ],
                                  ),
                                  child: _imagePath != null
                                      ? ClipOval(
                                          child: kIsWeb
                                              ? Image.network(_imagePath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Center(
                                                      child: Text(_icon,
                                                          style: const TextStyle(
                                                              fontSize: 40))))
                                              : Image.file(File(_imagePath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Center(
                                                      child: Text(_icon,
                                                          style: const TextStyle(
                                                              fontSize: 40)))))
                                      : Center(child: Text(_icon, style: const TextStyle(fontSize: 40))),
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
                                                color: Colors.white,
                                                width: 1.5)),
                                        child: const Icon(Icons.close_rounded,
                                            color: Colors.white, size: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            context.read<AppProvider>().playClick();
                            _pickImage();
                          },
                          icon: const Icon(Icons.photo_library_rounded,
                              color: Color(0xFF00E676)),
                          label: Text('اختيار صورة بدلاً من الرمز',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF00E676),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('اسم الفئة',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF00E676).withOpacity(0.5),
                              width: 1),
                        ),
                        child: TextField(
                          controller: _nameCtrl,
                          style: GoogleFonts.cairo(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'مثال: سوبر ماركت، فواتير...',
                            hintStyle: GoogleFonts.cairo(color: Colors.white54),
                            prefixIcon: const Icon(Icons.category_rounded,
                                color: Color(0xFF00E676)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('اختر رمز (Emoji) للفئة',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00E676).withOpacity(0.3)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00E676)
                                        : Colors.transparent,
                                    width: 2),
                              ),
                              child:
                                  Text(i, style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 10,
                            shadowColor:
                                const Color(0xFF00E676).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.existingCategory != null
                                      ? '💾 حفظ التعديلات'
                                      : '✅ حفظ الفئة',
                                  style: GoogleFonts.cairo(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18)),
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
}
