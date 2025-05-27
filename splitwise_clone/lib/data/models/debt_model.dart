import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtStatus { pending, partial, settled }

class DebtModel {
  final String id;
  final String from; // userId who owes
  final String to; // userId who is owed
  final double amount;
  final double settledAmount;
  final String currency;
  final String? groupId;
  final String? expenseId;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final List<SettlementRecord>? settlements;

  DebtModel({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.settledAmount,
    required this.currency,
    this.groupId,
    this.expenseId,
    required this.status,
    required this.createdAt,
    this.lastUpdatedAt,
    this.settlements,
  });

  factory DebtModel.fromMap(Map<String, dynamic> map, String id) {
    return DebtModel(
      id: id,
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      settledAmount: (map['settledAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      groupId: map['groupId'],
      expenseId: map['expenseId'],
      status: DebtStatus.values.firstWhere(
        (e) => e.toString() == 'DebtStatus.${map['status']}',
        orElse: () => DebtStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: map['lastUpdatedAt'] != null
          ? (map['lastUpdatedAt'] as Timestamp).toDate()
          : null,
      settlements: map['settlements'] != null
          ? (map['settlements'] as List)
              .map((s) => SettlementRecord.fromMap(s))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'amount': amount,
      'settledAmount': settledAmount,
      'currency': currency,
      'groupId': groupId,
      'expenseId': expenseId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': lastUpdatedAt != null
          ? Timestamp.fromDate(lastUpdatedAt!)
          : null,
      'settlements': settlements?.map((s) => s.toMap()).toList(),
    };
  }

  double get remainingAmount => amount - settledAmount;
  bool get isSettled => status == DebtStatus.settled;
}

class SettlementRecord {
  final double amount;
  final DateTime date;
  final String? note;
  final String settledBy;

  SettlementRecord({
    required this.amount,
    required this.date,
    this.note,
    required this.settledBy,
  });

  factory SettlementRecord.fromMap(Map<String, dynamic> map) {
    return SettlementRecord(
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'],
      settledBy: map['settledBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'settledBy': settledBy,
    };
  }
}