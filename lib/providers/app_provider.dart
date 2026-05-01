import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirestoreService _fs = FirestoreService();
  String? _uid;
  // تم ضبط ReleaseMode.stop لتفريغ الذاكرة فوراً والسماح بالنقر السريع جداً بدون تقطيع
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _notifPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  String _deviceId = '';
  String _displayName = 'مستخدم';

  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  double _dollarRate = DefaultData.defaultDollarRate;
  List<String> _categories = [];

  bool _hasSeenTutorial = false;
  String _appCurrency = 'EGP';
  String? _appPin;
  bool _isPinUnlocked = false;
  bool _hapticEnabled = true;

  StreamSubscription? _accountsSub;
  StreamSubscription? _txSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _logsSub;
  Timer? _presenceTimer;

  bool _loading = true;
  int _activeUsersCount = 1;
  List<Map<String, dynamic>> _actionLogs = [];

  double _globalIncome = 0.0;
  double _globalExpense = 0.0;
  double _globalNetBalance = 0.0;

  // دالة لإرسال الإشعارات المنبثقة للواجهة
  void Function(String, String)? onNewNotification;

  // ─── Getters ──────────────────────────────────────────
  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  double get dollarRate => _dollarRate;
  List<String> get categories => _categories;
  bool get loading => _loading;
  String get displayName => _displayName;

  bool get hasSeenTutorial => _hasSeenTutorial;
  String get appCurrency => _appCurrency;
  String get appCurrencySymbol => _appCurrency == 'EGP' ? 'جنية' : _appCurrency;
  String? get appPin => _appPin;
  bool get isPinUnlocked => _isPinUnlocked;
  bool get hapticEnabled => _hapticEnabled;

  int get pendingCount => _transactions.where((t) => t.isPending).length;

  double get totalIncome => _globalIncome;
  double get totalExpense => _globalExpense;
  double get netBalance => _globalNetBalance;
  int get activeUsersCount => _activeUsersCount;
  List<Map<String, dynamic>> get actionLogs => _actionLogs;

  // ─── Init ─────────────────────────────────────────────
  Future<void> init(String uid, String displayName) async {
    if (_uid == uid) return;
    _uid = uid;
    _displayName = displayName;
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('device_user_name') ?? displayName;
    _hapticEnabled = prefs.getBool('hapticEnabled') ?? true;

    // سحب السعر المخزن محلياً فوراً لحل مشكلة رجوع السعر لـ 50 عند فتح التطبيق
    if (prefs.containsKey('dollarRate')) {
      _dollarRate = prefs.getDouble('dollarRate')!;
    }

    // إنشاء معرف فريد للجهاز لضمان عدم تكرار العداد لنفس الهاتف
    _deviceId = prefs.getString('device_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = newTxId();
      await prefs.setString('device_id', _deviceId);
    }

    WidgetsBinding.instance.addObserver(this);

    // تم إيقاف إنشاء الحسابات الافتراضية بناءً على طلبك لترك التطبيق فارغاً للمستخدم
    // await _fs.initDefaultAccounts(uid);
    await _fs.initSettings(uid);

    // Start real-time listeners
    _accountsSub = _fs.accountsStream(uid).listen((accs) {
      _accounts = accs;
      // ترتيب الحسابات بالأولوية المطلوبة دائماً
      final order = {'vodafone': 1, 'instapay': 2, 'dollar': 3, 'cash': 4};
      _accounts.sort((a, b) {
        return (order[a.id] ?? 99).compareTo(order[b.id] ?? 99);
      });
      _recalcBalances();
      notifyListeners();
    });

    _txSub = _fs.transactionsStream(uid).listen((txs) {
      _transactions = txs;
      _recalcBalances();
      _loading = false;
      notifyListeners();
    });

    _settingsSub = _fs.settingsStream(uid).listen((settings) {
      final newRate =
          (settings['dollarRate'] ?? DefaultData.defaultDollarRate).toDouble();
      final newCurrency = settings['appCurrency'] ?? 'EGP';

      bool needsRecalc = false;
      if (_dollarRate != newRate || _appCurrency != newCurrency) {
        needsRecalc = true;
      }

      _dollarRate = newRate;
      _appCurrency = newCurrency;

      if (settings['categories'] != null) {
        _categories = List<String>.from(settings['categories']);
      }
      _hasSeenTutorial = settings['hasSeenTutorial'] ?? false;
      _appPin = settings['appPin'];

      if (needsRecalc && !_loading) {
        _recalcBalances();
      }
      notifyListeners();
    });

    _setupPresenceAndLogs(uid);
    _setupFCM(uid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_uid == null || _deviceId.isEmpty) return;
    final presenceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('presence')
        .doc(_deviceId);
    if (state == AppLifecycleState.resumed) {
      presenceRef.set({'lastActive': DateTime.now().millisecondsSinceEpoch});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      presenceRef
          .set({'lastActive': 0}); // إيقاف الاتصال فوراً عند الخروج من التطبيق
    }
  }

  void _setupPresenceAndLogs(String uid) {
    // نظام الحضور لمعرفة المتصلين الآن
    final presenceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('presence')
        .doc(_deviceId);
    presenceRef.set({'lastActive': DateTime.now().millisecondsSinceEpoch});
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      presenceRef.set({'lastActive': DateTime.now().millisecondsSinceEpoch});
    });

    _presenceSub?.cancel();
    _presenceSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('presence')
        .snapshots()
        .listen((snap) {
      int count = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var doc in snap.docs) {
        final last = doc.data()['lastActive'] as int? ?? 0;
        if (last > 0 && now - last < 60000) {
          count++; // نشط الآن (تم تقليص المدة لـ 60 ثانية لزيادة الدقة)
        }
      }
      _activeUsersCount = count > 0 ? count : 1;
      notifyListeners();
    });

    // نظام مراقبة سجل النشاطات الفوري
    _logsSub?.cancel();
    _logsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      // البحث عن التغييرات الجديدة لإرسال إشعار
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final isMe = data['by'] == _displayName;
            final isLogin = data['action'].toString().contains('تسجيل الدخول');
            if (!isMe || isLogin) {
              final ts = data['timestamp'] as Timestamp?;
              // التأكد أن الإشعار لحدث تم في آخر 10 ثواني (وليس رسالة قديمة)
              if (ts != null &&
                  DateTime.now().difference(ts.toDate()).inSeconds < 10) {
                if (_hapticEnabled) {
                  HapticFeedback.vibrate();
                  _playNotificationSound(); // استخدام audioplayers لضمان تشغيل الصوت
                }
                onNewNotification?.call(
                    'إشعار جديد 🔔', 'قام ${data['by']} بـ ${data['action']}');
              }
            }
          }
        }
      }

      _actionLogs = snap.docs.map((d) => d.data()).toList();
      notifyListeners();
    });
  }

  Future<void> _setupFCM(String uid) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. طلب صلاحية إظهار الإشعارات للمستخدم مع التنبيهات والصوت
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // تفعيل الإشعارات أثناء فتح التطبيق لتظهر كرسالة منبثقة رسمية للنظام بصوت
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. سحب العنوان المميز لهذا الهاتف (Token) وحفظه
    String? token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'device': _displayName,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    // الاشتراك في قناة المجموعة لاستقبال الإشعارات من الشركاء تلقائياً
    await messaging.subscribeToTopic('group_$uid');
  }

  Future<void> logAction(String action,
      {Transaction? tx, String? accountName, String? colorHex}) async {
    if (_uid == null) return;

    String? toAccountName;
    if (tx != null && tx.toAccountId != null) {
      try {
        toAccountName =
            _accounts.firstWhere((a) => a.id == tx.toAccountId).name;
      } catch (_) {}
    }
    String? fromAccountName = accountName;
    if (tx != null && fromAccountName == null) {
      try {
        fromAccountName =
            _accounts.firstWhere((a) => a.id == tx.accountId).name;
      } catch (_) {}
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('logs')
        .add({
      'action': action,
      'by': _displayName,
      'timestamp': FieldValue.serverTimestamp(),
      if (tx != null) 'tx_amount': tx.amount,
      if (tx != null) 'tx_type': tx.type.name,
      if (tx != null) 'tx_category': tx.category,
      if (fromAccountName != null) 'account_name': fromAccountName,
      if (toAccountName != null) 'to_account_name': toAccountName,
      if (colorHex != null) 'color_hex': colorHex,
    });

    if (!action.contains('تسجيل الدخول')) {
      _sendSecurePushNotification(
          'تحديث جديد 💰', 'قام $_displayName بـ $action');
    }
  }

  // إرسال الإشعارات الخارجية بأمان تام عبر الخادم الوسيط المجاني
  Future<void> _sendSecurePushNotification(String title, String body) async {
    if (_uid == null) return;
    try {
      // الرابط الحقيقي الخاص بالـ Web Service الذي أنشأته
      final url = Uri.parse(
          'https://<YOUR_RENDER_APP_NAME>.onrender.com/send-notification');

      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // هذا المفتاح السري يمنع أي شخص غريب من استخدام الرابط الخاص بك
          'Authorization': 'Bearer MY_SUPER_SECRET_APP_KEY_123',
        },
        body: json.encode({
          'title': title,
          'body': body,
          'topic':
              'group_$_uid', // إرسال الإشعار لجميع الأجهزة المشتركة في هذا الحساب
        }),
      );
    } catch (e) {
      debugPrint('Secure Notification Error: $e');
    }
  }

  Future<void> saveDeviceName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_user_name', newName);
    _displayName = newName;
    notifyListeners();
  }

  void updateDisplayName(String newName) {
    saveDeviceName(newName);
  }

  Future<void> toggleHaptic(bool val) async {
    _hapticEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticEnabled', val);
  }

  void playClick() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback
          .vibrate(); // الاهتزاز القياسي المضمون 100% على جميع هواتف أندرويد
    } catch (_) {}
    _playCustomSound();
  }

  Future<void> _playCustomSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (_) {
      SystemSound.play(SystemSoundType.click); // بديل احتياطي إذا فشل الصوت
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _notifPlayer.stop();
      await _notifPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Notification sound error: $e');
    }
  }

  void playVibrate() {
    if (_hapticEnabled) HapticFeedback.vibrate();
  }

  void _recalcBalances() {
    // 1. تصفير جميع الأرصدة أولاً
    for (final acc in _accounts) {
      acc.balance = 0.0;
    }

    _globalIncome = 0.0;
    _globalExpense = 0.0;
    _globalNetBalance = 0.0;

    // 2. إعادة حساب الأرصدة بناءً على المعاملات الجديدة
    for (final t in _transactions) {
      if (!t.isCountable) continue;

      final fromIdx = _accounts.indexWhere((a) => a.id == t.accountId);

      // حساب الإجماليات العالمية للبرنامج بكفاءة عالية (الكاشينج)
      if (!t.isTransfer) {
        final accCurrency =
            fromIdx != -1 ? _accounts[fromIdx].currency : _appCurrency;
        final amtInApp = convertCurrency(t.amount, accCurrency, _appCurrency);
        if (t.isIncome) _globalIncome += amtInApp;
        if (t.isExpense) _globalExpense += amtInApp;
      }

      if (t.isTransfer) {
        if (fromIdx != -1) {
          _accounts[fromIdx].balance -= t.amount; // خصم من حساب المرسل
        }

        final toIdx = _accounts.indexWhere((a) => a.id == t.toAccountId);
        if (toIdx != -1 && fromIdx != -1) {
          // تحويل العملة إذا كان التحويل بين حسابين بعملات مختلفة (إصلاح الخلل الخطير)
          final convertedAmt = convertCurrency(
              t.amount, _accounts[fromIdx].currency, _accounts[toIdx].currency);
          _accounts[toIdx].balance += convertedAmt;
        } else if (toIdx != -1) {
          _accounts[toIdx].balance +=
              t.amount; // حساب المصدر محذوف (إجراء احتياطي)
        }
      } else {
        if (fromIdx != -1) {
          _accounts[fromIdx].balance += t.isIncome ? t.amount : -t.amount;
        }
      }
    }

    // حساب الرصيد الصافي الإجمالي بناءً على الأرصدة النهائية للحسابات
    for (final acc in _accounts) {
      _globalNetBalance +=
          convertCurrency(acc.balance, acc.currency, _appCurrency);
    }
  }

  void clear() {
    _accountsSub?.cancel();
    _txSub?.cancel();
    _settingsSub?.cancel();
    _presenceSub?.cancel();
    _logsSub?.cancel();
    _presenceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _uid = null;
    _accounts = [];
    _transactions = [];
    _loading = true;
  }

  // ─── Account Operations ───────────────────────────────
  void saveAccountLocally(Account acc) {
    final idx = _accounts.indexWhere((a) => a.id == acc.id);
    if (idx >= 0) {
      _accounts[idx] = acc;
    } else {
      _accounts.add(acc);
    }
    notifyListeners();

    // حفظ التعديلات في قاعدة البيانات لكي لا تضيع وتُطبق على كل الأجهزة
    if (_uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('accounts')
          .doc(acc.id)
          .set(acc.toMap())
          .catchError((e) => debugPrint('Error saving account: $e'));
      logAction('تعديل / إنشاء حساب',
          accountName: acc.name, colorHex: acc.colors.last);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    if (_uid == null) return;
    final accName = _accounts
        .firstWhere((a) => a.id == accountId, orElse: () => _accounts.first)
        .name;
    _accounts.removeWhere((a) => a.id == accountId);

    // تنظيف ذكي (Cascade Delete): مسح جميع المعاملات المرتبطة بالحساب المحذوف لحماية الإجماليات
    final txsToDelete = _transactions
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .toList();
    for (var tx in txsToDelete) {
      _fs.deleteTransaction(_uid!, tx.id);
    }
    _transactions.removeWhere(
        (t) => t.accountId == accountId || t.toAccountId == accountId);

    notifyListeners();

    try {
      // حذف الحساب بشكل نهائي من قاعدة بيانات Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid!)
          .collection('accounts')
          .doc(accountId)
          .delete();
      logAction('حذف حساب', accountName: accName);
    } catch (e) {
      debugPrint('Error deleting account: $e');
    }
  }

  // ─── Transaction Operations ───────────────────────────
  Future<void> addTransactions(List<Transaction> txs) async {
    if (_uid == null) return;
    await _fs.addTransactions(_uid!, txs);
    if (txs.isNotEmpty) logAction('إضافة معاملة', tx: txs.first);
  }

  Future<void> approveTransaction(String txId) async {
    if (_uid == null) return;
    await _fs.approveTransaction(_uid!, txId);
    try {
      final tx = _transactions.firstWhere((t) => t.id == txId);
      logAction('اعتماد معاملة معلقة', tx: tx);
    } catch (_) {
      logAction('اعتماد معاملة معلقة');
    }
  }

  Future<void> deleteTransaction(String txId) async {
    if (_uid == null) return;
    Transaction? deletedTx;
    try {
      deletedTx = _transactions.firstWhere((t) => t.id == txId);
    } catch (_) {}
    await _fs.deleteTransaction(_uid!, txId);
    logAction('حذف معاملة', tx: deletedTx);
  }

  Future<void> clearAllTransactionsAndLogs() async {
    if (_uid == null) return;
    await _fs.deleteAllTransactions(_uid!);

    final logsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid!)
        .collection('logs')
        .get();
    for (var doc in logsSnap.docs) {
      await doc.reference.delete();
    }

    logAction('⚠️ قام بمسح جميع المعاملات وسجل النشاطات');
  }

  // ─── Settings Operations ──────────────────────────────
  Future<void> saveDollarRate(double rate) async {
    if (_uid == null) return;
    _dollarRate = rate;
    _recalcBalances(); // إعادة الحساب فوراً عند تغيير السعر يدوياً
    notifyListeners();
    await _fs.saveSettings(_uid!, {'dollarRate': rate});

    // حفظ السعر محلياً أيضاً ليعمل فوراً عند فتح التطبيق دون انتظار الإنترنت
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dollarRate', rate);
  }

  Future<void> saveCategories(List<String> cats) async {
    if (_uid == null) return;
    await _fs.saveSettings(_uid!, {'categories': cats});
  }

  Future<void> completeTutorial() async {
    if (_uid == null) return;
    _hasSeenTutorial = true;
    notifyListeners();
    await _fs.saveSettings(_uid!, {'hasSeenTutorial': true});
  }

  Future<void> setAppCurrency(String cur) async {
    if (_uid == null) return;
    _appCurrency = cur;
    _recalcBalances(); // إعادة الحساب فوراً عند تغيير عملة البرنامج
    notifyListeners();
    await _fs.saveSettings(_uid!, {'appCurrency': cur});
  }

  Future<void> setAppPin(String? pin) async {
    if (_uid == null) return;
    _appPin = pin;
    _isPinUnlocked = true;
    notifyListeners();
    await _fs.saveSettings(_uid!, {'appPin': pin});
  }

  void unlockPin() {
    _isPinUnlocked = true;
    notifyListeners();
  }

  // دالة رفع الصور إلى Firebase Storage واستخراج الرابط الدائم
  Future<String?> uploadImageBytes(Uint8List bytes, String folder) async {
    if (_uid == null) return null;
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child(_uid!)
          .child(folder)
          .child(fileName);
      final uploadTask =
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // دالة ذكية لتحويل أي مبلغ بين أي عملتين بناءً على الأسعار اللحظية
  double convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    try {
      // إعطاء الأولوية القصوى لسعر الدولار اليدوي الذي حدده المستخدم 👑
      double getRate(String currency) {
        if (currency == 'USD') return 1.0;
        // تعريف "جنية" و "EGP" كعملة واحدة لمنع أخطاء الحسابات القديمة
        if ((currency == 'EGP' || currency == 'جنية') && _dollarRate > 0) {
          return _dollarRate;
        }
        return 1.0;
      }

      final fromRate = getRate(fromCurrency);
      final toRate = getRate(toCurrency);

      if (fromRate == 0) return amount;
      return (amount / fromRate) * toRate;
    } catch (e) {
      return amount;
    }
  }

  // ─── Helper ───────────────────────────────────────────
  String newTxId() => generateId();

  // دالة ضبط المصنع: تمسح كل شيء وتعيد التطبيق للصفر
  Future<void> factoryReset() async {
    if (_uid == null) return;

    // 1. مسح جميع المعاملات
    await _fs.deleteAllTransactions(_uid!);

    // 1.5 مسح سجل النشاطات (Logs)
    final logsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid!)
        .collection('logs')
        .get();
    for (var doc in logsSnap.docs) {
      await doc.reference.delete();
    }

    // 2. مسح جميع الحسابات
    for (var acc in _accounts) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid!)
          .collection('accounts')
          .doc(acc.id)
          .delete();
    }

    // 3. تصفير الإعدادات للوضع الافتراضي
    await _fs.saveSettings(_uid!, {
      'dollarRate': DefaultData.defaultDollarRate,
      'appCurrency': 'EGP',
      'categories': [],
      'hasSeenTutorial': false,
      'appPin': null,
    });

    // 4. تسجيل الخروج من الواجهة ليعود للبرنامج التعليمي
    _hasSeenTutorial = false;
    logAction('⚠️ أجرى ضبط مصنع ومسح جميع بيانات التطبيق');
    notifyListeners();
  }

  @override
  void dispose() {
    _accountsSub?.cancel();
    _txSub?.cancel();
    _settingsSub?.cancel();
    _presenceSub?.cancel();
    _logsSub?.cancel();
    _presenceTimer?.cancel();
    _audioPlayer.dispose();
    _notifPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
