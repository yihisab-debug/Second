import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/credit_models.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'credit_create_screen.dart';
import 'credit_pay_screen.dart';

class CreditsTab extends StatefulWidget {
  const CreditsTab({super.key});

  @override
  State<CreditsTab> createState() => _CreditsTabState();
}

class _CreditsTabState extends State<CreditsTab> {
  List<Credit> _credits = <Credit>[];
  List<Creditor> _creditors = <Creditor>[];
  List<Wallet> _wallets = <Wallet>[];
  CreditSummary _summary = CreditSummary.empty();

  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = '');

    try {
      final creditsData = await Api.call(Api.credits);
      final creditorsData = await Api.call(Api.creditors);
      final walletsData = await Api.call(Api.wallets);

      if (!mounted) return;
      setState(() {
        _credits = Credit.listFrom(creditsData['credits']);
        final summary = creditsData['summary'];
        _summary = summary is Map<String, dynamic>
            ? CreditSummary.fromJson(summary)
            : CreditSummary.empty();
        _creditors = Creditor.listFrom(creditorsData['creditors']);
        _wallets = Wallet.listFrom(walletsData['wallets']);
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

  Future<void> _openCreate([Creditor? creditor]) async {
    if (_creditors.isEmpty) {
      showMessage(context, 'Список кредиторов пуст', error: true);
      return;
    }
    if (_wallets.isEmpty) {
      showMessage(context, 'Сначала откройте счёт', error: true);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCreateScreen(
          creditors: _creditors,
          wallets: _wallets,
          initial: creditor ?? _creditors.first,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openPay(Credit credit) async {
    if (_wallets.isEmpty) {
      showMessage(context, 'Сначала откройте счёт', error: true);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditPayScreen(credit: credit, wallets: _wallets),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Кредиты',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),

            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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

            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              dividerColor: AppColors.divider,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Мои кредиты'),
                Tab(text: 'Кредиторы'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _myCreditsTab(),
                  _creditorsTab(),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _myCreditsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [

          _summaryCard(),

          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Оформить кредит',
            icon: Icons.add_rounded,
            onPressed: () => _openCreate(),
          ),

          const SizedBox(height: 20),

          if (_credits.isEmpty)
            const EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'Кредитов пока нет',
              subtitle:
                  'Выберите кредитора на соседней вкладке и оформите первый кредит.',
            )
          else
            ..._credits.map(_creditCard),

        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            'Общий долг',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 4),

          Text(
            formatMoney(_summary.totalDebt, _summary.currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [

              Expanded(
                child: _summaryCell(
                  'Платёж в месяц',
                  formatMoney(_summary.monthlyPayment, _summary.currency,
                      withCents: false),
                ),
              ),

              Expanded(
                child: _summaryCell(
                  'Активных кредитов',
                  '${_summary.activeCount}',
                ),
              ),

            ],
          ),

        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

      ],
    );
  }

  Widget _creditCard(Credit credit) {
    final closed = !credit.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (closed ? AppColors.income : AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    closed ? Icons.check_rounded : Icons.account_balance_rounded,
                    color: closed ? AppColors.income : AppColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        credit.creditorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),

                      Text(
                        '${credit.months} мес. · ${credit.rate}% годовых',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),

                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (closed ? AppColors.income : AppColors.accent)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    closed ? 'Закрыт' : 'Активен',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: closed ? AppColors.income : AppColors.accent,
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: credit.progress,
                minHeight: 7,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  closed ? AppColors.income : AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _row('Сумма кредита', formatMoney(credit.amount, credit.currency)),
            _row('К возврату', formatMoney(credit.totalAmount, credit.currency)),
            _row('Погашено', formatMoney(credit.paidAmount, credit.currency)),
            _row(
              'Остаток',
              formatMoney(credit.remaining, credit.currency),
              strong: true,
            ),
            _row(
              'Платёж в месяц',
              formatMoney(credit.monthlyPayment, credit.currency),
            ),

            if (credit.purpose.isNotEmpty) _row('Цель', credit.purpose),

            _row('Оформлен', dayLabel(credit.createdAt)),

            if (!closed) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _openPay(credit),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Внести платёж'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
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
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.text,
            ),
          ),

        ],
      ),
    );
  }

  Widget _creditorsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [

          if (_creditors.isEmpty)
            const EmptyState(
              icon: Icons.business_outlined,
              title: 'Кредиторов пока нет',
              subtitle: 'Добавьте записи в таблицу creditors в базе данных.',
            )
          else
            ..._creditors.map(_creditorCard),

        ],
      ),
    );
  }

  Widget _creditorCard(Creditor creditor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    creditor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),

                Text(
                  '${creditor.rate}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),

              ],
            ),

            if (creditor.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                creditor.description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textMuted,
                ),
              ),
            ],

            const SizedBox(height: 10),

            _row(
              'Сумма',
              '${formatMoney(creditor.minAmount, creditor.currency, withCents: false)}'
                  ' — ${formatMoney(creditor.maxAmount, creditor.currency, withCents: false)}',
            ),

            _row('Срок', '${creditor.minMonths}—${creditor.maxMonths} мес.'),

            const SizedBox(height: 10),

            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openCreate(creditor),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Оформить кредит'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
