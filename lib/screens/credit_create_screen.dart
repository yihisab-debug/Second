import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/credit_models.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/wallet_selector.dart';

class CreditCreateScreen extends StatefulWidget {
  final List<Creditor> creditors;
  final List<Wallet> wallets;
  final Creditor initial;

  const CreditCreateScreen({
    super.key,
    required this.creditors,
    required this.wallets,
    required this.initial,
  });

  @override
  State<CreditCreateScreen> createState() => _CreditCreateScreenState();
}

class _CreditCreateScreenState extends State<CreditCreateScreen> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();

  late Creditor _creditor;
  late Wallet _wallet;
  late double _months;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _creditor = widget.initial;
    _wallet = widget.wallets.first;
    _months = _creditor.minMonths.toDouble();
    _amountController.text = _creditor.minAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _selectCreditor(Creditor creditor) {
    setState(() {
      _creditor = creditor;
      _months = creditor.minMonths.toDouble();
      _amountController.text = creditor.minAmount.toStringAsFixed(0);
    });
  }

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  double get _monthly => _amount <= 0
      ? 0
      : _creditor.monthlyPayment(_amount, _months.round());

  double get _total => _monthly * _months.round();

  Future<void> _submit() async {
    final amount = _amount;

    if (amount < _creditor.minAmount || amount > _creditor.maxAmount) {
      showMessage(
        context,
        'Сумма должна быть от '
        '${formatMoney(_creditor.minAmount, _creditor.currency, withCents: false)}'
        ' до ${formatMoney(_creditor.maxAmount, _creditor.currency, withCents: false)}',
        error: true,
      );
      return;
    }

    if (_wallet.currency != _creditor.currency) {
      showMessage(
        context,
        'Выберите счёт в валюте ${_creditor.currency}',
        error: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.creditCreate, {
        'creditor_id': '${_creditor.id}',
        'wallet_id': '${_wallet.id}',
        'amount': '$amount',
        'months': '${_months.round()}',
        'purpose': _purposeController.text.trim(),
      });

      final payment = data['monthly_payment'];
      final monthly = payment is num
          ? payment.toDouble()
          : double.tryParse('$payment') ?? 0;

      if (!mounted) return;
      popWithMessage(
        context,
        'Кредит оформлен. Платёж: '
        '${formatMoney(monthly, _creditor.currency)} в месяц',
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
    final divisions = _creditor.maxMonths - _creditor.minMonths;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление кредита'),
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

              const Text(
                'Кредитор',
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
                  child: DropdownButton<int>(
                    value: _creditor.id,
                    isExpanded: true,
                    itemHeight: 64,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(Icons.expand_more,
                        color: AppColors.textMuted),
                    items: widget.creditors
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '${c.rate}% годовых',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      _selectCreditor(
                        widget.creditors.firstWhere((c) => c.id == id),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              WalletSelector(
                wallets: widget.wallets,
                selected: _wallet,
                label: 'Счёт зачисления',
                onChanged: (w) => setState(() => _wallet = w),
              ),

              const SizedBox(height: 20),

              const Text(
                'Сумма кредита',
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
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: currencySymbol(_creditor.currency),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'От ${formatMoney(_creditor.minAmount, _creditor.currency, withCents: false)}'
                ' до ${formatMoney(_creditor.maxAmount, _creditor.currency, withCents: false)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    'Срок',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),

                  Text(
                    '${_months.round()} мес.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),

                ],
              ),

              Slider(
                value: _months,
                min: _creditor.minMonths.toDouble(),
                max: _creditor.maxMonths.toDouble(),
                divisions: divisions > 0 ? divisions : null,
                label: '${_months.round()}',
                activeColor: AppColors.primary,
                onChanged: (value) => setState(() => _months = value),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _purposeController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Цель кредита (необязательно)',
                  counterText: '',
                ),
              ),

              const SizedBox(height: 20),

              AppCard(
                child: Column(
                  children: [

                    _calcRow(
                      'Ставка',
                      '${_creditor.rate}% годовых',
                    ),

                    _calcRow(
                      'Ежемесячный платёж',
                      formatMoney(_monthly, _creditor.currency),
                      strong: true,
                    ),

                    _calcRow(
                      'Всего к возврату',
                      formatMoney(_total, _creditor.currency),
                    ),

                    _calcRow(
                      'Переплата',
                      formatMoney(
                        _total - _amount < 0 ? 0 : _total - _amount,
                        _creditor.currency,
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Получить кредит',
                loading: _loading,
                onPressed: _submit,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 15 : 13.5,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong ? AppColors.primary : AppColors.text,
            ),
          ),

        ],
      ),
    );
  }
}
