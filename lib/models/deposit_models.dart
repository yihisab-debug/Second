double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

class DepositProduct {
  final int id;
  final String name;
  final String description;
  final double rate;
  final double minAmount;
  final double maxAmount;
  final int minMonths;
  final int maxMonths;
  final String currency;

  DepositProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.rate,
    required this.minAmount,
    required this.maxAmount,
    required this.minMonths,
    required this.maxMonths,
    required this.currency,
  });

  factory DepositProduct.fromJson(Map<String, dynamic> json) => DepositProduct(
        id: _toInt(json['id']),
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        rate: _toDouble(json['rate']),
        minAmount: _toDouble(json['min_amount']),
        maxAmount: _toDouble(json['max_amount']),
        minMonths: _toInt(json['min_months']),
        maxMonths: _toInt(json['max_months']),
        currency: '${json['currency'] ?? 'KZT'}',
      );

  static List<DepositProduct> listFrom(dynamic raw) {
    if (raw is! List) return <DepositProduct>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => DepositProduct.fromJson(item))
        .toList();
  }

  double income(double amount, int months) {
    if (months < 1) return 0;
    return amount * (rate / 100) * months / 12;
  }
}

class Deposit {
  final int id;
  final int productId;
  final String productName;
  final int walletId;
  final String walletTitle;
  final double amount;
  final double rate;
  final int months;
  final double income;
  final double totalAmount;
  final String currency;
  final String status;
  final String openedAt;
  final String endsAt;
  final String closedAt;
  final int daysLeft;
  final double progress;
  final bool isMatured;

  Deposit({
    required this.id,
    required this.productId,
    required this.productName,
    required this.walletId,
    required this.walletTitle,
    required this.amount,
    required this.rate,
    required this.months,
    required this.income,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.openedAt,
    required this.endsAt,
    required this.closedAt,
    required this.daysLeft,
    required this.progress,
    required this.isMatured,
  });

  bool get isActive => status == 'active';

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
        id: _toInt(json['id']),
        productId: _toInt(json['product_id']),
        productName: '${json['product_name'] ?? ''}',
        walletId: _toInt(json['wallet_id']),
        walletTitle: '${json['wallet_title'] ?? ''}',
        amount: _toDouble(json['amount']),
        rate: _toDouble(json['rate']),
        months: _toInt(json['months']),
        income: _toDouble(json['income']),
        totalAmount: _toDouble(json['total_amount']),
        currency: '${json['currency'] ?? 'KZT'}',
        status: '${json['status'] ?? 'active'}',
        openedAt: '${json['opened_at'] ?? ''}',
        endsAt: '${json['ends_at'] ?? ''}',
        closedAt: '${json['closed_at'] ?? ''}',
        daysLeft: _toInt(json['days_left']),
        progress: _toDouble(json['progress']),
        isMatured: json['is_matured'] == true,
      );

  static List<Deposit> listFrom(dynamic raw) {
    if (raw is! List) return <Deposit>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => Deposit.fromJson(item))
        .toList();
  }
}

class DepositSummary {
  final int activeCount;
  final double totalSaved;
  final double expectedIncome;
  final String currency;

  DepositSummary({
    required this.activeCount,
    required this.totalSaved,
    required this.expectedIncome,
    required this.currency,
  });

  factory DepositSummary.fromJson(Map<String, dynamic> json) => DepositSummary(
        activeCount: _toInt(json['active_count']),
        totalSaved: _toDouble(json['total_saved']),
        expectedIncome: _toDouble(json['expected_income']),
        currency: '${json['currency'] ?? 'KZT'}',
      );

  static DepositSummary empty() => DepositSummary(
        activeCount: 0,
        totalSaved: 0,
        expectedIncome: 0,
        currency: 'KZT',
      );
}
