import 'dart:math' as math;
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _showPass = false;
  String _error = '';
  bool _rememberMe = false;

  final _companyCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _loadSavedUser();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _animCtrl.forward();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('mb_saved_email') ?? '';
    final savedPass = prefs.getString('mb_saved_pass') ?? '';
    if (savedEmail.isNotEmpty) {
      setState(() {
        _companyCtrl.text = savedEmail.replaceAll('@moneybravo.app', '');
        _passCtrl.text = savedPass;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _animCtrl.dispose();
    _companyCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    context.read<AppProvider>().playClick();
    setState(() => _loading = true);

    final auth = context.read<AuthService>();
    final input = _companyCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (input.isEmpty || pass.isEmpty) {
      _showSnackBar('يرجى إدخال اسم المستخدم / الإيميل وكلمة المرور.',
          isError: true);
      setState(() => _loading = false);
      return;
    }

    final email = input.contains('@')
        ? input
        : '${input.toLowerCase().replaceAll(' ', '')}@moneybravo.app';

    try {
      if (_isLogin) {
        await auth.signIn(email, pass);
        await _logNewLogin();
      } else {
        await auth.signUp(email, pass);
        if (mounted) {
          _showSnackBar('تم إنشاء الحساب بنجاح! ✨ جاري الدخول...',
              isError: false);
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('mb_saved_email', input);
        await prefs.setString('mb_saved_pass', pass);
      } else {
        await prefs.remove('mb_saved_email');
        await prefs.remove('mb_saved_pass');
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(_mapError(e.code), isError: true);
      setState(() => _loading = false);
    } catch (e) {
      _showSnackBar('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
          isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    context.read<AppProvider>().playClick();
    final input = _companyCtrl.text.trim();
    if (input.isEmpty) {
      _showSnackBar('يرجى إدخال البريد الإلكتروني أولاً.', isError: true);
      return;
    }

    final email = input.contains('@')
        ? input
        : '${input.toLowerCase().replaceAll(' ', '')}@moneybravo.app';

    if (!input.contains('@')) {
      _showSnackBar(
          'استعادة كلمة المرور تعمل فقط مع البريد الإلكتروني الحقيقي. تواصل مع الإدارة.',
          isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().resetPassword(email);
      _showSnackBar('تم إرسال رابط استعادة كلمة المرور لبريدك بنجاح ✅',
          isError: false);
    } catch (e) {
      _showSnackBar('حدث خطأ. تأكد من إدخال بيانات صحيحة وأن الحساب موجود.',
          isError: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _handleGoogleAuth() async {
    context.read<AppProvider>().playClick();
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final userCred = await auth.signInWithGoogle();
      if (userCred == null && mounted) {
        setState(() => _loading = false); // المستخدم تراجع عن التسجيل
      } else if (userCred != null) {
        await _logNewLogin();
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء تسجيل الدخول بجوجل.', isError: true);
      setState(() => _loading = false);
    }
  }

  // دالة لتسجيل حدث الدخول في قاعدة البيانات ليقوم السيرفر بإرسال إشعار للشركاء
  Future<void> _logNewLogin() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        final deviceName = prefs.getString('device_user_name') ?? 'جهاز جديد';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('logs')
            .add({
          'action': 'بتسجيل الدخول للحساب الآن 🔐',
          'by': deviceName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لم يتم العثور على حساب بهذا المستخدم.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'اسم المستخدم مستخدم بالفعل.';
      case 'weak-password':
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
      case 'invalid-email':
        return 'اسم المستخدم غير صالح.';
      default:
        return 'حدث خطأ. كود: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // Animated background blobs
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (context, child) {
              final val = _floatCtrl.value * 2 * math.pi;
              final size = MediaQuery.of(context).size;
              return Stack(
                children: [
                  Positioned(
                      top: -80 + math.sin(val) * 20,
                      right: -80 + math.cos(val) * 20,
                      child: _blob(200, const Color(0xFF7C3AED), 0.15)),
                  Positioned(
                      bottom: -80 + math.cos(val) * 20,
                      left: -80 + math.sin(val) * 20,
                      child: _blob(200, const Color(0xFF4F46E5), 0.15)),
                  Positioned(
                      top: size.height * 0.45 + math.sin(val + math.pi) * 30,
                      left: size.width * 0.3 + math.cos(val + math.pi) * 30,
                      child: _blob(140, const Color(0xFF8B5CF6), 0.1)),
                ],
              );
            },
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text('💰', style: TextStyle(fontSize: 44)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MONEY BRAVO',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      'نظام إدارة الحسابات الاحترافي',
                      style: GoogleFonts.cairo(
                        color: Colors.purple[200],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 20),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Toggle Login/Register
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _tabBtn('تسجيل الدخول', _isLogin, () {
                                  setState(() {
                                    _isLogin = true;
                                    _error = '';
                                  });
                                }),
                                _tabBtn('إنشاء حساب', !_isLogin, () {
                                  setState(() {
                                    _isLogin = false;
                                    _error = '';
                                  });
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Username
                          _inputField(
                            controller: _companyCtrl,
                            hint: 'الإيميل أو اسم المستخدم',
                            icon: '👤',
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          _inputField(
                            controller: _passCtrl,
                            hint: 'كلمة المرور',
                            icon: '🔒',
                            obscure: !_showPass,
                            suffix: GestureDetector(
                              onTap: () {
                                context.read<AppProvider>().playClick();
                                setState(() => _showPass = !_showPass);
                              },
                              child: Text(_showPass ? '🙈' : '👁️'),
                            ),
                            onSubmit: (_) => _handleAuth(),
                          ),
                          const SizedBox(height: 12),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      context.read<AppProvider>().playClick();
                                      setState(
                                          () => _rememberMe = val ?? false);
                                    },
                                    activeColor: const Color(0xFF7C3AED),
                                    side:
                                        const BorderSide(color: Colors.white54),
                                  ),
                                  Text('تذكرني',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                              TextButton(
                                onPressed: _handleForgotPassword,
                                child: Text('نسيت كلمة السر؟',
                                    style: GoogleFonts.cairo(
                                        color: const Color(0xFFD8B4FE),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        shadows: [
                                          Shadow(
                                              color: const Color(0xFFD8B4FE)
                                                  .withOpacity(0.8),
                                              blurRadius: 10)
                                        ])),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // CTA Button
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF4C1D95)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED)
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _isLogin ? 'تسجيل الدخول 🚀' : 'إنشاء حساب ✨',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: Colors.white.withOpacity(0.2))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('أو',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Colors.white.withOpacity(0.2))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Google Sign In Button (3D)
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.05)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF00B0FF)
                                          .withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _handleGoogleAuth,
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                  child: const Text('G',
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Color(0xFF4285F4),
                                          fontWeight: FontWeight.w900)),
                                ),
                                label: Text('المتابعة بحساب جوجل',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay (Blur Animation)
          if (_loading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isLogin
                              ? 'جاري تسجيل الدخول...'
                              : 'جاري إنشاء الحساب...',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<AppProvider>().playClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: active ? const Color(0xFF5B21B6) : Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required String icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textDirection: TextDirection.ltr,
        style:
            GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: Colors.white38),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(icon,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 50, minHeight: 0),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
