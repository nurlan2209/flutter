import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType { equal, manual, percentage, shares }

class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String paidBy;
  final Map<String, double> splitAmounts; // userId: amount
  final SplitType splitType;
  final String? category;
  final DateTime date;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic>? metadata;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.splitAmounts,
    required this.splitType,
    this.category,
    required this.date,
    required this.createdAt,
    required this.createdBy,
    this.metadata,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      paidBy: map['paidBy'] ?? '',
      splitAmounts: Map<String, double>.from(
        map['splitAmounts']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {},
      ),
      splitType: SplitType.values.firstWhere(
        (e) => e.toString() == 'SplitType.${map['splitType']}',
        orElse: () => SplitType.equal,
      ),
      category: map['category'],
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'paidBy': paidBy,
      'splitAmounts': splitAmounts,
      'splitType': splitType.toString().split('.').last,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  double getUserShare(String userId) => splitAmounts[userId] ?? 0.0;
  
  double getUserBalance(String userId) {
    if (paidBy == userId) {
      return amount - getUserShare(userId);
    } else {
      return -getUserShare(userId);
    }
  }
  
  ExpenseModel copyWith({String? id}) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId,
      title: title,
      description: description,
      amount: amount,
      currency: currency,
      paidBy: paidBy,
      splitAmounts: splitAmounts,
      splitType: splitType,
      category: category,
      date: date,
      createdAt: createdAt,
      createdBy: createdBy,
      metadata: metadata,
    );
  }
}