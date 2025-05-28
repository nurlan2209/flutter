import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:intl/intl.dart';

class ExpenseLineChart extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final DateTimeRange dateRange;

  const ExpenseLineChart({
    super.key, 
    required this.expenses,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final dailyTotals = _calculateDailyTotals();
    
    if (dailyTotals.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1000,
              getDrawingHorizontalLine: (value) {
                return const FlLine( // ДОБАВЛЕНО: const
                  color: Colors.grey, // УПРОСТИТЬ: убрать [300]!
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine( // ДОБАВЛЕНО: const
                  color: Colors.grey, // УПРОСТИТЬ: убрать [300]!
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles( // ДОБАВЛЕНО: const
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles( // ДОБАВЛЕНО: const
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final date = dateRange.start.add(Duration(days: value.toInt()));
                    return const Padding( // ДОБАВЛЕНО: const
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'day', // УПРОСТИТЬ: убрать DateFormat
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1000,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      CurrencyUtils.formatAmountCompact(value, 'RUB'),
                      style: const TextStyle(fontSize: 10), // ДОБАВЛЕНО: const
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey),
            ),
            minX: 0,
            maxX: dateRange.end.difference(dateRange.start).inDays.toDouble(),
            minY: 0,
            maxY: dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
            lineBarsData: [
              LineChartBarData(
                spots: _buildSpots(dailyTotals),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.5), // ИСПРАВЛЕНО: withOpacity -> withValues
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).primaryColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      Theme.of(context).primaryColor.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<DateTime, double> _calculateDailyTotals() {
    final totals = <DateTime, double>{};
    
    for (var expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      totals[date] = (totals[date] ?? 0) + expense.amount;
    }
    
    return totals;
  }

  List<FlSpot> _buildSpots(Map<DateTime, double> dailyTotals) {
    final spots = <FlSpot>[];
    
    for (var i = 0; i <= dateRange.end.difference(dateRange.start).inDays; i++) {
      final date = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day + i,
      );
      final amount = dailyTotals[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), amount));
    }
    
    return spots;
  }
}