import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

/// Firestore paths:
/// users/{uid}/accounts/{accountId}
/// users/{uid}/transactions/{txId}
/// users/{uid}/settings (single doc)

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    // تفعيل وضع الأوفلاين صراحة للحفظ التلقائي عند انقطاع الإنترنت
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ─── Refs ─────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _accountsRef(String uid) =>
      _db.collection('users').doc(uid).collection('accounts');

  CollectionReference<Map<String, dynamic>> _txRef(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  DocumentReference<Map<String, dynamic>> _settingsRef(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('data');

  // ─── Real-time Streams ────────────────────────────────
  Stream<List<Account>> accountsStream(String uid) {
    return _accountsRef(uid).snapshots().map((snap) =>
        snap.docs.map((d) => Account.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Transaction>> transactionsStream(String uid) {
    return _txRef(uid).orderBy('date', descending: true).snapshots().map(
        (snap) =>
            snap.docs.map((d) => Transaction.fromMap(d.data(), d.id)).toList());
  }

  Stream<Map<String, dynamic>> settingsStream(String uid) {
    return _settingsRef(uid).snapshots().map((snap) => snap.data() ?? {});
  }

  // ─── Accounts CRUD ────────────────────────────────────
  Future<void> initDefaultAccounts(String uid) async {
    final batch = _db.batch();
    for (final a in DefaultData.accounts) {
      final ref = _accountsRef(uid).doc(a['id'] as String);
      batch.set(
          ref,
          {
            'name': a['name'],
            'currency': a['currency'],
            'icon': a['icon'],
            'colors': a['colors'],
          },
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─── Transactions CRUD ────────────────────────────────
  Future<void> addTransaction(String uid, Transaction tx) async {
    await _txRef(uid).doc(tx.id).set(tx.toMap());
  }

  Future<void> addTransactions(String uid, List<Transaction> txs) async {
    final batch = _db.batch();
    for (final tx in txs) {
      batch.set(_txRef(uid).doc(tx.id), tx.toMap());
    }
    await batch.commit();
  }

  Future<void> approveTransaction(String uid, String txId) async {
    await _txRef(uid).doc(txId).update({'status': 'approved'});
  }

  Future<void> deleteTransaction(String uid, String txId) async {
    await _txRef(uid).doc(txId).delete();
  }

  Future<void> deleteAllTransactions(String uid) async {
    final snap = await _txRef(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Settings ─────────────────────────────────────────
  Future<void> saveSettings(String uid, Map<String, dynamic> data) async {
    await _settingsRef(uid).set(data, SetOptions(merge: true));
  }

  Future<void> initSettings(String uid) async {
    await _settingsRef(uid).set({
      'dollarRate': DefaultData.defaultDollarRate,
      'categories': [],
    }, SetOptions(merge: true));
  }
}
