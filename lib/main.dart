import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Api {
  static const String baseUrl = 'http://api.com/api/user';

  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
}

class Session {
  static String? token;
  static String? name;
  static String? login;

  static void clear() {
    token = null;
    name = null;
    login = null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Авторизация',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _resultMessage = '';

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      setState(() {
        _resultMessage = 'Заполните логин и пароль';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(Api.login),
        body: {
          'login': login,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['status'] == 200) {
        Session.token = data['token'] ?? data['data']?['token'];
        Session.name = data['name'] ?? data['data']?['name'] ?? login;
        Session.login = login;

        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          if (data['status'] == 401) {
            _resultMessage = 'Неверный логин или пароль';
          } else if (data['status'] == 404) {
            _resultMessage = 'Пользователь не найден';
          } else {
            _resultMessage = 'Ошибка: ${data['message'] ?? 'неизвестная ошибка'}';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resultMessage = 'Ошибка соединения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Логин'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Войти'),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text('Нет аккаунта? Зарегистрироваться'),
            ),

            const SizedBox(height: 16),

            if (_resultMessage.isNotEmpty)
              Text(
                _resultMessage,
                style: const TextStyle(color: Colors.red),
              ),

          ],
        ),

      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String _resultMessage = '';

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      setState(() {
        _resultMessage = 'Заполните логин и пароль';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(Api.register),
        body: {
          'login': login,
          'password': password,
          'name': name,
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (data['status'] == 200) {
          _resultMessage = 'Регистрация успешна!';
        } else if (data['status'] == 409) {
          _resultMessage = 'Такой пользователь уже существует';
        } else {
          _resultMessage = 'Ошибка: ${data['message'] ?? 'неизвестная ошибка'}';
        }
      });

      if (data['status'] == 200) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resultMessage = 'Ошибка соединения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Логин'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Зарегистрироваться'),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Уже есть аккаунт? Войти'),
            ),

            const SizedBox(height: 16),

            if (_resultMessage.isNotEmpty)
              Text(
                _resultMessage,
                style: TextStyle(
                  color: _resultMessage.contains('успешна')
                      ? Colors.green
                      : Colors.red,
                ),
              ),

          ],
        ),

      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              Session.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          
          child: Text(
            'Welcome, ${Session.name ?? Session.login ?? "гость"}!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

        ),
      ),

    );
  }
}
