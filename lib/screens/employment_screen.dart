import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/employment_models.dart';
import '../widgets/app_widgets.dart';

class EmploymentScreen extends StatefulWidget {
  const EmploymentScreen({super.key});

  @override
  State<EmploymentScreen> createState() => _EmploymentScreenState();
}

class _EmploymentScreenState extends State<EmploymentScreen> {
  final _employerController = TextEditingController();
  final _incomeController = TextEditingController();
  final _experienceController = TextEditingController();

  List<EmploymentOption> _options = <EmploymentOption>[];
  CreditDecision _decision = CreditDecision.empty();
  String _status = '';
  double _limit = 0;

  bool _loading = true;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _employerController.dispose();
    _incomeController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  EmploymentOption? get _option {
    for (final option in _options) {
      if (option.code == _status) return option;
    }
    return null;
  }

  Future<void> _load() async {
    try {
      final data = await Api.call(Api.employment);
      final employment = Employment.from(data['employment']);

      if (!mounted) return;
      setState(() {
        _options = EmploymentOption.listFrom(data['statuses']);
        _decision = CreditDecision.from(data['decision']);
        _status = employment.status;
        _limit = data['credit_limit'] is num
            ? (data['credit_limit'] as num).toDouble()
            : 0.0;
        _employerController.text = employment.employer;
        _incomeController.text = employment.monthlyIncome <= 0
            ? ''
            : employment.monthlyIncome.toStringAsFixed(0);
        _experienceController.text = employment.experienceMonths <= 0
            ? ''
            : '${employment.experienceMonths}';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _save() async {
    final option = _option;

    if (option == null) {
      showMessage(context, 'Выберите статус занятости', error: true);
      return;
    }

    if (option.needEmployer && _employerController.text.trim().isEmpty) {
      showMessage(context, 'Укажите место работы', error: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final data = await Api.call(Api.employmentSave, {
        'employment_status': option.code,
        'employer': _employerController.text.trim(),
        'monthly_income': _incomeController.text.trim().isEmpty
            ? '0'
            : _incomeController.text.trim(),
        'experience_months': _experienceController.text.trim().isEmpty
            ? '0'
            : _experienceController.text.trim(),
      });

      if (!mounted) return;
      setState(() {
        _decision = CreditDecision.from(data['decision']);
        _limit = data['credit_limit'] is num
            ? (data['credit_limit'] as num).toDouble()
            : 0.0;
      });

      showMessage(
        context,
        _decision.allowed
            ? 'Статус сохранён. Кредиты доступны'
            : 'Статус сохранён. ${_decision.message}',
        error: !_decision.allowed,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = _option;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статус занятости'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [

                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: AppColors.expense),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error,
                                style: const TextStyle(fontSize: 13, height: 1.35),
                              ),
                            ),
                            TextButton(onPressed: _load, child: const Text('Ещё раз')),
                          ],
                        ),
                      ),
                    ),

                  _decisionCard(),

                  const SizedBox(height: 20),

                  const Text(
                    'Кем вы работаете',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ..._options.map(_optionCard),

                  if (option != null && option.canCredit) ...[

                    const SizedBox(height: 12),

                    if (option.needEmployer) ...[

                      TextField(
                        controller: _employerController,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          labelText: 'Место работы',
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 14),

                    ],

                    TextField(
                      controller: _incomeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Доход в месяц',
                        suffixText: '₸',
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Минимум для этого статуса — '
                      '${formatMoney(option.minIncome, 'KZT', withCents: false)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Стаж в месяцах',
                        suffixText: 'мес.',
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      option.minMonths == 0
                          ? 'Стаж для этого статуса не обязателен'
                          : 'Минимальный стаж — ${option.minMonths} мес.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    AppCard(
                      child: Column(
                        children: [

                          _infoRow(
                            'Максимальная сумма',
                            formatMoney(option.maxAmount, 'KZT', withCents: false),
                          ),

                          _infoRow(
                            'Платёж не больше',
                            '${(option.paymentPart * 100).round()}% от дохода',
                          ),

                          _infoRow(
                            'Доступно сейчас',
                            formatMoney(_limit, 'KZT', withCents: false),
                            strong: true,
                          ),

                        ],
                      ),
                    ),

                  ],

                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Сохранить статус',
                    loading: _saving,
                    onPressed: _save,
                  ),

                ],
              ),
      ),
    );
  }

  Widget _decisionCard() {
    final allowed = _decision.allowed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (allowed ? AppColors.income : AppColors.expense)
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(
            allowed ? Icons.verified_rounded : Icons.error_outline_rounded,
            color: allowed ? AppColors.income : AppColors.expense,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  allowed ? 'Кредиты доступны' : 'Кредит не выдаётся',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: allowed ? AppColors.income : AppColors.expense,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _decision.message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.text,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _optionCard(EmploymentOption option) {
    final selected = option.code == _status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _status = option.code),

        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),

          child: Row(
            children: [

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (option.canCredit ? AppColors.primary : AppColors.expense)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  option.canCredit
                      ? Icons.badge_outlined
                      : Icons.do_not_disturb_on_outlined,
                  color: option.canCredit ? AppColors.primary : AppColors.expense,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      option.hint,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textMuted,
                      ),
                    ),

                  ],
                ),
              ),

              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool strong = false}) {
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
