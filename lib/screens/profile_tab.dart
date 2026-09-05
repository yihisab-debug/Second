import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/phone.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/employment_models.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import 'employment_screen.dart';
import 'login_screen.dart';
import 'pin_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  List<Wallet> _wallets = <Wallet>[];
  Employment _employment = Employment.empty();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Api.call(Api.wallets);
      final employmentData = await Api.call(Api.employment);
      if (!mounted) return;
      setState(() {
        _wallets = Wallet.listFrom(data['wallets']);
        _employment = Employment.from(employmentData['employment']);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showMessage(context, e.message, error: true);
    }
  }

  Future<void> _openEmployment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmploymentScreen()),
    );
    if (mounted) _load();
  }

  Future<void> _copy(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    showMessage(context, 'Номер счёта скопирован');
  }

  Future<void> _copyPhone() async {
    await Clipboard.setData(ClipboardData(text: formatPhone(Session.phone)));
    if (!mounted) return;
    showMessage(context, 'Номер телефона скопирован');
  }

  Future<void> _changePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.change)),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Данные счетов останутся в банке — просто войдите снова.'),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 44),
              backgroundColor: AppColors.expense,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Выйти'),
          ),

        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Api.call(Api.logout);
    } on ApiException {
    }

    await Session.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [

          Row(
            children: [

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Center(

                  child: Text(
                    Session.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      Session.fullName.isEmpty ? 'Клиент' : Session.fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 2),

                    GestureDetector(
                      onTap: _copyPhone,

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Text(
                            formatPhone(Session.phone),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),

                          const SizedBox(width: 6),

                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),

                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          AppCard(
            child: Row(
              children: [

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.phone_iphone_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Номер для переводов',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        formatPhone(Session.phone),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),

                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Скопировать номер телефона',
                  onPressed: _copyPhone,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 24),

          const SectionTitle(title: 'Мои счета'),

          const SizedBox(height: 8),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._wallets.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(

                  child: Row(
                    children: [

                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              w.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              formatCardNumber(w.number),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),

                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [

                          Text(
                            formatMoney(w.balance, w.currency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),

                          const SizedBox(height: 2),

                          GestureDetector(
                            onTap: () => _copy(w.number),
                            child: const Text(
                              'Копировать номер',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),

                ),
              ),
            ),

          const SizedBox(height: 16),

          const SectionTitle(title: 'Занятость'),

          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                _employment.canCredit
                    ? Icons.badge_outlined
                    : Icons.work_off_outlined,
                color: _employment.canCredit
                    ? AppColors.income
                    : AppColors.expense,
              ),
              title: Text(
                _employment.isFilled
                    ? _employment.statusLabel
                    : 'Статус не указан',
              ),
              subtitle: Text(
                _employment.canCredit
                    ? 'Доход ${formatMoney(_employment.monthlyIncome, 'KZT', withCents: false)} · кредиты доступны'
                    : 'Без статуса занятости кредит не выдаётся',
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: _openEmployment,
            ),
          ),

          const SizedBox(height: 16),

          const SectionTitle(title: 'Безопасность'),

          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [

                ListTile(
                  leading: const Icon(Icons.pin_outlined, color: AppColors.primary),
                  title: const Text('Изменить PIN-код'),
                  subtitle: const Text('4 цифры для входа в приложение'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: _changePin,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.expense),
                  title: const Text(
                    'Выйти из аккаунта',
                    style: TextStyle(color: AppColors.expense),
                  ),
                  onTap: _logout,
                ),

              ],
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'MiniBank · учебный проект\nFlutter + PHP + MySQL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),

        ],
      ),
    );
  }
}
