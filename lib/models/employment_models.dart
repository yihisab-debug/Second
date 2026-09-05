double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

class EmploymentOption {
  final String code;
  final String label;
  final String hint;
  final bool canCredit;
  final bool needEmployer;
  final double minIncome;
  final int minMonths;
  final double maxAmount;
  final double paymentPart;

  EmploymentOption({
    required this.code,
    required this.label,
    required this.hint,
    required this.canCredit,
    required this.needEmployer,
    required this.minIncome,
    required this.minMonths,
    required this.maxAmount,
    required this.paymentPart,
  });

  factory EmploymentOption.fromJson(Map<String, dynamic> json) =>
      EmploymentOption(
        code: '${json['code'] ?? ''}',
        label: '${json['label'] ?? ''}',
        hint: '${json['hint'] ?? ''}',
        canCredit: json['can_credit'] == true,
        needEmployer: json['need_employer'] == true,
        minIncome: _toDouble(json['min_income']),
        minMonths: _toInt(json['min_months']),
        maxAmount: _toDouble(json['max_amount']),
        paymentPart: _toDouble(json['payment_part']),
      );

  static List<EmploymentOption> listFrom(dynamic raw) {
    if (raw is! List) return <EmploymentOption>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => EmploymentOption.fromJson(item))
        .toList();
  }
}

class Employment {
  final String status;
  final String statusLabel;
  final String employer;
  final double monthlyIncome;
  final int experienceMonths;
  final bool isFilled;
  final bool canCredit;
  final double maxAmount;
  final double paymentPart;

  Employment({
    required this.status,
    required this.statusLabel,
    required this.employer,
    required this.monthlyIncome,
    required this.experienceMonths,
    required this.isFilled,
    required this.canCredit,
    required this.maxAmount,
    required this.paymentPart,
  });

  factory Employment.fromJson(Map<String, dynamic> json) => Employment(
        status: '${json['status'] ?? ''}',
        statusLabel: '${json['status_label'] ?? ''}',
        employer: '${json['employer'] ?? ''}',
        monthlyIncome: _toDouble(json['monthly_income']),
        experienceMonths: _toInt(json['experience_months']),
        isFilled: json['is_filled'] == true,
        canCredit: json['can_credit'] == true,
        maxAmount: _toDouble(json['max_amount']),
        paymentPart: _toDouble(json['payment_part']),
      );

  static Employment from(dynamic raw) {
    if (raw is Map<String, dynamic>) return Employment.fromJson(raw);
    return Employment.empty();
  }

  static Employment empty() => Employment(
        status: '',
        statusLabel: '',
        employer: '',
        monthlyIncome: 0,
        experienceMonths: 0,
        isFilled: false,
        canCredit: false,
        maxAmount: 0,
        paymentPart: 0,
      );
}

class CreditDecision {
  final bool allowed;
  final String message;

  CreditDecision({
    required this.allowed,
    required this.message,
  });

  factory CreditDecision.fromJson(Map<String, dynamic> json) => CreditDecision(
        allowed: json['allowed'] == true,
        message: '${json['message'] ?? ''}',
      );

  static CreditDecision from(dynamic raw) {
    if (raw is Map<String, dynamic>) return CreditDecision.fromJson(raw);
    return CreditDecision.empty();
  }

  static CreditDecision empty() => CreditDecision(
        allowed: false,
        message: 'Укажите статус занятости в профиле',
      );
}
