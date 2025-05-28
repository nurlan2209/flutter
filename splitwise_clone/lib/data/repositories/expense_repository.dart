import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createExpense(ExpenseModel expense) async {
    try {
      final docRef = await _firestore.collection('expenses').add(expense.toMap());
      
      // Calculate and create debts
      await _calculateAndCreateDebts(expense.copyWith(id: docRef.id));
      
      // Update group last activity
      await _firestore.collection('groups').doc(expense.groupId).update({
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания расхода: $e');
    }
  }

  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<ExpenseModel>> getUserExpenses(String userId, {String? groupId}) {
    Query query = _firestore.collection('expenses');
    
    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }
    
    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((expense) => 
              expense.paidBy == userId || 
              expense.splitAmounts.containsKey(userId))
          .toList();
    });
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());
    
    // Recalculate debts
    await _recalculateDebts(expense);
  }

  Future<void> deleteExpense(String expenseId) async {
    // Get expense details first
    final doc = await _firestore.collection('expenses').doc(expenseId).get();
    if (!doc.exists) return;
    
    // Delete related debts
    final debts = await _firestore
        .collection('debts')
        .where('expenseId', isEqualTo: expenseId)
        .get();
    
    for (var debt in debts.docs) {
      await debt.reference.delete();
    }
    
    // Delete expense
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  Future<void> _calculateAndCreateDebts(ExpenseModel expense) async {
    final batch = _firestore.batch();
    
    expense.splitAmounts.forEach((userId, amount) {
      if (userId != expense.paidBy && amount > 0) {
        final debtDoc = _firestore.collection('debts').doc();
        batch.set(debtDoc, {
          'from': userId,
          'to': expense.paidBy,
          'amount': amount,
          'settledAmount': 0,
          'currency': expense.currency,
          'groupId': expense.groupId,
          'expenseId': expense.id,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
    
    await batch.commit();
  }

  Future<void> _recalculateDebts(ExpenseModel expense) async {
    // Delete old debts
    final oldDebts = await _firestore
        .collection('debts')
        .where('expenseId', isEqualTo: expense.id)
        .get();
    
    for (var debt in oldDebts.docs) {
      await debt.reference.delete();
    }
    
    // Create new debts
    await _calculateAndCreateDebts(expense);
  }
}