import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/currency_utils.dart';

class DebtCard extends StatefulWidget {
  final String userId;
  final double amount;
  final VoidCallback? onTap;

  const DebtCard({
    Key? key,
    required this.userId,
    required this.amount,
    this.onTap,
  }) : super(key: key);

  @override
  State<DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<DebtCard> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userProvider = context.read<UserProvider>();
    // Здесь должна быть логика загрузки пользователя
    // Для простоты используем заглушку
  }

  @override
  Widget build(BuildContext context) {
    final isOwed = widget.amount > 0;
    final displayAmount = widget.amount.abs();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                child: Text(
                  _user?.name.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.name ?? 'Загрузка...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwed ? 'должен вам' : 'вы должны',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.formatAmount(displayAmount, 'RUB'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isOwed ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.onTap != null)
                    TextButton(
                      onPressed: widget.onTap,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Погасить'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}