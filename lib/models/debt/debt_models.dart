// Debt Model (backend: /api/debts)
class Debt {
  final int id;
  final String name;
  final double balance;
  final double interestRate; // yıllık %
  final double minPayment;
  final String currency;

  Debt({
    required this.id,
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minPayment,
    this.currency = 'TRY',
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    double pd(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Debt(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      balance: pd(json['balance']),
      interestRate: pd(json['interest_rate']),
      minPayment: pd(json['min_payment']),
      currency: json['currency'] as String? ?? 'TRY',
    );
  }
}

class DebtRequest {
  final String name;
  final double balance;
  final double interestRate;
  final double minPayment;
  final String currency;

  DebtRequest({
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minPayment,
    this.currency = 'TRY',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'balance': balance,
        'interest_rate': interestRate,
        'min_payment': minPayment,
        'currency': currency,
      };
}

/// Borç ödeme planı sonucu.
class DebtPlan {
  final int months; // toplam ay (600'de kapanmazsa 'ödenemez' kabul)
  final double totalInterest;
  final bool unpayable;
  final List<String> order; // ödenme sırasına göre borç adları

  DebtPlan({
    required this.months,
    required this.totalInterest,
    required this.unpayable,
    required this.order,
  });
}
