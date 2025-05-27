import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../widgets/common/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _notificationsEnabled = true;
  String _defaultCurrency = 'RUB';

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _notificationsEnabled = currentUser.settings?['notifications'] ?? true;
      _defaultCurrency = currentUser.settings?['defaultCurrency'] ?? 'RUB';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    // TODO: Implement save settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки сохранены'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile settings
          Text(
            'Профиль',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Имя',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // App settings
          Text(
            'Приложение',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Theme
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Светлая тема'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Темная тема'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Системная тема'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Currency
          DropdownButtonFormField<String>(
            value: _defaultCurrency,
            decoration: const InputDecoration(
              labelText: 'Валюта по умолчанию',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD - Доллар США')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR - Евро')),
              DropdownMenuItem(value: 'RUB', child: Text('RUB - Российский рубль')),
              DropdownMenuItem(value: 'KZT', child: Text('KZT - Казахстанский тенге')),
            ],
            onChanged: (value) {
              setState(() {
                _defaultCurrency = value!;
              });
            },
          ),
          const SizedBox(height: 24),

          // Notifications
          Text(
            'Уведомления',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Push-уведомления'),
            subtitle: const Text('Получать уведомления о новых расходах и долгах'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Privacy
          Text(
            'Конфиденциальность',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Изменить пароль'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showChangePasswordDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Удалить аккаунт'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          CustomButton(
            text: 'Сохранить изменения',
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить пароль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Текущий пароль',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Новый пароль',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Подтвердите новый пароль',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Пароль успешно изменен'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Это действие нельзя отменить. Все ваши данные будут удалены навсегда.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}