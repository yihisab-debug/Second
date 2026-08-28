import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class WalletCreateScreen extends StatefulWidget {
  const WalletCreateScreen({super.key});

  @override
  State<WalletCreateScreen> createState() => _WalletCreateScreenState();
}

class _WalletCreateScreenState extends State<WalletCreateScreen> {
  final _titleController = TextEditingController();

  String _currency = 'KZT';
  bool _loading = false;

  static const Map<String, String> _currencies = {
    'KZT': 'Тенге · ₸',
    'USD': 'Доллар · \$',
    'EUR': 'Евро · €',
  };

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showMessage(context, 'Введите название счёта', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      await Api.call(Api.walletCreate, {
        'title': title,
        'currency': _currency,
      });

      if (!mounted) return;
      popWithMessage(
        context, 'Счёт «$title» открыт');
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый счёт'),
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

              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: Накопления',
                  prefixIcon: Icon(Icons.label_outline),
                  counterText: '',
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Валюта',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 8),

              Column(
                children: _currencies.entries.map((entry) {
                  final selected = entry.key == _currency;
                  return Padding(

                    padding: const EdgeInsets.only(bottom: 8),

                    child: GestureDetector(
                      onTap: () => setState(() => _currency = entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.divider,
                            width: selected ? 1.6 : 1,
                          ),
                        ),

                        child: Row(
                          children: [

                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 20,
                            ),

                            const SizedBox(width: 12),

                            Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Открыть счёт',
                loading: _loading,
                onPressed: _submit,
              ),

              const SizedBox(height: 12),

              const Text(
                'Номер счёта из 16 цифр присвоится автоматически. '
                'Всего можно открыть до 5 счетов.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
