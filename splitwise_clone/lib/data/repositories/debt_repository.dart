import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

class DebtRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DebtModel>> getUserDebts(String userId) {
    final owedByUser = _firestore
        .collection('debts')
        .where('from', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'partial'])
        .snapshots();
    
    final owedToUser = _firestore
        .collection('debts')
        .where('to', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'partial'])
        .snapshots();

    return owedByUser.asyncMap((snapshot1) async {
      final snapshot2 = await owedToUser.first;
      final allDocs = [...snapshot1.docs, ...snapshot2.docs];
      
      return allDocs
          .map((doc) => DebtModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Map<String, double>> getSimplifiedDebts(String userId, {String? groupId}) async {
    try {
      Query query = _firestore.collection('debts');
      
      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }
      
      final snapshot = await query.get();
      final debts = snapshot.docs.map((doc) => DebtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      // Calculate net debts
      final netDebts = <String, double>{};
      
      for (var debt in debts) {
        if (debt.status != DebtStatus.settled) {
          final remaining = debt.remainingAmount;
          
          if (debt.from == userId) {
            netDebts[debt.to] = (netDebts[debt.to] ?? 0) - remaining;
          } else if (debt.to == userId) {
            netDebts[debt.from] = (netDebts[debt.from] ?? 0) + remaining;
          }
        }
      }
      
      // Remove zero balances
      netDebts.removeWhere((key, value) => value.abs() < 0.01);
      
      return netDebts;
    } catch (e) {
      throw Exception('Ошибка получения долгов: $e');
    }
  }

  Future<void> settleDebt({
    required String debtId,
    required double amount,
    required String settledBy,
    String? note,
  }) async {
    try {
      final doc = await _firestore.collection('debts').doc(debtId).get();
      if (!doc.exists) throw Exception('Долг не найден');
      
      final debt = DebtModel.fromMap(doc.data()!, doc.id);
      final newSettledAmount = debt.settledAmount + amount;
      final settlements = debt.settlements ?? [];
      
      settlements.add(SettlementRecord(
        amount: amount,
        date: DateTime.now(),
        note: note,
        settledBy: settledBy,
      ));
      
      await _firestore.collection('debts').doc(debtId).update({
        'settledAmount': newSettledAmount,
        'status': newSettledAmount >= debt.amount ? 'settled' : 'partial',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'settlements': settlements.map((s) => s.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Ошибка погашения долга: $e');
    }
  }

  Future<void> settleAllDebts(String userId1, String userId2, {String? groupId}) async {
    try {
      Query query = _firestore.collection('debts');
      
      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }
      
      final debts1 = await query
          .where('from', isEqualTo: userId1)
          .where('to', isEqualTo: userId2)
          .where('status', whereIn: ['pending', 'partial'])
          .get();
      
      final debts2 = await query
          .where('from', isEqualTo: userId2)
          .where('to', isEqualTo: userId1)
          .where('status', whereIn: ['pending', 'partial'])
          .get();
      
      final batch = _firestore.batch();
      
      for (var doc in [...debts1.docs, ...debts2.docs]) {
        final debt = DebtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        batch.update(doc.reference, {
          'status': 'settled',
          'settledAmount': debt.amount,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка погашения всех долгов: $e');
    }
  }
}