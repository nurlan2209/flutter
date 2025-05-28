import 'package:flutter/material.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../core/utils/currency_utils.dart';

class ExpenseInsights extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final String userId;

  const ExpenseInsights({
    super.key,
    required this.expenses,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();
    
    return Column(
      children: insights.map((insight) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: insight.color.withValues(alpha: 0.1),
              child: Icon(insight.icon, color: insight.color),
            ),
            title: Text(insight.title),
            subtitle: Text(insight.description),
          ),
        );
      }).toList(),
    );
  }

  List<_Insight> _generateInsights() {
    final insights = <_Insight>[];
    
    // Highest spending category
    final categoryTotals = <String, double>{};
    for (var expense in expenses) {
      final category = expense.category ?? 'other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }
    
    if (categoryTotals.isNotEmpty) {
      final highestCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final category = CategoryModel.defaultCategories.firstWhere(
        (c) => c.id == highestCategory.key,
        orElse: () => CategoryModel.defaultCategories.last,
      );
      
      insights.add(
        _Insight(
          icon: Icons.trending_up,
          color: Colors.orange,
          title: 'Больше всего тратите на ${category.name.toLowerCase()}',
          description: 'За выбранный период потрачено ${CurrencyUtils.formatAmount(highestCategory.value, 'RUB')}',
        ),
      );
    }
    
    // Average daily spending
    if (expenses.isNotEmpty) {
      final totalDays = expenses.last.date.difference(expenses.first.date).inDays + 1;
      final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final avgDaily = totalAmount / totalDays;
      
      insights.add(
        _Insight(
          icon: Icons.calendar_today,
          color: Colors.blue,
          title: 'Средние расходы в день',
          description: CurrencyUtils.formatAmount(avgDaily, 'RUB'),
        ),
      );
    }
    
    // Most expensive expense
    if (expenses.isNotEmpty) {
      final mostExpensive = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
      insights.add(
        _Insight(
          icon: Icons.attach_money,
          color: Colors.red,
          title: 'Самый крупный расход',
          description: '${mostExpensive.title} - ${CurrencyUtils.formatAmount(mostExpensive.amount, 'RUB')}',
        ),
      );
    }
    
    // Saving tip
    if (categoryTotals.isNotEmpty) {
      final entertainmentTotal = categoryTotals['entertainment'] ?? 0;
      if (entertainmentTotal > 0) {
        final savingPotential = entertainmentTotal * 0.2;
        insights.add(
          _Insight(
            icon: Icons.savings,
            color: Colors.green,
            title: 'Совет по экономии',
            description: 'Сократив расходы на развлечения на 20%, вы сможете сэкономить ${CurrencyUtils.formatAmount(savingPotential, 'RUB')}',
          ),
        );
      }
    }
    
    return insights;
  }
}

class _Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  _Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}