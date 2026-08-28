import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'pin_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();

  bool _loading = false;
  bool _agree = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final repeat = _repeatController.text;

    if (name.isEmpty) {
      showMessage(context, 'Введите имя и фамилию', error: true);
      return;
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      showMessage(context, 'Введите номер телефона полностью', error: true);
      return;
    }
    if (password.length < 4) {
      showMessage(context, 'Пароль должен быть не короче 4 символов', error: true);
      return;
    }
    if (password != repeat) {
      showMessage(context, 'Пароли не совпадают', error: true);
      return;
    }
    if (!_agree) {
      showMessage(context, 'Примите условия обслуживания', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.register, {
        'full_name': name,
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
        MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.setup)),
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
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const Text(
                'Создайте аккаунт',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Счёт в тенге откроется автоматически',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя и фамилия',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 14),

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
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _repeatController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Повторите пароль',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _agree = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Согласен с условиями обслуживания',
                      style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Зарегистрироваться',
                loading: _loading,
                onPressed: _register,
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Уже есть аккаунт? Войти'),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
