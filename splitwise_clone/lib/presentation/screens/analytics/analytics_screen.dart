import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/utils/currency_utils.dart';
import 'widgets/expense_pie_chart.dart';
import 'widgets/expense_line_chart.dart';
import 'widgets/expense_insights.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedGroupId;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<ExpenseProvider>().loadUserDebts(userId);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  List<ExpenseModel> _getFilteredExpenses() {
    final expenses = context.read<ExpenseProvider>().expenses;
    
    return expenses.where((expense) {
      // Filter by group
      if (_selectedGroupId != null && expense.groupId != _selectedGroupId) {
        return false;
      }
      
      // Filter by date range
      if (expense.date.isBefore(_selectedDateRange.start) ||
          expense.date.isAfter(_selectedDateRange.end)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredExpenses = _getFilteredExpenses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: filteredExpenses.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Фильтры',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          
                          // Group filter
                          DropdownButtonFormField<String?>(
                            value: _selectedGroupId,
                            decoration: const InputDecoration(
                              labelText: 'Группа',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Все группы'),
                              ),
                              ...groupProvider.groups.map((group) {
                                return DropdownMenuItem(
                                  value: group.id,
                                  child: Text(group.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGroupId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Date range
                          InkWell(
                            onTap: _selectDateRange,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('d MMM').format(_selectedDateRange.start)} - ${DateFormat('d MMM').format(_selectedDateRange.end)}',
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary cards
                  _buildSummaryCards(filteredExpenses),
                  const SizedBox(height: 24),

                  // Category breakdown
                  Text(
                    'Расходы по категориям',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ExpensePieChart(expenses: filteredExpenses),
                  ),
                  const SizedBox(height: 24),

                  // Expense trend
                  Text(
                    'Динамика расходов',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ExpenseLineChart(
                      expenses: filteredExpenses,
                      dateRange: _selectedDateRange,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Insights
                  Text(
                    'Полезные советы',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ExpenseInsights(
                    expenses: filteredExpenses,
                    userId: currentUser.id,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет данных для анализа',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте расходы, чтобы увидеть аналитику',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<ExpenseModel> expenses) {
    final currentUserId = context.read<AuthProvider>().currentUser!.id;
    
    double totalSpent = 0;
    double totalOwed = 0;
    double totalOwing = 0;
    
    for (var expense in expenses) {
      if (expense.paidBy == currentUserId) {
        totalSpent += expense.amount;
      }
      
      final userShare = expense.getUserShare(currentUserId);
      if (userShare > 0) {
        if (expense.paidBy != currentUserId) {
          totalOwing += userShare;
        }
      }
      
      expense.splitAmounts.forEach((userId, amount) {
        if (userId != currentUserId && expense.paidBy == currentUserId) {
          totalOwed += amount;
        }
      });
    }
    
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Всего потрачено',
            amount: totalSpent,
            color: Colors.blue,
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Вам должны',
            amount: totalOwed,
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Вы должны',
            amount: totalOwing,
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyUtils.formatAmountCompact(amount, 'RUB'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}