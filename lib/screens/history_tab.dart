import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/transaction_tile.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<TxItem> _all = <TxItem>[];
  bool _loading = true;
  String _error = '';

  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = '');
    try {
      final data = await Api.call(Api.history, {'limit': '100'});
      if (!mounted) return;
      setState(() {
        _all = TxItem.listFrom(data['transactions']);
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

  List<TxItem> get _visible {
    switch (_filter) {
      case 1:
        return _all.where((t) => t.isIncome).toList();
      case 2:
        return _all.where((t) => !t.isIncome).toList();
      default:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'История операций',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),

            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _chip('Все', 0),
                const SizedBox(width: 8),
                _chip('Поступления', 1),
                const SizedBox(width: 8),
                _chip('Списания', 2),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _error.isNotEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 60),
                              EmptyState(
                                icon: Icons.wifi_off,
                                title: 'Не удалось загрузить историю',
                                subtitle: _error,
                              ),
                            ],
                          )

                        : items.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 60),
                                  EmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Здесь пока пусто',
                                    subtitle:
                                        'Пополните счёт или сделайте перевод — операции появятся в списке.',
                                  ),
                                ],
                              )

                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final tx = items[index];
                                  final label = dayLabel(tx.createdAt);
                                  final showLabel = index == 0 ||
                                      dayLabel(items[index - 1].createdAt) != label;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (showLabel)

                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: index == 0 ? 0 : 14,
                                            bottom: 2,
                                          ),

                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),

                                      TransactionTile(tx: tx),

                                    ],
                                  );
                                },
                              ),

                  ),
          ),

        ],
      ),
    );
  }

  Widget _chip(String label, int value) {
    final active = _filter == value;
    return Expanded(

      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider,
            ),
          ),

          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),

        ),
      ),

    );
  }
}
