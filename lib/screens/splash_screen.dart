import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _error = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _error = '');

    await Session.load();

    if (Session.token == null) {
      _replaceWith(const LoginScreen());
      return;
    }

    try {
      final data = await Api.call(Api.overview);
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final profile = Profile.fromJson(user);
        Session.fullName = profile.fullName;
        Session.phone = profile.phone;
        Session.hasPin = profile.hasPin;
        await Session.save();
      }

      _replaceWith(
        Session.hasPin
            ? const PinScreen(mode: PinMode.unlock)
            : const PinScreen(mode: PinMode.setup),
      );
    } on ApiException catch (e) {
      if (e.status == 401) {
        await Session.clear();
        _replaceWith(const LoginScreen());
        return;
      }
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  void _replaceWith(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(26),
                ),

                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 40,
                ),

              ),

              const SizedBox(height: 20),

              const Text(
                'MiniBank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 28),

              if (_error.isEmpty)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: _boot,
                  child: const Text('Повторить'),
                ),
              ],
              
            ],
          ),
        ),
      ),
    );
  }
}
