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

class Recipient {
  final int userId;
  final String fullName;
  final String phone;
  final String phonePretty;
  final List<String> currencies;

  Recipient({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.phonePretty,
    required this.currencies,
  });

  bool supports(String currency) => currencies.contains(currency.toUpperCase());

  factory Recipient.fromJson(Map<String, dynamic> json) {
    final raw = json['currencies'];
    return Recipient(
      userId: _toInt(json['user_id']),
      fullName: '${json['full_name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      phonePretty: '${json['phone_pretty'] ?? ''}',
      currencies: raw is List
          ? raw.map((e) => '$e'.toUpperCase()).toList()
          : <String>[],
    );
  }
}

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final double amount;
  final String currency;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.amount,
    required this.currency,
    required this.isRead,
    required this.createdAt,
  });

  bool get isIncome => type == 'transfer_in' || type == 'deposit';
  bool get hasAmount => amount > 0;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: _toInt(json['id']),
        type: '${json['type'] ?? 'info'}',
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        amount: _toDouble(json['amount']),
        currency: '${json['currency'] ?? 'KZT'}',
        isRead: json['is_read'] == true,
        createdAt: '${json['created_at'] ?? ''}',
      );

  static List<AppNotification> listFrom(dynamic raw) {
    if (raw is! List) return <AppNotification>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => AppNotification.fromJson(item))
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
