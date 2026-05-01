import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer }

enum TransactionStatus { completed, pending, approved }

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'دخل';
      case TransactionType.expense:
        return 'مصروف';
      case TransactionType.transfer:
        return 'تحويل';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.income:
        return '⬆️';
      case TransactionType.expense:
        return '⬇️';
      case TransactionType.transfer:
        return '↔️';
    }
  }
}

extension TransactionStatusExt on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.completed:
        return 'مكتملة';
      case TransactionStatus.pending:
        return 'معلقة';
      case TransactionStatus.approved:
        return 'معتمدة';
    }
  }
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String accountId;
  final String? toAccountId;
  final DateTime date;
  final TransactionStatus status;
  final String category;
  final String notes;
  final String? createdBy;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.accountId,
    this.toAccountId,
    required this.date,
    required this.status,
    required this.category,
    this.notes = '',
    this.createdBy,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;
  bool get isPending => status == TransactionStatus.pending;
  bool get isCountable =>
      status == TransactionStatus.completed ||
      status == TransactionStatus.approved;

  factory Transaction.fromMap(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      accountId: data['accountId'] ?? '',
      toAccountId: data['toAccountId'],
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : (data['date'] is String
              ? DateTime.tryParse(data['date']) ?? DateTime.now()
              : DateTime.now()),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.completed,
      ),
      category: data['category'] ?? 'أخرى',
      notes: data['notes'] ?? '',
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'type': type.name,
        'accountId': accountId,
        if (toAccountId != null) 'toAccountId': toAccountId,
        'date': Timestamp.fromDate(date),
        'status': status.name,
        'category': category,
        'notes': notes,
        if (createdBy != null) 'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Transaction copyWith({TransactionStatus? status}) => Transaction(
        id: id,
        description: description,
        amount: amount,
        type: type,
        accountId: accountId,
        toAccountId: toAccountId,
        date: date,
        status: status ?? this.status,
        category: category,
        notes: notes,
        createdBy: createdBy,
      );
}
