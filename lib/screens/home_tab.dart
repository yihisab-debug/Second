import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/wallet_card.dart';
import 'deposit_screen.dart';
import 'notifications_screen.dart';
import 'transfer_screen.dart';
import 'wallet_create_screen.dart';
import 'withdraw_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onOpenHistory;

  const HomeTab({super.key, required this.onOpenHistory});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _pageController = PageController(viewportFraction: 0.88);

  List<Wallet> _wallets = <Wallet>[];
  List<TxItem> _transactions = <TxItem>[];
  bool _loading = true;
  String _error = '';
  int _page = 0;

  int _unread = 0;

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _checkUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = '');
    try {
      final data = await Api.call(Api.overview);

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final profile = Profile.fromJson(user);
        Session.fullName = profile.fullName;
        Session.phone = profile.phone;
        Session.hasPin = profile.hasPin;
      }

      if (!mounted) return;
      setState(() {
        _wallets = Wallet.listFrom(data['wallets']);
        _transactions = TxItem.listFrom(data['transactions']);
        _unread = int.tryParse('${data['unread'] ?? 0}') ?? 0;
        _loading = false;
        if (_page >= _wallets.length) _page = 0;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _checkUnread() async {
    if (!mounted || Session.token == null) return;

    try {
      final data = await Api.call(Api.notifications, {'limit': '1'});
      final unread = int.tryParse('${data['unread'] ?? 0}') ?? 0;
      if (!mounted) return;

      final isNew = unread > _unread;
      setState(() => _unread = unread);

      if (isNew) {
        final list = AppNotification.listFrom(data['notifications']);
        final text = list.isEmpty
            ? 'Вам поступил перевод'
            : (list.first.hasAmount
                ? 'Пополнение: +${formatMoney(list.first.amount, list.first.currency)}'
                : list.first.title);

        _load();
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: AppColors.income,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'Открыть',
                textColor: Colors.white,
                onPressed: _openNotifications,
              ),
            ),
          );
      }
    } on ApiException {
      return;
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted) _load();
  }

  Wallet? get _current {
    if (_wallets.isEmpty) return null;
    var index = _page;
    if (index < 0) index = 0;
    if (index > _wallets.length - 1) index = _wallets.length - 1;
    return _wallets[index];
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  void _needWallet() {
    showMessage(context, 'Сначала создайте счёт', error: true);
  }

  double get _totalKzt => _wallets
      .where((w) => w.currency == 'KZT')
      .fold<double>(0, (sum, w) => sum + w.balance);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [

            _header(),
            if (_error.isNotEmpty) _errorBox(),

            const SizedBox(height: 8),

            _walletsBlock(),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _actions(),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                title: 'Последние операции',
                actionText: _transactions.isEmpty ? null : 'Вся история',
                onAction: widget.onOpenHistory,
              ),
            ),

            if (_transactions.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Операций пока нет',
                subtitle: 'Пополните счёт — и первая запись появится здесь.',
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _transactions
                      .map((tx) => TransactionTile(tx: tx))
                      .toList(),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                Session.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),

          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Добрый день,',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),

                Text(
                  Session.fullName.isEmpty ? 'Клиент' : Session.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),

              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              const Text(
                'Всего на счетах',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              ),

              Text(
                formatMoney(_totalKzt, 'KZT', withCents: false),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),

            ],
          ),

          const SizedBox(width: 4),

          _bell(),

        ],
      ),
    );
  }

  Widget _bell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [

        IconButton(
          tooltip: 'Уведомления',
          onPressed: _openNotifications,
          icon: Icon(
            _unread > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: _unread > 0 ? AppColors.primary : AppColors.textMuted,
          ),
        ),

        if (_unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 17),
              decoration: BoxDecoration(
                color: AppColors.expense,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

      ],
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
    );
  }

  Widget _walletsBlock() {
    if (_wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              const EmptyState(
                icon: Icons.credit_card_off_outlined,
                title: 'Счетов пока нет',
                subtitle: 'Откройте счёт, чтобы начать пользоваться банком.',
              ),

              PrimaryButton(
                label: 'Открыть счёт',
                onPressed: () => _open(const WalletCreateScreen()),
              ),

            ],
          ),
        ),
      );
    }

    return Column(
      children: [

        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _wallets.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),

              child: WalletCard(
                wallet: _wallets[index],
                index: index,
                ownerName: Session.fullName,
              ),

            ),
          ),
        ),

        if (_wallets.length > 1) ...[

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_wallets.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

        ],
      ],
    );
  }

  Widget _actions() {
    final wallet = _current;

    return Row(
      children: [

        _actionButton(
          icon: Icons.add_rounded,
          label: 'Пополнить',
          color: AppColors.income,
          onTap: () => wallet == null
              ? _needWallet()
              : _open(DepositScreen(wallets: _wallets, initial: wallet)),
        ),

        _actionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Перевести',
          color: AppColors.primary,
          onTap: () => wallet == null
              ? _needWallet()
              : _open(TransferScreen(wallets: _wallets, initial: wallet)),
        ),

        _actionButton(
          icon: Icons.arrow_outward_rounded,
          label: 'Вывести',
          color: AppColors.expense,
          onTap: () => wallet == null
              ? _needWallet()
              : _open(WithdrawScreen(wallets: _wallets, initial: wallet)),
        ),

        _actionButton(
          icon: Icons.add_card_rounded,
          label: 'Новый счёт',
          color: AppColors.accent,
          onTap: () => _open(const WalletCreateScreen()),
        ),

      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(height: 8),

              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
