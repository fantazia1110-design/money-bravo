import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  String? _photoUrl;
  Uint8List? _imageBytes;
  bool _loading = false;

  bool get isGoogle {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
    final user = FirebaseAuth.instance.currentUser;
    final app = context.read<AppProvider>();
    if (user != null) {
      _photoUrl = user.photoURL;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    context.read<AppProvider>().playClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoUrl = picked.path;
        _imageBytes = bytes;
      });
    }
  }

  void _clearImage() {
    context.read<AppProvider>().playClick();
    setState(() {
      _photoUrl = null;
      _imageBytes = null;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final app = context.read<AppProvider>();
      if (user != null) {
        String? finalPhotoUrl = user.photoURL;

        if (_imageBytes != null) {
          final uploadedUrl =
              await app.uploadImageBytes(_imageBytes!, 'profile_pictures');
          if (uploadedUrl != null) {
            finalPhotoUrl = uploadedUrl;
          }
        } else if (_photoUrl == null && user.photoURL != null) {
          finalPhotoUrl = null;
        }
        if (finalPhotoUrl != user.photoURL) {
          await user.updatePhotoURL(finalPhotoUrl);
          await user
              .reload(); // تحديث حالة المستخدم محلياً لضمان ظهور الصورة فوراً
        }

        if (!isGoogle && _oldPassCtrl.text.isNotEmpty) {
          final cred = EmailAuthProvider.credential(
              email: user.email!, password: _oldPassCtrl.text);
          await user.reauthenticateWithCredential(cred);

          if (_newPassCtrl.text.isNotEmpty && _newPassCtrl.text.length >= 6) {
            await user.updatePassword(_newPassCtrl.text);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث البيانات بنجاح ✅',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تأكد من إدخال كلمة المرور القديمة بشكل صحيح!',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditUsernameDialog(
      BuildContext context, bool dark, bool isGoogleMode) {
    final app = context.read<AppProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final currentUsername = isGoogleMode
        ? (user?.email ?? '')
        : (user?.email?.split('@').first ?? '');
    final ctrl = TextEditingController(text: currentUsername);
    final passCtrl = TextEditingController();
    bool localLoading = false;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
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
                const Icon(Icons.manage_accounts_rounded,
                    color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                    isGoogleMode
                        ? 'تغيير البريد (Gmail)'
                        : 'تغيير اسم المستخدم',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    isGoogleMode
                        ? 'أدخل بريد Gmail الجديد.'
                        : 'هذا هو الاسم الذي تستخدمه لتسجيل الدخول للحساب.',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: isGoogleMode
                        ? 'البريد الجديد...'
                        : 'اسم المستخدم الجديد...',
                    hintStyle: GoogleFonts.cairo(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور الحالية للتأكيد...',
                    hintStyle: GoogleFonts.cairo(color: Colors.white54),
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
                            onPressed: localLoading
                                ? null
                                : () {
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
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: localLoading
                                ? null
                                : () async {
                                    app.playClick();
                                    final newName = ctrl.text.trim();
                                    final pass = passCtrl.text;
                                    if (newName.isEmpty || pass.isEmpty) return;
                                    setDialogState(() => localLoading = true);
                                    try {
                                      final cred = EmailAuthProvider.credential(
                                          email: user!.email!, password: pass);
                                      await user
                                          .reauthenticateWithCredential(cred);
                                      final newEmail = isGoogleMode
                                          ? newName
                                          : (newName.contains('@')
                                              ? newName
                                              : '$newName@moneybravo.app');
                                      // ignore: deprecated_member_use
                                      await user.updateEmail(newEmail);
                                      if (mounted) {
                                        Navigator.pop(c);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'تم تغيير اسم المستخدم بنجاح ✅',
                                                    style: GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                backgroundColor: Colors.green));
                                        setState(() {});
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'كلمة المرور غير صحيحة، أو الاسم مستخدم مسبقاً!',
                                                  style: GoogleFonts.cairo(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              backgroundColor: Colors.red));
                                    }
                                    setDialogState(() => localLoading = false);
                                  },
                            child: localLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.black, strokeWidth: 2))
                                : Text('حفظ',
                                    style: GoogleFonts.cairo(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String hint, TextEditingController ctrl, bool dark, IconData icon,
      {bool isPass = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: dark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        style: GoogleFonts.cairo(
            color: dark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
              color: dark ? Colors.white54 : Colors.grey[400]),
          prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().darkMode;
    final textColor = dark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        title: Text('الملف الشخصي',
            style: GoogleFonts.cairo(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF7C3AED)),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              final val = _animCtrl.value * 2 * math.pi;
              return Positioned.fill(
                child: Stack(
                  children: [
                    Positioned(
                      top: math.sin(val) * 50,
                      left: math.cos(val) * 50,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF7C3AED)
                                  .withOpacity(dark ? 0.2 : 0.1),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 2),
                        ),
                        child: _photoUrl != null
                            ? ClipOval(
                                child: _photoUrl!.startsWith('http') || kIsWeb
                                    ? Image.network(_photoUrl!,
                                        fit: BoxFit.cover)
                                    : Image.file(File(_photoUrl!),
                                        fit: BoxFit.cover),
                              )
                            : const Center(
                                child:
                                    Text('👤', style: TextStyle(fontSize: 60))),
                      ),
                      if (_photoUrl != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _clearImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFF00B0FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6)
                              ]),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('البيانات الأساسية',
                          style: GoogleFonts.cairo(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 16),
                      // 1. الاسم التفاعلي (مغلق)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: dark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[300]!,
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_rounded,
                                color: Color(0xFF7C3AED)),
                            const SizedBox(width: 16),
                            Text(context.read<AppProvider>().displayName,
                                style: GoogleFonts.cairo(
                                    color:
                                        dark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const Spacer(),
                            const Icon(Icons.lock_outline,
                                color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                      // 2. اسم المستخدم / البريد (قابل للتعديل عبر النافذة)
                      GestureDetector(
                        onTap: () {
                          context.read<AppProvider>().playClick();
                          _showEditUsernameDialog(context, dark, isGoogle);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!,
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  isGoogle ? Icons.email_rounded : Icons.person,
                                  color: const Color(0xFF7C3AED)),
                              const SizedBox(width: 16),
                              Text(
                                  isGoogle
                                      ? (FirebaseAuth
                                              .instance.currentUser?.email ??
                                          '')
                                      : (FirebaseAuth
                                              .instance.currentUser?.email
                                              ?.split('@')
                                              .first ??
                                          ''),
                                  style: GoogleFonts.cairo(
                                      color:
                                          dark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Spacer(),
                              Icon(Icons.edit_rounded,
                                  color: dark ? Colors.white54 : Colors.black54,
                                  size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (!isGoogle) ...[
                        const SizedBox(height: 24),
                        Text('تغيير كلمة المرور 🔒',
                            style: GoogleFonts.cairo(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('مطلوب إدخال كلمة المرور الحالية لحفظ التعديلات.',
                            style: GoogleFonts.cairo(
                                color: dark ? Colors.white54 : Colors.grey[600],
                                fontSize: 12)),
                        const SizedBox(height: 16),
                        _buildInput('كلمة المرور الحالية', _oldPassCtrl, dark,
                            Icons.lock_outline,
                            isPass: true),
                        _buildInput('كلمة المرور الجديدة (اختياري)',
                            _newPassCtrl, dark, Icons.lock,
                            isPass: true),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  context.read<AppProvider>().playClick();
                                  _saveProfile();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 10,
                            shadowColor:
                                const Color(0xFF7C3AED).withOpacity(0.5),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('💾 حفظ التعديلات',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            context.read<AppProvider>().playClick();
                            await context.read<AuthService>().signOut();
                            if (mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white),
                          label: Text('تسجيل الخروج من الحساب',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF1744),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 10,
                            shadowColor:
                                const Color(0xFFFF1744).withOpacity(0.5),
                          ),
                        ),
                      )
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
