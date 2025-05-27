import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/debt_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/debt_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final DebtRepository _debtRepository = DebtRepository();
  
  List<ExpenseModel> _expenses = [];
  List<DebtModel> _debts = [];
  Map<String, double> _simplifiedDebts = {};
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  List<DebtModel> get debts => _debts;
  Map<String, double> get simplifiedDebts => _simplifiedDebts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadGroupExpenses(String groupId) {
    _expenseRepository.getGroupExpenses(groupId).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  void loadUserDebts(String userId) {
    _debtRepository.getUserDebts(userId).listen((debts) {
      _debts = debts;
      notifyListeners();
    });
  }

  Future<void> loadSimplifiedDebts(String userId, {String? groupId}) async {
    try {
      _simplifiedDebts = await _debtRepository.getSimplifiedDebts(userId, groupId: groupId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createExpense(ExpenseModel expense) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _expenseRepository.createExpense(expense);
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _expenseRepository.updateExpense(expense);
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _expenseRepository.deleteExpense(expenseId);
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> settleDebt({
    required String debtId,
    required double amount,
    required String settledBy,
    String? note,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _debtRepository.settleDebt(
        debtId: debtId,
        amount: amount,
        settledBy: settledBy,
        note: note,
      );
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> settleAllDebts(String userId1, String userId2, {String? groupId}) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _debtRepository.settleAllDebts(userId1, userId2, groupId: groupId);
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  double calculateTotalExpenses({String? userId, String? groupId}) {
    var filtered = _expenses;
    
    if (groupId != null) {
      filtered = filtered.where((e) => e.groupId == groupId).toList();
    }
    
    if (userId != null) {
      filtered = filtered.where((e) => 
        e.paidBy == userId || e.splitAmounts.containsKey(userId)
      ).toList();
    }
    
    return filtered.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> calculateCategoryExpenses({String? userId, String? groupId}) {
    var filtered = _expenses;
    
    if (groupId != null) {
      filtered = filtered.where((e) => e.groupId == groupId).toList();
    }
    
    if (userId != null) {
      filtered = filtered.where((e) => 
        e.paidBy == userId || e.splitAmounts.containsKey(userId)
      ).toList();
    }
    
    final categoryTotals = <String, double>{};
    
    for (var expense in filtered) {
      final category = expense.category ?? 'other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}