import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/wallet_selector.dart';

class DepositScreen extends StatefulWidget {
  final List<Wallet> wallets;
  final Wallet initial;

  const DepositScreen({
    super.key,
    required this.wallets,
    required this.initial,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();

  late Wallet _wallet;
  String _source = 'Банковская карта';
  bool _loading = false;

  static const List<String> _sources = [
    'Банковская карта',
    'Наличные через кассу',
    'Перевод из другого банка',
  ];

  static const List<double> _quick = [1000, 5000, 10000, 25000];

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
      showMessage(context, 'Введите сумму пополнения', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.deposit, {
        'wallet_id': '${_wallet.id}',
        'amount': '$amount',
        'source': _source,
      });

      final balance = data['balance'];
      final newBalance =
          balance is num ? balance.toDouble() : double.tryParse('$balance') ?? 0;

      if (!mounted) return;
      popWithMessage(
        context,
        'Счёт пополнен на ${formatMoney(amount, _wallet.currency)}. '
        'Баланс: ${formatMoney(newBalance, _wallet.currency)}',
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
        title: const Text('Пополнение'),
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
                label: 'Счёт зачисления',
                onChanged: (w) => setState(() => _wallet = w),
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

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quick
                    .map(
                      (value) => ActionChip(
                        label: Text(formatNumber(value, withCents: false)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onPressed: () => setState(
                          () => _amountController.text =
                              value.toStringAsFixed(0),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 22),

              const Text(
                'Источник пополнения',
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
                    value: _source,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
                    items: _sources
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
                    onChanged: (v) => setState(() => _source = v ?? _source),
                  ),
                  
                ),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Пополнить',
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
