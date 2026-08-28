import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'main_shell.dart';
import 'pin_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      showMessage(context, 'Введите телефон и пароль', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.login, {
        'phone': phone,
        'password': password,
      });

      Session.token = '${data['token']}';
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final profile = Profile.fromJson(user);
        Session.fullName = profile.fullName;
        Session.phone = profile.phone;
        Session.hasPin = profile.hasPin;
      }
      await Session.save();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Session.hasPin
              ? const MainShell()
              : const PinScreen(mode: PinMode.setup),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 30,
                ),

              ),

              const SizedBox(height: 28),

              const Text(
                'С возвращением',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Войдите, чтобы управлять счетами',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 777 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Пароль',

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),

                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Войти',
                loading: _loading,
                onPressed: _login,
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),

            ],
          ),
          
        ),
      ),
    );
  }
}
