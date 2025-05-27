import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../core/utils/currency_utils.dart';

class ExpensePieChart extends StatefulWidget {
  final List<ExpenseModel> expenses;

  const ExpensePieChart({
    Key? key,
    required this.expenses,
  }) : super(key: key);

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int? _touchedIndex;

  Map<String, double> _getCategoryTotals() {
    final totals = <String, double>{};
    
    for (var expense in widget.expenses) {
      final category = expense.category ?? 'other';
      totals[category] = (totals[category] ?? 0) + expense.amount;
    }
    
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _getCategoryTotals();
    final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _buildSections(categoryTotals, total),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categoryTotals.entries.map((entry) {
                final category = CategoryModel.defaultCategories.firstWhere(
                  (c) => c.id == entry.key,
                  orElse: () => CategoryModel.defaultCategories.last,
                );
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                          category.color.replaceAll('#', '0xFF'),
                        )),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${category.icon} ${category.name} ($percentage%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<String, double> categoryTotals,
    double total,
  ) {
    final sections = <PieChartSectionData>[];
    var index = 0;
    
    categoryTotals.forEach((categoryId, amount) {
      final category = CategoryModel.defaultCategories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CategoryModel.defaultCategories.last,
      );
      
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final percentage = amount / total * 100;
      
      sections.add(
        PieChartSectionData(
          color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
          value: amount,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: isTouched
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        CurrencyUtils.formatAmountCompact(amount, 'RUB'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
      index++;
    });
    
    return sections;
  }
}