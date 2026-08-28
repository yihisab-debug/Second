import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
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
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  late Wallet _wallet;
  bool _loading = false;
  bool _checking = false;
  String _recipient = '';

  @override
  void initState() {
    super.initState();
    _wallet = widget.initial;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String get _digits => _numberController.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _findRecipient() async {
    if (_digits.length != 16) {
      showMessage(context, 'Номер счёта состоит из 16 цифр', error: true);
      return;
    }

    setState(() {
      _checking = true;
      _recipient = '';
    });

    try {
      final data = await Api.call(Api.findWallet, {'number': _digits});
      if (!mounted) return;
      setState(() => _recipient = '${data['full_name'] ?? ''}');
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (_digits.length != 16) {
      showMessage(context, 'Введите 16 цифр номера счёта получателя', error: true);
      return;
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

    final confirmed = await showDialog<bool>(
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

            Text('Счёт получателя: ${formatCardNumber(_digits)}'),

            if (_recipient.isNotEmpty) ...[

              const SizedBox(height: 6),

              Text('Получатель: $_recipient'),

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

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.transfer, {
        'wallet_id': '${_wallet.id}',
        'to_number': _digits,
        'amount': '$amount',
        'comment': _commentController.text.trim(),
      });

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

              WalletSelector(
                wallets: widget.wallets,
                selected: _wallet,
                label: 'Счёт списания',
                onChanged: (w) => setState(() {
                  _wallet = w;
                  _recipient = '';
                }),
              ),

              const SizedBox(height: 20),

              const Text(
                'Счёт получателя',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [CardNumberInputFormatter()],
                onChanged: (_) {
                  if (_recipient.isNotEmpty) setState(() => _recipient = '');
                },
                decoration: InputDecoration(
                  hintText: '4400 0000 0000 0000',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: _checking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Проверить счёт',
                          icon: const Icon(Icons.search),
                          onPressed: _findRecipient,
                        ),
                ),
              ),

              if (_recipient.isNotEmpty) ...[

                const SizedBox(height: 10),

                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [

                      const Icon(Icons.check_circle,
                          color: AppColors.income, size: 20),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Получатель: $_recipient',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),

              const Text(
                'Сумма',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),

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

              const Text(
                'Перевод проходит между счетами в одной валюте. '
                'Номер своего счёта можно посмотреть в профиле.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
}
