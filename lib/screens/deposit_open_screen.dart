import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/deposit_models.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/wallet_selector.dart';

class DepositOpenScreen extends StatefulWidget {
  final List<DepositProduct> products;
  final List<Wallet> wallets;
  final DepositProduct initial;

  const DepositOpenScreen({
    super.key,
    required this.products,
    required this.wallets,
    required this.initial,
  });

  @override
  State<DepositOpenScreen> createState() => _DepositOpenScreenState();
}

class _DepositOpenScreenState extends State<DepositOpenScreen> {
  final _amountController = TextEditingController();

  late DepositProduct _product;
  late Wallet _wallet;
  late double _months;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.initial;
    _wallet = widget.wallets.first;
    _months = _product.minMonths.toDouble();
    _amountController.text = _product.minAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectProduct(DepositProduct product) {
    setState(() {
      _product = product;
      _months = product.minMonths.toDouble();
      _amountController.text = product.minAmount.toStringAsFixed(0);
    });
  }

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  double get _income =>
      _amount <= 0 ? 0 : _product.income(_amount, _months.round());

  double get _total => _amount + _income;

  Future<void> _submit() async {
    final amount = _amount;

    if (amount < _product.minAmount || amount > _product.maxAmount) {
      showMessage(
        context,
        'Сумма должна быть от '
        '${formatMoney(_product.minAmount, _product.currency, withCents: false)}'
        ' до ${formatMoney(_product.maxAmount, _product.currency, withCents: false)}',
        error: true,
      );
      return;
    }

    if (_wallet.currency != _product.currency) {
      showMessage(
        context,
        'Выберите счёт в валюте ${_product.currency}',
        error: true,
      );
      return;
    }

    if (amount > _wallet.balance) {
      showMessage(context, 'Недостаточно средств на счёте', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await Api.call(Api.depositOpen, {
        'product_id': '${_product.id}',
        'wallet_id': '${_wallet.id}',
        'amount': '$amount',
        'months': '${_months.round()}',
      });

      final raw = data['total_amount'];
      final total = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;

      if (!mounted) return;
      popWithMessage(
        context,
        'Вклад открыт. К получению: '
        '${formatMoney(total, _product.currency)}',
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
    final divisions = _product.maxMonths - _product.minMonths;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Открытие вклада'),
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
                'Программа',
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
                    value: _product.id,
                    isExpanded: true,
                    itemHeight: 64,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(Icons.expand_more,
                        color: AppColors.textMuted),
                    items: widget.products
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p.id,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '${p.rate}% годовых',
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
                      _selectProduct(
                        widget.products.firstWhere((p) => p.id == id),
                      );
                    },
                  ),
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
                'Сумма вклада',
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
                  suffixText: currencySymbol(_product.currency),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'От ${formatMoney(_product.minAmount, _product.currency, withCents: false)}'
                ' до ${formatMoney(_product.maxAmount, _product.currency, withCents: false)}',
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
                min: _product.minMonths.toDouble(),
                max: _product.maxMonths.toDouble(),
                divisions: divisions > 0 ? divisions : null,
                label: '${_months.round()}',
                activeColor: AppColors.income,
                onChanged: (value) => setState(() => _months = value),
              ),

              const SizedBox(height: 12),

              AppCard(
                child: Column(
                  children: [

                    _calcRow('Ставка', '${_product.rate}% годовых'),

                    _calcRow(
                      'Доход за срок',
                      formatMoney(_income, _product.currency),
                      strong: true,
                    ),

                    _calcRow(
                      'К получению',
                      formatMoney(_total, _product.currency),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'При досрочном закрытии проценты не начисляются, '
                'возвращается только сумма вклада.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Открыть вклад',
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
              color: strong ? AppColors.income : AppColors.text,
            ),
          ),

        ],
      ),
    );
  }
}
