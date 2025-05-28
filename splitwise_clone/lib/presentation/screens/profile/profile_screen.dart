import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      currentUser.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.group,
                    label: 'Группы',
                    value: currentUser.groups.length.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Друзья',
                    value: currentUser.friends.length.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Друзья'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showFriendsDialog(context, currentUser);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    title: const Text('Тема'),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.system
                          ? 'Системная'
                          : themeProvider.isDarkMode
                              ? 'Темная'
                              : 'Светлая',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: const Text('Валюта по умолчанию'),
                    subtitle: const Text('RUB'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implement currency selection
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Уведомления'),
                    subtitle: const Text('Включены'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement notification settings
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support section
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Помощь'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implement help screen
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('О приложении'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            CustomButton(
              text: 'Выйти',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Выйти из аккаунта?'),
                    content: const Text('Вы уверены, что хотите выйти?'),
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
                        child: const Text('Выйти'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await authProvider.signOut();
                }
              },
              color: Colors.red,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendsDialog(BuildContext context, UserModel currentUser) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Друзья',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showAddFriendDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    if (currentUser.friends.isEmpty) {
                      return const Center(
                        child: Text('У вас пока нет друзей'),
                      );
                    }

                    return ListView.builder(
                      itemCount: currentUser.friends.length,
                      itemBuilder: (context, index) {
                        // В реальном приложении здесь нужно загрузить данные друзей
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text('Друг ${index + 1}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              // TODO: Remove friend
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить друга'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Email или имя',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  context.read<UserProvider>().searchUsers(value);
                }
              },
            ),
            const SizedBox(height: 16),
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (userProvider.isLoading) {
                  return const CircularProgressIndicator();
                }
                
                if (userProvider.searchResults.isEmpty) {
                  return const Text('Начните вводить для поиска');
                }
                
                return Column(
                  children: userProvider.searchResults.map((user) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name[0].toUpperCase()),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () async {
                          final currentUserId = context.read<AuthProvider>().currentUser!.id;
                          await userProvider.addFriend(currentUserId, user.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Друг добавлен'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Splitwise Clone',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet,
        size: 48,
      ),
      children: [
        const Text(
          'Приложение для управления совместными расходами.\n\n'
          'Разработано как дипломный проект.\n\n'
          'Технологии: Flutter, Firebase',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}