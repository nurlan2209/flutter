import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final List<String> _selectedMembers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Add current user to members
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (currentUserId != null) {
      _selectedMembers.add(currentUserId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Добавьте хотя бы одного участника'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        final groupProvider = context.read<GroupProvider>();
        final currentUserId = context.read<AuthProvider>().currentUser!.id;
        
        await groupProvider.createGroup(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdBy: currentUserId,
          members: _selectedMembers,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Группа успешно создана'),
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

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    context.read<UserProvider>().searchUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать группу'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group name
            CustomTextField(
              controller: _nameController,
              labelText: 'Название группы',
              prefixIcon: Icons.group,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название группы';
                }
                if (value.length < 3) {
                  return 'Название должно быть не менее 3 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Описание (необязательно)',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Members section
            Text(
              'Участники',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Search members
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по email или имени',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                          context.read<UserProvider>().clearSearchResults();
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            
            // Search results
            if (_isSearching) ...[
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  if (userProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (userProvider.searchResults.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Пользователи не найдены'),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userProvider.searchResults.length,
                    itemBuilder: (context, index) {
                      final user = userProvider.searchResults[index];
                      final isSelected = _selectedMembers.contains(user.id);
                      final isCurrentUser = user.id == currentUser?.id;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user.name[0].toUpperCase()),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: isCurrentUser
                            ? const Chip(label: Text('Вы'))
                            : Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMembers.add(user.id);
                                    } else {
                                      _selectedMembers.remove(user.id);
                                    }
                                  });
                                },
                              ),
                        onTap: isCurrentUser
                            ? null
                            : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedMembers.remove(user.id);
                                  } else {
                                    _selectedMembers.add(user.id);
                                  }
                                });
                              },
                      );
                    },
                  );
                },
              ),
            ],
            
            // Selected members
            if (_selectedMembers.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                'Выбрано участников: ${_selectedMembers.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Create button
            Consumer<GroupProvider>(
              builder: (context, groupProvider, _) {
                return CustomButton(
                  text: 'Создать группу',
                  onPressed: groupProvider.isLoading ? null : _createGroup,
                  isLoading: groupProvider.isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}