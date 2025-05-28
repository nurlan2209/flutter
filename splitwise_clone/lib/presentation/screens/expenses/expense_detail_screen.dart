import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/utils/currency_utils.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final paidByUser = groupProvider.groupMembers[expense.paidBy];
    final category = expense.category != null
        ? CategoryModel.defaultCategories.firstWhere(
            (c) => c.id == expense.category,
            orElse: () => CategoryModel.defaultCategories.last,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали расхода'),
        actions: [
          if (expense.createdBy == currentUser?.id ||
              expense.paidBy == currentUser?.id)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Редактировать'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить'),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить расход?'),
                      content: const Text(
                        'Это действие нельзя отменить. Все связанные долги будут удалены.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      await context.read<ExpenseProvider>().deleteExpense(expense.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Расход удален'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyUtils.formatAmount(expense.amount, expense.currency),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.icon),
                          const SizedBox(width: 4),
                          Text(category.name),
                        ],
                      ),
                      backgroundColor: Color(
                        int.parse(category.color.replaceAll('#', '0xFF')),
                      ).withValues(alpha: 0.2),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards
                  _InfoCard(
                    icon: Icons.person,
                    title: 'Оплатил',
                    value: paidByUser?.name ?? 'Неизвестно',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.calendar_today,
                    title: 'Дата',
                    value: DateFormat('d MMMM yyyy, HH:mm').format(expense.date),
                  ),
                  if (expense.description != null) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.note,
                      title: 'Описание',
                      value: expense.description!,
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text(
                    'Распределение',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Split details
                  ...expense.splitAmounts.entries.map((entry) {
                    final user = groupProvider.groupMembers[entry.key];
                    final amount = entry.value;
                    final percentage = (amount / expense.amount * 100).toStringAsFixed(1);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? '?',
                          ),
                        ),
                        title: Text(user?.name ?? 'Загрузка...'),
                        subtitle: Text('$percentage% от суммы'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatAmount(amount, expense.currency),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (entry.key == expense.paidBy)
                              const Text( // Добавлено const
                                'Оплатил',
                                style: TextStyle( // TextStyle уже помечен как const
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              )
                            else if (amount > 0)
                              const Text( // Добавлено const
                                'Должен',
                                style: TextStyle( // TextStyle уже помечен как const
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  // Your balance
                  if (currentUser != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ваш баланс',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          () {
                            final balance = expense.getUserBalance(currentUser.id);
                            if (balance == 0) {
                              return const Text(
                                'Вы ничего не должны',
                                style: TextStyle(color: Colors.green),
                              );
                            } else if (balance > 0) {
                              return Text(
                                'Вам должны ${CurrencyUtils.formatAmount(balance, expense.currency)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            } else {
                              return Text(
                                'Вы должны ${CurrencyUtils.formatAmount(balance.abs(), expense.currency)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                          }(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}