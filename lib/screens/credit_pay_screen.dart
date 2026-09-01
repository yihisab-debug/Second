import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/credit_models.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/wallet_selector.dart';

class CreditPayScreen extends StatefulWidget {
  final Credit credit;
  final List<Wallet> wallets;

  const CreditPayScreen({
    super.key,
    required this.credit,
    required this.wallets,
  });

  @override
  State<CreditPayScreen> createState() => _CreditPayScreenState();
}

class _CreditPayScreenState extends State<CreditPayScreen> {
  final _amountController = TextEditingController();

  late Wallet _wallet;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    final same = widget.wallets
        .where((w) => w.currency == widget.credit.currency)
        .toList();
    _wallet = same.isEmpty ? widget.wallets.first : same.first;

    final payment = widget.credit.monthlyPayment > widget.credit.remaining
        ? widget.credit.remaining
        : widget.credit.monthlyPayment;
    _amountController.text = payment.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

    if (amount <= 0) {
      showMessage(context, 'Введите сумму платежа', error: true);
      return;
    }

    if (amount > _wallet.balance) {
      showMessage(context, 'Недостаточно средств на счёте', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.creditPay, {
        'credit_id': '${widget.credit.id}',
        'wallet_id': '${_wallet.id}',
        'amount': '$amount',
      });

      final closed = data['closed'] == true;
      final rest = data['remaining'];
      final remaining =
          rest is num ? rest.toDouble() : double.tryParse('$rest') ?? 0;

      if (!mounted) return;
      popWithMessage(
        context,
        closed
            ? 'Кредит полностью погашен'
            : 'Платёж принят. Остаток: '
                '${formatMoney(remaining, widget.credit.currency)}',
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
    final credit = widget.credit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Погашение кредита'),
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

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      credit.creditorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _row('Остаток долга',
                        formatMoney(credit.remaining, credit.currency)),
                    _row('Ежемесячный платёж',
                        formatMoney(credit.monthlyPayment, credit.currency)),
                    _row('Срок', '${credit.months} мес.'),

                  ],
                ),
              ),

              const SizedBox(height: 20),

              WalletSelector(
                wallets: widget.wallets,
                selected: _wallet,
                label: 'Счёт списания',
                onChanged: (w) => setState(() => _wallet = w),
              ),

              const SizedBox(height: 20),

              const Text(
                'Сумма платежа',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: currencySymbol(credit.currency),
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: [

                  ActionChip(
                    label: const Text('Платёж за месяц'),
                    onPressed: () => setState(
                      () => _amountController.text =
                          credit.monthlyPayment.toStringAsFixed(2),
                    ),
                  ),

                  ActionChip(
                    label: const Text('Погасить полностью'),
                    onPressed: () => setState(
                      () => _amountController.text =
                          credit.remaining.toStringAsFixed(2),
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Оплатить',
                loading: _loading,
                onPressed: _submit,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),

        ],
      ),
    );
  }
}
