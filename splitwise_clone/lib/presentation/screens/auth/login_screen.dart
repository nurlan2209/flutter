import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Logo
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Splitwise Clone',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Управляйте совместными расходами',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                // Email field
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Пароль',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showForgotPasswordDialog();
                    },
                    child: const Text('Забыли пароль?'),
                  ),
                ),
                const SizedBox(height: 24),
                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      text: 'Войти',
                      onPressed: authProvider.isLoading ? null : _login,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Divider with OR
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ИЛИ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Sign In button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return OutlinedButton.icon(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              try {
                                await authProvider.signInWithGoogle();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: Container(
                        height: 24,
                        width: 24,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.g_mobiledata,
                          size: 20,
                          color: Colors.blue,
                        ),
                      ),
                      label: const Text('Войти через Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Нет аккаунта? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Зарегистрироваться'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите email для отправки ссылки восстановления'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await context.read<AuthProvider>().resetPassword(email);
                  if (dialogContext.mounted) { // Используем dialogContext.mounted
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Ссылка для восстановления отправлена на email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) { // Используем dialogContext.mounted
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}