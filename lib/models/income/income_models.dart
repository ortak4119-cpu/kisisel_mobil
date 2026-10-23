// Income Model (backend: /api/incomes)
class ApiIncome {
  final int id;
  final double amount;
  final String currency;
  final String category;
  final String? description;
  final String incomeDate; // yyyy-MM-dd

  ApiIncome({
    required this.id,
    required this.amount,
    required this.currency,
    required this.category,
    this.description,
    required this.incomeDate,
  });

  factory ApiIncome.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    String parseDate(dynamic v) {
      if (v is String) {
        return v.contains('T') ? v.split('T').first : v;
      }
      return '';
    }

    return ApiIncome(
      id: json['id'] as int,
      amount: parseDouble(json['amount']),
      currency: json['currency'] as String? ?? 'TRY',
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String?,
      incomeDate: parseDate(json['income_date']),
    );
  }
}

class IncomeRequest {
  final double amount;
  final String currency;
  final String category;
  final String? description;
  final String incomeDate; // yyyy-MM-dd

  IncomeRequest({
    required this.amount,
    required this.currency,
    required this.category,
    this.description,
    required this.incomeDate,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'income_date': incomeDate,
      };
}
