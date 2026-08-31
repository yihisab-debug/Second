import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/phone.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/wallet_selector.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class TransferScreen extends StatefulWidget {
  final List<Wallet> wallets;
  final Wallet initial;

  const TransferScreen({
    super.key,
    required this.wallets,
    required this.initial,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _phoneController = TextEditingController();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  late Wallet _wallet;

  bool _byPhone = true;
  bool _loading = false;
  bool _checking = false;

  Recipient? _recipient;
  String _lookupError = '';
  String _cardOwner = '';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _wallet = widget.initial;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phoneController.dispose();
    _numberController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String get _phone => normalizePhone(_phoneController.text);

  String get _cardDigits => _numberController.text.replaceAll(RegExp(r'\D'), '');

  void _resetRecipient() {
    if (_recipient != null || _lookupError.isNotEmpty || _cardOwner.isNotEmpty) {
      setState(() {
        _recipient = null;
        _lookupError = '';
        _cardOwner = '';
      });
    }
  }

  void _onPhoneChanged(String _) {
    _debounce?.cancel();
    _resetRecipient();

    if (_phone.length >= phoneMinLength) {
      _debounce = Timer(const Duration(milliseconds: 500), _findByPhone);
    }
  }

  Future<void> _findByPhone() async {
    if (_phone.length < phoneMinLength) {
      setState(() => _lookupError = 'Введите номер полностью');
      return;
    }

    setState(() {
      _checking = true;
      _recipient = null;
      _lookupError = '';
    });

    try {
      final data = await Api.call(Api.findUser, {'phone': _phone});
      if (!mounted) return;
      setState(() => _recipient = Recipient.fromJson(data));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _recipient = null;
        _lookupError = e.message;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    showMessage(context, 'Номер телефона скопирован');
  }

  Future<void> _findByCard() async {
    if (_cardDigits.length != 16) {
      showMessage(context, 'Номер счёта состоит из 16 цифр', error: true);
      return;
    }

    setState(() {
      _checking = true;
      _cardOwner = '';
      _lookupError = '';
    });

    try {
      final data = await Api.call(Api.findWallet, {'number': _cardDigits});
      if (!mounted) return;
      setState(() => _cardOwner = '${data['full_name'] ?? ''}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _lookupError = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (_byPhone) {
      if (_phone.length < phoneMinLength) {
        showMessage(context, 'Введите номер телефона получателя', error: true);
        return;
      }
      if (_recipient == null) {
        showMessage(
          context,
          _lookupError.isEmpty
              ? 'Сначала проверьте номер получателя'
              : _lookupError,
          error: true,
        );
        return;
      }
      if (!_recipient!.supports(_wallet.currency)) {
        showMessage(
          context,
          'У получателя нет счёта в валюте ${_wallet.currency}',
          error: true,
        );
        return;
      }
    } else {
      if (_cardDigits.length != 16) {
        showMessage(
          context,
          'Введите 16 цифр номера счёта получателя',
          error: true,
        );
        return;
      }
    }

    if (amount == null || amount <= 0) {
      showMessage(context, 'Введите сумму перевода', error: true);
      return;
    }
    if (amount > _wallet.balance) {
      showMessage(
        context,
        'На счёте только ${formatMoney(_wallet.balance, _wallet.currency)}',
        error: true,
      );
      return;
    }

    final confirmed = await _confirmDialog(amount);
    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final Map<String, dynamic> data;

      if (_byPhone) {
        data = await Api.call(Api.transferPhone, {
          'wallet_id': '${_wallet.id}',
          'to_phone': _phone,
          'amount': '$amount',
          'comment': _commentController.text.trim(),
        });
      } else {
        data = await Api.call(Api.transfer, {
          'wallet_id': '${_wallet.id}',
          'to_number': _cardDigits,
          'amount': '$amount',
          'comment': _commentController.text.trim(),
        });
      }

      final to = '${data['recipient'] ?? ''}';

      if (!mounted) return;
      popWithMessage(
        context,
        'Перевод ${formatMoney(amount, _wallet.currency)} '
        '${to.isEmpty ? 'выполнен' : 'отправлен: $to'}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _confirmDialog(double amount) {
    final target = _byPhone ? formatPhone(_phone) : formatCardNumber(_cardDigits);
    final name = _byPhone ? (_recipient?.fullName ?? '') : _cardOwner;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Подтвердите перевод'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text('Сумма: ${formatMoney(amount, _wallet.currency)}'),

            const SizedBox(height: 6),

            Text(_byPhone ? 'Телефон: $target' : 'Счёт получателя: $target'),

            if (name.isNotEmpty) ...[

              const SizedBox(height: 6),

              Text('Получатель: $name'),

            ],
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Перевести'),
          ),

        ],

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Перевод'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              _modeSwitch(),

              const SizedBox(height: 20),

              WalletSelector(
                wallets: widget.wallets,
                selected: _wallet,
                label: 'Счёт списания',
                onChanged: (w) => setState(() {
                  _wallet = w;
                }),
              ),

              const SizedBox(height: 20),

              _fieldLabel(_byPhone ? 'Телефон получателя' : 'Счёт получателя'),

              const SizedBox(height: 8),

              if (_byPhone) _phoneField() else _cardField(),

              _recipientBlock(),

              const SizedBox(height: 20),

              _fieldLabel('Сумма'),

              const SizedBox(height: 8),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: currencySymbol(_wallet.currency),
                  suffixStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _commentController,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                  counterText: '',
                ),
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Перевести',
                loading: _loading,
                onPressed: _submit,
              ),

              const SizedBox(height: 12),

              Text(
                _byPhone
                    ? 'Деньги придут на счёт получателя в валюте ${_wallet.currency}. '
                        'Получателю сразу придёт уведомление о пополнении.'
                    : 'Перевод проходит между счетами в одной валюте. '
                        'Номер своего счёта можно посмотреть в профиле.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),

      child: Row(
        children: [

          _modeTab('По телефону', Icons.phone_iphone_rounded, true),

          _modeTab('По номеру счёта', Icons.credit_card, false),

        ],
      ),
    );
  }

  Widget _modeTab(String label, IconData icon, bool phoneMode) {
    final active = _byPhone == phoneMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_byPhone == phoneMode) return;
          _debounce?.cancel();
          setState(() {
            _byPhone = phoneMode;
            _recipient = null;
            _lookupError = '';
            _cardOwner = '';
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(
                icon,
                size: 17,
                color: active ? Colors.white : AppColors.textMuted,
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _suffix(VoidCallback onSearch) {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      tooltip: 'Проверить получателя',
      icon: const Icon(Icons.search),
      onPressed: onSearch,
    );
  }

  Widget _phoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [PhoneInputFormatter()],
      onChanged: _onPhoneChanged,
      decoration: InputDecoration(
        hintText: '707 123-45-67',
        prefixIcon: const Icon(Icons.phone_iphone_rounded),
        suffixIcon: _suffix(_findByPhone),
      ),
    );
  }

  Widget _cardField() {
    return TextField(
      controller: _numberController,
      keyboardType: TextInputType.number,
      inputFormatters: [CardNumberInputFormatter()],
      onChanged: (_) => _resetRecipient(),
      decoration: InputDecoration(
        hintText: '4400 0000 0000 0000',
        prefixIcon: const Icon(Icons.credit_card),
        suffixIcon: _suffix(_findByCard),
      ),
    );
  }

  Widget _recipientBlock() {
    if (_lookupError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [

              const Icon(Icons.error_outline,
                  color: AppColors.expense, size: 20),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _lookupError,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.expense,
                  ),
                ),
              ),

            ],
          ),
        ),
      );
    }

    final name = _byPhone ? (_recipient?.fullName ?? '') : _cardOwner;
    if (name.isEmpty) return const SizedBox.shrink();

    final wrongCurrency =
        _byPhone && _recipient != null && !_recipient!.supports(_wallet.currency);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [

            Icon(
              wrongCurrency ? Icons.warning_amber_rounded : Icons.check_circle,
              color: wrongCurrency ? AppColors.accent : AppColors.income,
              size: 20,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Получатель: $name',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),

                  if (_byPhone && _recipient != null) ...[

                    const SizedBox(height: 2),

                    Text(
                      wrongCurrency
                          ? 'Нет счёта в валюте ${_wallet.currency}'
                          : _recipient!.phonePretty,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: wrongCurrency
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                    ),

                  ],
                ],
              ),
            ),

            if (_byPhone && _recipient != null)
              IconButton(
                tooltip: 'Скопировать номер телефона',
                onPressed: () => _copyPhone(_recipient!.phonePretty),
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),

          ],
        ),
      ),
    );
  }
}
