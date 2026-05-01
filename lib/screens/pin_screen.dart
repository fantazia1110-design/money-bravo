import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  final bool isChange;
  const PinScreen({super.key, required this.isSetup, this.isChange = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPin = '';
  String _step = 'enter'; // verify, enter, confirm, old
  bool _hasError = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    if (widget.isChange) {
      _step = 'old';
    } else if (widget.isSetup) {
      _step = 'enter';
    } else {
      _step = 'verify';
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    context.read<AppProvider>().playClick();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += key;
        _hasError = false;
      });
      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () => _processPin());
      }
    }
  }

  void _onBackspace() {
    context.read<AppProvider>().playClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  void _processPin() {
    final app = context.read<AppProvider>();
    if (_step == 'verify') {
      if (_enteredPin == app.appPin) {
        app.unlockPin();
      } else {
        _showError();
      }
    } else if (_step == 'old') {
      if (_enteredPin == app.appPin) {
        setState(() {
          _step = 'enter';
          _enteredPin = '';
        });
      } else {
        _showError();
      }
    } else if (_step == 'enter') {
      setState(() {
        _firstPin = _enteredPin;
        _step = 'confirm';
        _enteredPin = '';
      });
    } else if (_step == 'confirm') {
      if (_enteredPin == _firstPin) {
        app.setAppPin(_enteredPin);
        if (widget.isChange || widget.isSetup) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم تعيين رمز المرور بنجاح ✅',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        _showError();
        setState(() {
          _step = 'enter';
          _firstPin = '';
        });
      }
    }
  }

  void _showError() {
    setState(() {
      _hasError = true;
      _enteredPin = '';
    });
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
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().darkMode;
    final textColor = dark ? Colors.white : const Color(0xFF1E293B);
    String title = '';
    if (_step == 'verify') title = 'أدخل رمز المرور 🔒';
    if (_step == 'old') title = 'أدخل الرمز الحالي 🔓';
    if (_step == 'enter') title = 'قم بإعداد رمز جديد 🔢';
    if (_step == 'confirm') title = 'تأكيد الرمز الجديد ✔️';

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: (widget.isSetup || widget.isChange)
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: textColor))
          : null,
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
                      top: 100 + math.sin(val) * 30,
                      left: -50 + math.cos(val) * 30,
                      child: _blurredBlob(
                          200,
                          const Color(0xFF7C3AED).withOpacity(dark ? 0.2 : 0.1),
                          80),
                    ),
                    Positioned(
                      bottom: 100 + math.cos(val) * 30,
                      right: -50 + math.sin(val) * 30,
                      child: _blurredBlob(
                          200,
                          const Color(0xFFE040FB).withOpacity(dark ? 0.2 : 0.1),
                          80),
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_step == 'verify')
                  const Icon(Icons.lock_rounded,
                      size: 60, color: Color(0xFF7C3AED)),
                const SizedBox(height: 24),
                Text(title,
                    style: GoogleFonts.cairo(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                if (_hasError)
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('الرمز غير صحيح، حاول مرة أخرى',
                          style: GoogleFonts.cairo(
                              color: Colors.red, fontWeight: FontWeight.bold))),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: isFilled ? 24 : 16,
                      height: isFilled ? 24 : 16,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? const Color(0xFF7C3AED)
                            : (dark ? Colors.white24 : Colors.black12),
                        shape: BoxShape.circle,
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF7C3AED)
                                        .withOpacity(0.5),
                                    blurRadius: 10)
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 60),
                Column(
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['1', '2', '3']
                            .map((k) => _keyBtn(k, dark, textColor))
                            .toList()),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['4', '5', '6']
                            .map((k) => _keyBtn(k, dark, textColor))
                            .toList()),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['7', '8', '9']
                            .map((k) => _keyBtn(k, dark, textColor))
                            .toList()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 80, height: 80),
                        _keyBtn('0', dark, textColor),
                        SizedBox(
                            width: 80,
                            height: 80,
                            child: IconButton(
                                onPressed: _onBackspace,
                                icon: Icon(Icons.backspace_rounded,
                                    color: textColor))),
                      ],
                    ),
                  ],
                ),
                if (widget.isChange && _step == 'old')
                  TextButton(
                    onPressed: () {
                      context.read<AppProvider>().playClick();
                      context.read<AppProvider>().setAppPin(null);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('تم إلغاء رمز المرور',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold))));
                    },
                    child: Text('إلغاء وتفعيل الدخول المباشر',
                        style: GoogleFonts.cairo(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyBtn(String key, bool dark, Color textColor) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1)),
          ),
          child: Center(
              child: Text(key,
                  style: GoogleFonts.cairo(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}
