import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/utils/currency_utils.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';
import 'widgets/group_members_sheet.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    if (!mounted) return; // ДОБАВИТЬ проверку
    await context.read<GroupProvider>().selectGroup(widget.groupId);
    
    if (!mounted) return; // ДОБАВИТЬ проверку
    context.read<ExpenseProvider>().loadGroupExpenses(widget.groupId);
    
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null && mounted) { // ДОБАВИТЬ проверку
      context.read<ExpenseProvider>().loadSimplifiedDebts(
        userId,
        groupId: widget.groupId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final group = groupProvider.selectedGroup;

    if (group == null || groupProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              _showMembersSheet(context, group);
            },
          ),
          if (group.isAdmin(currentUser!.id))
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Редактировать'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить группу'),
                ),
              ],
              onSelected: (value) {
                // TODO: Implement edit and delete
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                preselectedGroupId: group.id,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroupData,
        child: CustomScrollView(
          slivers: [
            // Group info
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.description != null) ...[
                      Text(
                        group.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Balance card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ваш баланс в группе',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Consumer<ExpenseProvider>(
                              builder: (context, provider, _) {
                                double balance = 0;
                                provider.simplifiedDebts.forEach((userId, amount) {
                                  if (groupProvider.groupMembers.containsKey(userId)) {
                                    balance += amount;
                                  }
                                });
                                
                                return Text(
                                  CurrencyUtils.formatAmount(balance, 'RUB'),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: balance > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // TODO: Show detailed balances
                              },
                              child: const Text('Посмотреть детали'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      'Расходы',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            // Expenses list
            Consumer<ExpenseProvider>(
              builder: (context, provider, _) {
                final expenses = provider.expenses
                    .where((e) => e.groupId == group.id)
                    .toList();
                
                if (expenses.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Пока нет расходов',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddExpenseScreen(
                                    preselectedGroupId: group.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить первый расход'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenses[index];
                      return _ExpenseListItem(
                        expense: expense,
                        currentUserId: currentUser.id,
                      );
                    },
                    childCount: expenses.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroupMembersSheet(group: group),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;
  final String currentUserId;

  const _ExpenseListItem({
    super.key,
    required this.expense,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final userBalance = expense.getUserBalance(currentUserId);
    final groupProvider = context.read<GroupProvider>();
    final paidByUser = groupProvider.groupMembers[expense.paidBy];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      expense.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatAmount(expense.amount, expense.currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Оплатил: ${paidByUser?.name ?? 'Неизвестно'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMMM yyyy').format(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (userBalance != 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: userBalance > 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    userBalance > 0
                        ? 'Вам должны ${CurrencyUtils.formatAmount(userBalance, expense.currency)}'
                        : 'Вы должны ${CurrencyUtils.formatAmount(userBalance.abs(), expense.currency)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: userBalance > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}