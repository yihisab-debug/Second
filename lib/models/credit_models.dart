double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

class Creditor {
  final int id;
  final String name;
  final String description;
  final double rate;
  final double minAmount;
  final double maxAmount;
  final int minMonths;
  final int maxMonths;
  final String currency;

  Creditor({
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

  factory Creditor.fromJson(Map<String, dynamic> json) => Creditor(
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

  static List<Creditor> listFrom(dynamic raw) {
    if (raw is! List) return <Creditor>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => Creditor.fromJson(item))
        .toList();
  }

  double monthlyPayment(double amount, int months) {
    if (months < 1) return amount;
    final monthRate = rate / 100 / 12;
    if (monthRate <= 0) return amount / months;
    final k = _pow(1 + monthRate, months);
    return amount * monthRate * k / (k - 1);
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

class Credit {
  final int id;
  final int creditorId;
  final String creditorName;
  final int walletId;
  final String walletTitle;
  final double amount;
  final double rate;
  final int months;
  final double monthlyPayment;
  final double totalAmount;
  final double paidAmount;
  final double remaining;
  final String currency;
  final String purpose;
  final String status;
  final String createdAt;
  final String closedAt;

  Credit({
    required this.id,
    required this.creditorId,
    required this.creditorName,
    required this.walletId,
    required this.walletTitle,
    required this.amount,
    required this.rate,
    required this.months,
    required this.monthlyPayment,
    required this.totalAmount,
    required this.paidAmount,
    required this.remaining,
    required this.currency,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.closedAt,
  });

  bool get isActive => status == 'active';

  double get progress {
    if (totalAmount <= 0) return 0;
    final value = paidAmount / totalAmount;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  factory Credit.fromJson(Map<String, dynamic> json) => Credit(
        id: _toInt(json['id']),
        creditorId: _toInt(json['creditor_id']),
        creditorName: '${json['creditor_name'] ?? ''}',
        walletId: _toInt(json['wallet_id']),
        walletTitle: '${json['wallet_title'] ?? ''}',
        amount: _toDouble(json['amount']),
        rate: _toDouble(json['rate']),
        months: _toInt(json['months']),
        monthlyPayment: _toDouble(json['monthly_payment']),
        totalAmount: _toDouble(json['total_amount']),
        paidAmount: _toDouble(json['paid_amount']),
        remaining: _toDouble(json['remaining']),
        currency: '${json['currency'] ?? 'KZT'}',
        purpose: '${json['purpose'] ?? ''}',
        status: '${json['status'] ?? 'active'}',
        createdAt: '${json['created_at'] ?? ''}',
        closedAt: '${json['closed_at'] ?? ''}',
      );

  static List<Credit> listFrom(dynamic raw) {
    if (raw is! List) return <Credit>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => Credit.fromJson(item))
        .toList();
  }
}

class CreditSummary {
  final int activeCount;
  final double totalDebt;
  final double monthlyPayment;
  final String currency;

  CreditSummary({
    required this.activeCount,
    required this.totalDebt,
    required this.monthlyPayment,
    required this.currency,
  });

  factory CreditSummary.fromJson(Map<String, dynamic> json) => CreditSummary(
        activeCount: _toInt(json['active_count']),
        totalDebt: _toDouble(json['total_debt']),
        monthlyPayment: _toDouble(json['monthly_payment']),
        currency: '${json['currency'] ?? 'KZT'}',
      );

  static CreditSummary empty() => CreditSummary(
        activeCount: 0,
        totalDebt: 0,
        monthlyPayment: 0,
        currency: 'KZT',
      );
}
