import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';
import 'main_shell.dart';

enum PinMode {
  setup,

  unlock,

  change,
}

class PinScreen extends StatefulWidget {
  final PinMode mode;

  const PinScreen({super.key, required this.mode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const int _pinLength = 4;

  late String _step;

  String _input = '';
  String _newPin = '';
  String _currentPin = '';
  String _error = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    switch (widget.mode) {
      case PinMode.unlock:
        _step = 'unlock';
        break;
      case PinMode.change:
        _step = 'current';
        break;
      case PinMode.setup:
        _step = 'enter';
        break;
    }
  }

  String get _title {
    switch (_step) {
      case 'unlock':
        return 'Введите PIN-код';
      case 'current':
        return 'Текущий PIN-код';
      case 'confirm':
        return 'Повторите PIN-код';
      default:
        return 'Придумайте PIN-код';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 'unlock':
        return 'Здравствуйте, ${Session.firstName}';
      case 'current':
        return 'Подтвердите, что это вы';
      case 'confirm':
        return 'Ещё раз, чтобы не ошибиться';
      default:
        return '4 цифры для быстрого входа в приложение';
    }
  }

  void _press(String digit) {
    if (_loading || _input.length >= _pinLength) return;
    setState(() {
      _input += digit;
      _error = '';
    });
    if (_input.length == _pinLength) {
      _submit();
    }
  }

  void _backspace() {
    if (_loading || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final entered = _input;

    try {
      if (_step == 'unlock') {
        await Api.call(Api.checkPin, {'pin': entered});
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
        return;
      }

      if (_step == 'current') {
        await Api.call(Api.checkPin, {'pin': entered});
        if (!mounted) return;
        setState(() {
          _currentPin = entered;
          _step = 'enter';
          _input = '';
        });
        return;
      }

      if (_step == 'enter') {
        setState(() {
          _newPin = entered;
          _step = 'confirm';
          _input = '';
        });
        return;
      }

      if (entered != _newPin) {
        setState(() {
          _step = 'enter';
          _input = '';
          _newPin = '';
          _error = 'PIN-коды не совпали. Попробуйте ещё раз';
        });
        return;
      }

      final body = <String, String>{'pin': entered};
      if (widget.mode == PinMode.change) {
        body['current_pin'] = _currentPin;
      }
      await Api.call(Api.setPin, body);

      Session.hasPin = true;
      await Session.save();

      if (!mounted) return;

      if (widget.mode == PinMode.change) {
        popWithMessage(context, 'PIN-код изменён');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _input = '';
        _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final filled = index < _input.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: filled ? 18 : 14,
          height: filled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }

  Widget _key(String label, {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: label.isEmpty && icon == null
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),

          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,

            child: SizedBox(
              height: 62,
              child: Center(
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 24)
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

          ),

        ),
      ),
    );
  }

  Widget _keypadRow(List<String> digits) {
    return Row(
      children: digits.map((d) => _key(d, onTap: () => _press(d))).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = widget.mode == PinMode.change;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(

        child: Column(
          children: [

            if (canGoBack)

              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              )

            else
              const SizedBox(height: 20),

            const Spacer(),

            Icon(
              _step == 'unlock' ? Icons.lock_outline : Icons.pin_outlined,
              color: Colors.white.withValues(alpha: 0.9),
              size: 40,
            ),

            const SizedBox(height: 18),

            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            _dots(),

            const SizedBox(height: 14),

            SizedBox(
              height: 22,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFD1D1),
                        fontSize: 13,
                      ),
                    ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(

                children: [
                  _keypadRow(['1', '2', '3']),
                  _keypadRow(['4', '5', '6']),
                  _keypadRow(['7', '8', '9']),

                  Row(
                    children: [
                      _key(''),
                      _key('0', onTap: () => _press('0')),
                      _key('', icon: Icons.backspace_outlined, onTap: _backspace),
                    ],
                  ),

                ],
              ),
            ),

            if (widget.mode == PinMode.unlock)

              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Войти в другой аккаунт',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              )

            else
              const SizedBox(height: 12),
            const SizedBox(height: 8),
            
          ],
        ),
      ),
    );
  }
}
