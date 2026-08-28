import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';

class TransactionTile extends StatelessWidget {
  final TxItem tx;

  const TransactionTile({super.key, required this.tx});

  IconData get _icon {
    switch (tx.type) {
      case 'deposit':
        return Icons.south_west;
      case 'withdraw':
        return Icons.north_east;
      case 'transfer_out':
        return Icons.arrow_outward;
      default:
        return Icons.call_received;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncome ? AppColors.income : AppColors.expense;
    final sign = tx.isIncome ? '+' : '-';

    final subtitleParts = <String>[formatDateTime(tx.createdAt)];
    if (tx.counterparty.isNotEmpty) subtitleParts.add(tx.counterparty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: color, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  tx.title.isEmpty ? tx.typeLabel : tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitleParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Text(
                '$sign${formatMoney(tx.amount, tx.currency)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                tx.walletTitle,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),

            ],
          ),
          
        ],
      ),
    );
  }
}
