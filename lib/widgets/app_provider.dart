import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isAutoDollar = false;
  bool _isPinUnlocked = false;
  bool _hapticEnabled = true;

  DateTime _lastSeenTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
  List<Map<String, dynamic>> _notifications = [];
  final Set<String> _handledNotifs = {};

  StreamSubscription? _accountsSub;
  StreamSubscription? _txSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _categoriesSub;
  Timer? _presenceTimer;

  bool _loading = true;
  int _activeUsersCount = 1;
  List<Map<String, dynamic>> _actionLogs = [];

  double _globalIncome = 0.0;
  double _globalExpense = 0.0;
  double _globalNetBalance = 0.0;
  double _companyNetProfit = 0.0;
  static bool _hasLoggedAppOpen = false;

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
  bool get isAutoDollar => _isAutoDollar;
  bool get isPinUnlocked => _isPinUnlocked;
  bool get hapticEnabled => _hapticEnabled;

  DateTime get lastSeenTimestamp => _lastSeenTimestamp;
  List<Map<String, dynamic>> get notifications => _notifications;

  int get pendingCount => _transactions.where((t) => t.isPending).length;

  double get totalIncome => _globalIncome;
  double get totalExpense => _globalExpense;
  double get netBalance => _globalNetBalance;
  double get companyNetProfit => _companyNetProfit;
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
    _isAutoDollar = prefs.getBool('isAutoDollar') ?? false;
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;

    final lastSeenMs = prefs.getInt('last_seen_notif') ?? 0;
    _lastSeenTimestamp = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);

    // سحب السعر المخزن محلياً فوراً لحل مشكلة رجوع السعر لـ 50 عند فتح التطبيق
    if (prefs.containsKey('dollarRate')) {
      _dollarRate = prefs.getDouble('dollarRate')!;
    }

    // استرجاع الفئات محلياً لسرعة العرض وحل مشكلة التأخير
    final localCats = prefs.getStringList('local_categories');
    if (localCats != null && localCats.isNotEmpty) {
      _categories = localCats;
    }

    if (_isAutoDollar) {
      fetchDollarRate();
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

    // استرجاع الفئات من مجموعة منفصلة لضمان عدم حذفها
    _categoriesSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('user_data')
        .doc('categories')
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        final items = snap.data()!['items'];
        if (items != null) {
          _categories = List<String>.from(items);
          prefs.setStringList('local_categories', _categories);
          notifyListeners();
        }
      }
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

      // تم إيقاف سحب الفئات من هنا لحل مشكلة الحذف، وتُنقل لمجموعة منفصلة
      // _hasSeenTutorial = settings['hasSeenTutorial'] ?? false; // تم سحبها من SharedPreferences لمنع الوميض
      _appPin = settings['appPin'];
      _isAutoDollar = settings['isAutoDollar'] ?? _isAutoDollar;

      if (needsRecalc && !_loading) {
        _recalcBalances();
      }
      notifyListeners();
    });

    _setupPresenceAndLogs(uid);
    _setupFCM(uid);
    _setupNotificationsListener(uid);

    // إرسال إشعار لحظي (داخلي + خارجي) للشركاء بمجرد فتح التطبيق أو تسجيل الدخول
    if (!_hasLoggedAppOpen && _displayName != 'مستخدم') {
      _hasLoggedAppOpen = true;
      if (_hapticEnabled) {
        // تشغيل صوت الإشعار عند فتح التطبيق لأول مرة في الجلسة
        _playDynamicSound('system');
      }
      Future.delayed(const Duration(seconds: 3), () {
        logAction('بفتح التطبيق / تسجيل الدخول الآن 📱');
      });
    }
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
    bool isFirstLogSnapshot = true;
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
      if (isFirstLogSnapshot) {
        isFirstLogSnapshot = false;
        _actionLogs = snap.docs.map((d) => d.data()).toList();
        notifyListeners();
        return; // تجاهل الإشعارات للبيانات القديمة عند فتح التطبيق
      }

      _actionLogs = snap.docs.map((d) => d.data()).toList();
      notifyListeners();
    });
  }

  void _setupNotificationsListener(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final id = data['id'] as String? ?? '';
            // منع تكرار الإشعار
            if (_handledNotifs.contains(id)) continue;
            _handledNotifs.add(id);

            final ts = data['createdAt'] as Timestamp?;
            final notifDate = ts?.toDate() ?? DateTime.now();
            final sender = data['sender'] as String? ?? '';

            // عرض الإشعار فقط إذا كان أحدث من آخر مرة فتحنا فيها مركز الإشعارات
            if (notifDate.isAfter(_lastSeenTimestamp) &&
                sender != _displayName) {
              if (_hapticEnabled) {
                HapticFeedback.vibrate();
                _playDynamicSound(data['type'] ?? 'system');
              }
              onNewNotification?.call(
                  data['title'] ?? 'إشعار جديد', data['body'] ?? '');
            }
          }
        }
      }
      _notifications = snap.docs.map((d) => d.data()).toList();
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

    // الحل الشامل لمشكلة الإشعارات أثناء فتح التطبيق (Foreground Notifications)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        if (_hapticEnabled) {
          HapticFeedback.vibrate();
          _playDynamicSound('system');
        }
        onNewNotification?.call(message.notification!.title ?? 'إشعار جديد',
            message.notification!.body ?? '');
      }
    });
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
  }

  Future<void> sendNotification({
    required String type,
    required String title,
    required String body,
  }) async {
    if (_uid == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'type': type,
      'title': title,
      'body': body,
      'sender': _displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _sendSecurePushNotification(title, body, type: type);
  }

  // إرسال الإشعارات الخارجية بأمان تام عبر الخادم الوسيط المجاني
  Future<void> _sendSecurePushNotification(String title, String body,
      {String type = 'system'}) async {
    if (_uid == null) return;
    try {
      String soundName = 'notification';

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
          // إعدادات الصوت المخصص للإشعارات الخارجية (التطبيق مغلق)
          'android': {
            'notification': {
              'sound': soundName,
              'channel_id': 'custom_sound_channel'
            }
          },
          'apns': {
            'payload': {
              'aps': {'sound': '$soundName.mp3'}
            }
          }
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

  Future<void> _playDynamicSound(String type) async {
    try {
      await _notifPlayer.stop();
      await _notifPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      try {
        await _notifPlayer.play(AssetSource('sounds/notification.mp3'));
      } catch (_) {}
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
    _companyNetProfit = 0.0;
    double totalPartnerWithdrawals = 0.0;

    // 2. إعادة حساب الأرصدة بناءً على المعاملات الجديدة
    for (final t in _transactions) {
      if (!t.isCountable) continue;

      final fromIdx = _accounts.indexWhere((a) => a.id == t.accountId);
      final isPartnerAcc = fromIdx != -1 && _accounts[fromIdx].isPartner;

      // حساب الإجماليات العالمية للبرنامج بكفاءة عالية (الكاشينج)
      if (!t.isTransfer && !isPartnerAcc) {
        final accCurrency =
            fromIdx != -1 ? _accounts[fromIdx].currency : _appCurrency;
        final amtInApp = convertCurrency(t.amount, accCurrency, _appCurrency);
        if (t.isIncome) {
          _globalIncome += amtInApp;
        }
        if (t.isExpense) {
          _globalExpense += amtInApp;
        }
      }

      // حساب سحوبات الشركاء الفعلية من خلال رصد الخصم المباشر من حساب الشريك
      if (!t.isTransfer && isPartnerAcc && t.isExpense) {
        final accCurrency = _accounts[fromIdx].currency;
        totalPartnerWithdrawals +=
            convertCurrency(t.amount, accCurrency, _appCurrency);
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

    // 3. حساب الرصيد الصافي الإجمالي الفعلي (الكاش المتوفر)
    for (final acc in _accounts) {
      if (!acc.isPartner) {
        _globalNetBalance +=
            convertCurrency(acc.balance, acc.currency, _appCurrency);
      }
    }

    // 4. تحديد وعاء أرباح الشركة كصافي دخل حقيقي
    // صافي الدخل = إجمالي الدخل - (المصروفات التشغيلية بدون سحوبات الشركاء)
    _companyNetProfit =
        _globalIncome - (_globalExpense - totalPartnerWithdrawals);

    // 5. توزيع الأرباح الديناميكية على أرصدة الشركاء
    for (final acc in _accounts) {
      if (acc.isPartner) {
        double dynamicShare = _companyNetProfit * (acc.partnerShare / 100);
        double dynamicShareInPartnerCurrency =
            convertCurrency(dynamicShare, _appCurrency, acc.currency);
        acc.balance += dynamicShareInPartnerCurrency;
      }
    }
  }

  void clear() {
    _accountsSub?.cancel();
    _txSub?.cancel();
    _settingsSub?.cancel();
    _presenceSub?.cancel();
    _logsSub?.cancel();
    _categoriesSub?.cancel();
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
    _recalcBalances(); // تحديث فوري للأرصدة لتظهر أرباح الشركاء فور حفظ الحساب
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

    _recalcBalances(); // تحديث فوري للأرصدة
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

  Future<void> updateLastSeen() async {
    _lastSeenTimestamp = DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_seen_notif', _lastSeenTimestamp.millisecondsSinceEpoch);
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
    _categories = cats;
    notifyListeners(); // تحديث الواجهة فوراً لتجنب اختفاء الفئات

    // حفظ الفئات في مسار مستقل زي الحسابات لضمان عدم مسحها أبداً
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid!)
        .collection('user_data')
        .doc('categories')
        .set({'items': cats});

    // await _fs.saveSettings(_uid!, {'categories': cats}); // تم إيقافها لمنع التداخل
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_categories', cats); // حفظ محلي سريع
  }

  Future<void> completeTutorial() async {
    if (_uid == null) return;
    _hasSeenTutorial = true;
    notifyListeners();
    await _fs.saveSettings(_uid!, {'hasSeenTutorial': true});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
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

  // دالة تفعيل/إلغاء التحديث التلقائي لسعر الدولار
  Future<void> toggleAutoDollar(bool val) async {
    _isAutoDollar = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoDollar', val);

    if (_uid != null) {
      await _fs.saveSettings(_uid!, {'isAutoDollar': val});
    }

    if (val) {
      await fetchDollarRate();
    }
  }

  // دالة لجلب سعر الدولار من واجهة برمجة تطبيقات (API)
  Future<void> fetchDollarRate() async {
    try {
      final res =
          await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final rate = data['rates']?['EGP'];
        if (rate != null) {
          await saveDollarRate(rate.toDouble());
        }
      }
    } catch (e) {
      debugPrint('Error fetching dollar rate: $e');
    }
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
    _categoriesSub?.cancel();
    _presenceTimer?.cancel();
    _audioPlayer.dispose();
    _notifPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // دالة ذكية لحساب إجمالي أرباح الشريك (نصيبه التلقائي + إيداعاته اليدوية)
  double getPartnerTotalProfit(Account acc) {
    double dynamicShare = _companyNetProfit * (acc.partnerShare / 100);
    double dynamicShareInPartnerCurrency =
        convertCurrency(dynamicShare, _appCurrency, acc.currency);

    double manualIncome = 0.0;
    for (var t in _transactions) {
      if (!t.isCountable) continue;
      if (t.accountId == acc.id && t.isIncome) {
        manualIncome += t.amount;
      }
      if (t.isTransfer && t.toAccountId == acc.id) {
        final fromAcc =
            _accounts.firstWhere((a) => a.id == t.accountId, orElse: () => acc);
        manualIncome +=
            convertCurrency(t.amount, fromAcc.currency, acc.currency);
      }
    }
    return dynamicShareInPartnerCurrency + manualIncome;
  }
}
