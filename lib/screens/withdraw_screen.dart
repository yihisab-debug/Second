import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/wallet_selector.dart';

class WithdrawScreen extends StatefulWidget {
  final List<Wallet> wallets;
  final Wallet initial;

  const WithdrawScreen({
    super.key,
    required this.wallets,
    required this.initial,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();

  late Wallet _wallet;
  String _target = 'Наличные в банкомате';
  bool _loading = false;

  static const List<String> _targets = [
    'Наличные в банкомате',
    'На карту другого банка',
    'В кассе отделения',
  ];

  @override
  void initState() {
    super.initState();
    _wallet = widget.initial;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      showMessage(context, 'Введите сумму', error: true);
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

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.withdraw, {
        'wallet_id': '${_wallet.id}',
        'amount': '$amount',
        'target': _target,
      });

      final balance = data['balance'];
      final newBalance =
          balance is num ? balance.toDouble() : double.tryParse('$balance') ?? 0;

      if (!mounted) return;
      popWithMessage(
        context,
        'Выведено ${formatMoney(amount, _wallet.currency)}. '
        'Остаток: ${formatMoney(newBalance, _wallet.currency)}',
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
        title: const Text('Вывод средств'),
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
                onChanged: (w) => setState(() => _wallet = w),
              ),

              const SizedBox(height: 12),

              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      'Доступно',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    ),

                    Text(
                      formatMoney(_wallet.balance, _wallet.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),

                  ],
                ),
              ),

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

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(
                    () => _amountController.text =
                        _wallet.balance.toStringAsFixed(2),
                  ),
                  child: const Text('Вывести всё'),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Куда выводим',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _target,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
                    items: _targets
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(s),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _target = v ?? _target),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Вывести',
                loading: _loading,
                onPressed: _submit,
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
