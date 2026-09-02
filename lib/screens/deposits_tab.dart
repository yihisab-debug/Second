import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/deposit_models.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'deposit_open_screen.dart';

class DepositsTab extends StatefulWidget {
  const DepositsTab({super.key});

  @override
  State<DepositsTab> createState() => _DepositsTabState();
}

class _DepositsTabState extends State<DepositsTab> {
  List<Deposit> _deposits = <Deposit>[];
  List<DepositProduct> _products = <DepositProduct>[];
  List<Wallet> _wallets = <Wallet>[];
  DepositSummary _summary = DepositSummary.empty();

  bool _loading = true;
  bool _closing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = '');

    try {
      final depositsData = await Api.call(Api.deposits);
      final productsData = await Api.call(Api.depositProducts);
      final walletsData = await Api.call(Api.wallets);

      if (!mounted) return;
      setState(() {
        _deposits = Deposit.listFrom(depositsData['deposits']);
        final summary = depositsData['summary'];
        _summary = summary is Map<String, dynamic>
            ? DepositSummary.fromJson(summary)
            : DepositSummary.empty();
        _products = DepositProduct.listFrom(productsData['products']);
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

  Future<void> _openNew([DepositProduct? product]) async {
    if (_products.isEmpty) {
      showMessage(context, 'Список программ пуст', error: true);
      return;
    }
    if (_wallets.isEmpty) {
      showMessage(context, 'Сначала откройте счёт', error: true);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositOpenScreen(
          products: _products,
          wallets: _wallets,
          initial: product ?? _products.first,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _close(Deposit deposit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(deposit.isMatured ? 'Закрыть вклад' : 'Закрыть досрочно'),
        content: Text(
          deposit.isMatured
              ? 'Срок вклада закончился. На счёт вернётся '
                  '${formatMoney(deposit.amount + deposit.income, deposit.currency)}, '
                  'включая доход ${formatMoney(deposit.income, deposit.currency)}.'
              : 'Срок ещё не закончился. При досрочном закрытии проценты не начисляются, '
                  'на счёт вернётся только ${formatMoney(deposit.amount, deposit.currency)}.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Закрыть вклад'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);

    try {
      final data = await Api.call(Api.depositClose, {
        'deposit_id': '${deposit.id}',
        'wallet_id': '${deposit.walletId}',
      });

      final raw = data['payout'];
      final payout = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;

      if (!mounted) return;
      showMessage(
        context,
        'Вклад закрыт. На счёт зачислено '
        '${formatMoney(payout, deposit.currency)}',
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _closing = false);
    }
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
                  'Депозиты',
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
                Tab(text: 'Мои вклады'),
                Tab(text: 'Программы'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _myDepositsTab(),
                  _productsTab(),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _myDepositsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [

          _summaryCard(),

          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Открыть вклад',
            icon: Icons.add_rounded,
            onPressed: () => _openNew(),
          ),

          const SizedBox(height: 20),

          if (_deposits.isEmpty)
            const EmptyState(
              icon: Icons.savings_outlined,
              title: 'Вкладов пока нет',
              subtitle:
                  'Выберите программу на соседней вкладке и разместите первую сумму.',
            )
          else
            ..._deposits.map(_depositCard),

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
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            'Всего во вкладах',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 4),

          Text(
            formatMoney(_summary.totalSaved, _summary.currency),
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
                  'Ожидаемый доход',
                  formatMoney(_summary.expectedIncome, _summary.currency,
                      withCents: false),
                ),
              ),

              Expanded(
                child: _summaryCell(
                  'Активных вкладов',
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

  Widget _depositCard(Deposit deposit) {
    final closed = !deposit.isActive;
    final color = closed ? AppColors.textMuted : AppColors.income;

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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    closed ? Icons.check_rounded : Icons.savings_rounded,
                    color: color,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        deposit.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),

                      Text(
                        '${deposit.months} мес. · ${deposit.rate}% годовых',
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
                    color: (closed
                            ? AppColors.textMuted
                            : (deposit.isMatured
                                ? AppColors.income
                                : AppColors.accent))
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    closed
                        ? 'Закрыт'
                        : (deposit.isMatured ? 'Срок вышел' : 'Активен'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: closed
                          ? AppColors.textMuted
                          : (deposit.isMatured
                              ? AppColors.income
                              : AppColors.accent),
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: closed ? 1 : deposit.progress,
                minHeight: 7,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),

            const SizedBox(height: 10),

            _row('Сумма вклада', formatMoney(deposit.amount, deposit.currency)),
            _row('Доход', formatMoney(deposit.income, deposit.currency)),
            _row(
              closed ? 'Выплачено' : 'К получению',
              formatMoney(deposit.totalAmount, deposit.currency),
              strong: true,
            ),
            _row('Открыт', dayLabel(deposit.openedAt)),

            if (closed)
              _row('Закрыт', dayLabel(deposit.closedAt))
            else ...[
              _row('Дата окончания', dayLabel(deposit.endsAt)),
              _row('Осталось дней', '${deposit.daysLeft}'),
            ],

            if (!closed) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _closing ? null : () => _close(deposit),
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(
                    deposit.isMatured
                        ? 'Забрать деньги'
                        : 'Закрыть досрочно',
                  ),
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

  Widget _productsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [

          if (_products.isEmpty)
            const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Программ пока нет',
              subtitle: 'Добавьте записи в таблицу deposit_products в базе данных.',
            )
          else
            ..._products.map(_productCard),

        ],
      ),
    );
  }

  Widget _productCard(DepositProduct product) {
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
                    color: AppColors.income.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppColors.income,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    product.name,
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
                  '${product.rate}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.income,
                  ),
                ),

              ],
            ),

            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                product.description,
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
              '${formatMoney(product.minAmount, product.currency, withCents: false)}'
                  ' — ${formatMoney(product.maxAmount, product.currency, withCents: false)}',
            ),

            _row('Срок', '${product.minMonths}—${product.maxMonths} мес.'),

            const SizedBox(height: 10),

            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openNew(product),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Открыть вклад'),
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
