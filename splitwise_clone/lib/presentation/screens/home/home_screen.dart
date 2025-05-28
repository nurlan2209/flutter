import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/providers/group_provider.dart';
import '../../../core/utils/currency_utils.dart';
import '../../widgets/debt_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../expenses/add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<ExpenseProvider>().loadSimplifiedDebts(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications screen
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (groupProvider.groups.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Сначала создайте или присоединитесь к группе'),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        label: const Text('Добавить расход'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привет, ${currentUser.name}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ваш общий баланс',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<ExpenseProvider>(
                          builder: (context, provider, _) {
                            double totalBalance = 0;
                            provider.simplifiedDebts.forEach((userId, amount) {
                              totalBalance += amount;
                            });
                            
                            return Text(
                              CurrencyUtils.formatAmount(totalBalance, 'RUB'),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: totalBalance > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Группы',
                        groupProvider.groups.length.toString(),
                        Icons.group,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Друзья',
                        currentUser.friends.length.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Simplified debts
                Text(
                  'Ваши долги',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                Consumer<ExpenseProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const LoadingListWidget(itemCount: 3);
                    }
                    
                    if (provider.simplifiedDebts.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'У вас нет долгов!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final debtsList = provider.simplifiedDebts.entries.toList();
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: debtsList.length,
                      itemBuilder: (context, index) {
                        final entry = debtsList[index];
                        return DebtCard(
                          userId: entry.key,
                          amount: entry.value,
                          onTap: () {
                            // TODO: Navigate to settle debt screen
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}