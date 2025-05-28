import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/category_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import 'widgets/split_options_sheet.dart';
import '../../../core/utils/date_utils.dart' as AppDateUtils;

class AddExpenseScreen extends StatefulWidget {
  final String? preselectedGroupId;

  const AddExpenseScreen({
    Key? key,
    this.preselectedGroupId,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedGroupId;
  String? _selectedPaidBy;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  SplitType _splitType = SplitType.equal;
  Map<String, double> _splitAmounts = {};

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.preselectedGroupId;
    _selectedPaidBy = context.read<AuthProvider>().currentUser?.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  void _showSplitOptions() {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите группу')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала введите сумму')),
      );
      return;
    }

    final group = context.read<GroupProvider>().groups
        .firstWhere((g) => g.id == _selectedGroupId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SplitOptionsSheet(
        group: group,
        totalAmount: amount,
        currentSplitType: _splitType,
        currentSplitAmounts: _splitAmounts,
        onSplitChanged: (type, amounts) {
          setState(() {
            _splitType = type;
            _splitAmounts = amounts;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGroupId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите группу')),
        );
        return;
      }

      if (_splitAmounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройте распределение расходов')),
        );
        return;
      }

      try {
        final currentUser = context.read<AuthProvider>().currentUser!;
        final expenseId = const Uuid().v4();
        
        final expense = ExpenseModel(
          id: expenseId,
          groupId: _selectedGroupId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amount: double.parse(_amountController.text),
          currency: 'RUB',
          paidBy: _selectedPaidBy!,
          splitAmounts: _splitAmounts,
          splitType: _splitType,
          category: _selectedCategory?.id,
          date: _selectedDate,
          createdAt: DateTime.now(),
          createdBy: currentUser.id,
        );

        await context.read<ExpenseProvider>().createExpense(expense);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Расход успешно добавлен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить расход'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group selection
            DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: InputDecoration(
                labelText: 'Группа',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: groupProvider.groups.map((group) {
                return DropdownMenuItem(
                  value: group.id,
                  child: Text(group.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                  // Reset split when group changes
                  _splitAmounts = {};
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Выберите группу';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Title
            CustomTextField(
              controller: _titleController,
              labelText: 'Название расхода',
              prefixIcon: Icons.receipt,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount
            CustomTextField(
              controller: _amountController,
              labelText: 'Сумма',
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите сумму';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Введите корректную сумму';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              'Категория',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryModel.defaultCategories.map((category) {
                final isSelected = _selectedCategory?.id == category.id;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon),
                      const SizedBox(width: 4),
                      Text(category.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  backgroundColor: isSelected
                      ? Color(int.parse(category.color.replaceAll('#', '0xFF')))
                          .withOpacity(0.2)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              title: const Text('Дата'),
              Text(AppDateUtils.formatDate(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),

            // Paid by
            if (_selectedGroupId != null) ...[
              DropdownButtonFormField<String>(
                value: _selectedPaidBy,
                decoration: InputDecoration(
                  labelText: 'Кто заплатил',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: () {
                  final group = groupProvider.groups
                      .firstWhere((g) => g.id == _selectedGroupId);
                  return group.members.map((memberId) {
                    final member = groupProvider.groupMembers[memberId];
                    return DropdownMenuItem(
                      value: memberId,
                      child: Text(member?.name ?? 'Загрузка...'),
                    );
                  }).toList();
                }(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaidBy = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Split options
            ListTile(
              title: const Text('Разделить'),
              subtitle: Text(_getSplitDescription()),
              leading: const Icon(Icons.pie_chart),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showSplitOptions,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Описание (необязательно)',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 32),


            // Create button
            Consumer<ExpenseProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: 'Добавить расход',
                  onPressed: provider.isLoading ? null : _createExpense,
                  isLoading: provider.isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getSplitDescription() {
    if (_splitAmounts.isEmpty) {
      return 'Не настроено';
    }

    switch (_splitType) {
      case SplitType.equal:
        return 'Поровну между ${_splitAmounts.length} участниками';
      case SplitType.manual:
        return 'Вручную';
      case SplitType.percentage:
        return 'По процентам';
      case SplitType.shares:
        return 'По долям';
    }
  }
}