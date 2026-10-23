// Installment (taksit) Model — backend: /api/installments
class Installment {
  final int id;
  final String name;
  final double totalAmount;
  final int installmentCount;
  final int paidCount;
  final String startDate; // yyyy-MM-dd
  final String currency;

  Installment({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.installmentCount,
    required this.paidCount,
    required this.startDate,
    this.currency = 'TRY',
  });

  double get monthlyAmount =>
      installmentCount > 0 ? totalAmount / installmentCount : 0;
  int get remainingCount =>
      (installmentCount - paidCount).clamp(0, installmentCount);
  double get remainingAmount => monthlyAmount * remainingCount;
  bool get isDone => paidCount >= installmentCount;

  /// Bir sonraki ödeme tarihi (başlangıç + ödenen taksit ayı).
  DateTime? get nextDueDate {
    if (isDone) return null;
    try {
      final d = DateTime.parse(startDate);
      return DateTime(d.year, d.month + paidCount, d.day);
    } catch (_) {
      return null;
    }
  }

  factory Installment.fromJson(Map<String, dynamic> json) {
    double pd(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int pi(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String date(dynamic v) {
      if (v is String) return v.contains('T') ? v.split('T').first : v;
      return '';
    }

    return Installment(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      totalAmount: pd(json['total_amount']),
      installmentCount: pi(json['installment_count']),
      paidCount: pi(json['paid_count']),
      startDate: date(json['start_date']),
      currency: json['currency'] as String? ?? 'TRY',
    );
  }
}

class InstallmentRequest {
  final String name;
  final double totalAmount;
  final int installmentCount;
  final int paidCount;
  final String startDate;
  final String currency;

  InstallmentRequest({
    required this.name,
    required this.totalAmount,
    required this.installmentCount,
    this.paidCount = 0,
    required this.startDate,
    this.currency = 'TRY',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'total_amount': totalAmount,
        'installment_count': installmentCount,
        'paid_count': paidCount,
        'start_date': startDate,
        'currency': currency,
      };
}
