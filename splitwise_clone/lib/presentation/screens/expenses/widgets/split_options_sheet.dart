import 'package:flutter/material.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/providers/group_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:provider/provider.dart';

class SplitOptionsSheet extends StatefulWidget {
  final GroupModel group;
  final double totalAmount;
  final SplitType currentSplitType;
  final Map<String, double> currentSplitAmounts;
  final Function(SplitType, Map<String, double>) onSplitChanged;

  const SplitOptionsSheet({
    Key? key,
    required this.group,
    required this.totalAmount,
    required this.currentSplitType,
    required this.currentSplitAmounts,
    required this.onSplitChanged,
  }) : super(key: key);

  @override
  State<SplitOptionsSheet> createState() => _SplitOptionsSheetState();
}

class _SplitOptionsSheetState extends State<SplitOptionsSheet> {
  late SplitType _selectedType;
  late Map<String, double> _splitAmounts;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentSplitType;
    _splitAmounts = Map.from(widget.currentSplitAmounts);
    
    // Initialize with equal split if empty
    if (_splitAmounts.isEmpty) {
      _calculateEqualSplit();
    }
    
    // Create controllers for manual input
    for (var memberId in widget.group.members) {
      _controllers[memberId] = TextEditingController(
        text: _splitAmounts[memberId]?.toStringAsFixed(2) ?? '0.00',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateEqualSplit() {
    final perPerson = widget.totalAmount / widget.group.members.length;
    _splitAmounts = {};
    for (var memberId in widget.group.members) {
      _splitAmounts[memberId] = perPerson;
    }
  }

  void _updateSplit() {
    widget.onSplitChanged(_selectedType, _splitAmounts);
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Разделить ${CurrencyUtils.formatAmount(widget.totalAmount, 'RUB')}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: _updateSplit,
                      child: const Text('Готово'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Split type selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SplitTypeChip(
                      label: 'Поровну',
                      isSelected: _selectedType == SplitType.equal,
                      onTap: () {
                        setState(() {
                          _selectedType = SplitType.equal;
                          _calculateEqualSplit();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _SplitTypeChip(
                      label: 'Вручную',
                      isSelected: _selectedType == SplitType.manual,
                      onTap: () {
                        setState(() {
                          _selectedType = SplitType.manual;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Members list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = widget.group.members[index];
                    final member = groupProvider.groupMembers[memberId];
                    final amount = _splitAmounts[memberId] ?? 0.0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(
                                member?.name.substring(0, 1).toUpperCase() ?? '?',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member?.name ?? 'Загрузка...',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${(amount / widget.totalAmount * 100).toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedType == SplitType.manual)
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _controllers[memberId],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    prefixText: '₽',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    final newAmount = double.tryParse(value) ?? 0;
                                    setState(() {
                                      _splitAmounts[memberId] = newAmount;
                                    });
                                  },
                                ),
                              )
                            else
                              Text(
                                CurrencyUtils.formatAmount(amount, 'RUB'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Total validation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого:'),
                    Text(
                      CurrencyUtils.formatAmount(
                        _splitAmounts.values.fold(0.0, (sum, amount) => sum + amount),
                        'RUB',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _splitAmounts.values.fold(0.0, (sum, amount) => sum + amount) == widget.totalAmount
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SplitTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitTypeChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}