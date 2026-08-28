import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';

class WalletSelector extends StatelessWidget {
  final List<Wallet> wallets;
  final Wallet selected;
  final ValueChanged<Wallet> onChanged;
  final String label;

  const WalletSelector({
    super.key,
    required this.wallets,
    required this.selected,
    required this.onChanged,
    this.label = 'Счёт списания',
  });

  Widget _line(Wallet w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          '${w.title} · ${maskCardNumber(w.number)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          formatMoney(w.balance, w.currency),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMuted,
          ),
        ),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
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
              value: selected.id,
              isExpanded: true,
              itemHeight: 64,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
              selectedItemBuilder: (context) => wallets
                  .map((w) => Align(
                        alignment: Alignment.centerLeft,
                        child: _line(w),
                      ))
                  .toList(),
              items: wallets
                  .map(
                    (w) => DropdownMenuItem<int>(
                      value: w.id,
                      child: _line(w),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                onChanged(wallets.firstWhere((w) => w.id == id));
              },
            ),
          ),
        ),

      ],
    );
  }
}
