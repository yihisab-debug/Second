double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

class Profile {
  final int id;
  final String fullName;
  final String phone;
  final bool hasPin;

  Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.hasPin,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: _toInt(json['id']),
        fullName: '${json['full_name'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        hasPin: json['has_pin'] == true,
      );
}

class Wallet {
  final int id;
  final String title;
  final String number;
  final String currency;
  final double balance;
  final bool isDefault;

  Wallet({
    required this.id,
    required this.title,
    required this.number,
    required this.currency,
    required this.balance,
    required this.isDefault,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: _toInt(json['id']),
        title: '${json['title'] ?? ''}',
        number: '${json['number'] ?? ''}',
        currency: '${json['currency'] ?? 'KZT'}',
        balance: _toDouble(json['balance']),
        isDefault: json['is_default'] == true,
      );

  static List<Wallet> listFrom(dynamic raw) {
    if (raw is! List) return <Wallet>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => Wallet.fromJson(item))
        .toList();
  }
}

class TxItem {
  final int id;
  final int walletId;
  final String type;
  final double amount;
  final double balanceAfter;
  final String title;
  final String counterparty;
  final String currency;
  final String walletTitle;
  final String createdAt;

  TxItem({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.title,
    required this.counterparty,
    required this.currency,
    required this.walletTitle,
    required this.createdAt,
  });

  bool get isIncome => type == 'deposit' || type == 'transfer_in';

  String get typeLabel {
    switch (type) {
      case 'deposit':
        return 'Пополнение';
      case 'withdraw':
        return 'Вывод средств';
      case 'transfer_out':
        return 'Перевод отправлен';
      case 'transfer_in':
        return 'Перевод получен';
      default:
        return 'Операция';
    }
  }

  factory TxItem.fromJson(Map<String, dynamic> json) => TxItem(
        id: _toInt(json['id']),
        walletId: _toInt(json['wallet_id']),
        type: '${json['type'] ?? ''}',
        amount: _toDouble(json['amount']),
        balanceAfter: _toDouble(json['balance_after']),
        title: '${json['title'] ?? ''}',
        counterparty: '${json['counterparty'] ?? ''}',
        currency: '${json['currency'] ?? 'KZT'}',
        walletTitle: '${json['wallet_title'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
      );

  static List<TxItem> listFrom(dynamic raw) {
    if (raw is! List) return <TxItem>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => TxItem.fromJson(item))
        .toList();
  }
}
