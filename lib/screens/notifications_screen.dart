import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = <AppNotification>[];
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
      final data = await Api.call(Api.notifications);
      if (!mounted) return;
      setState(() {
        _items = AppNotification.listFrom(data['notifications']);
        _loading = false;
      });

      if (_items.any((n) => !n.isRead)) {
        await Api.call(Api.notificationsRead);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [

                    if (_error.isNotEmpty)
                      AppCard(
                        child: Row(
                          children: [

                            const Icon(Icons.wifi_off, color: AppColors.expense),

                            const SizedBox(width: 12),

                            Expanded(child: Text(_error)),

                            TextButton(
                              onPressed: _load,
                              child: const Text('Ещё раз'),
                            ),

                          ],
                        ),
                      )
                    else if (_items.isEmpty)
                      const EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Уведомлений пока нет',
                        subtitle:
                            'Здесь появятся сообщения о пополнениях и переводах.',
                      )
                    else
                      ..._items.map(_tile),

                  ],
                ),
              ),
      ),
    );
  }

  Widget _tile(AppNotification n) {
    final color = n.isIncome ? AppColors.income : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                n.isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.notifications_active_outlined,
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),

                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.expense,
                            shape: BoxShape.circle,
                          ),
                        ),

                    ],
                  ),

                  if (n.hasAmount) ...[

                    const SizedBox(height: 2),

                    Text(
                      '+${formatMoney(n.amount, n.currency)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),

                  ],

                  if (n.body.isNotEmpty) ...[

                    const SizedBox(height: 4),

                    Text(
                      n.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),

                  ],

                  const SizedBox(height: 6),

                  Text(
                    formatDateTime(n.createdAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
