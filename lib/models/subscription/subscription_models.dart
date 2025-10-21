// Subscription Model
class Subscription {
  final int id;
  final int userId;
  final String name;
  final String? platform;
  final String? iconUrl;
  final double amount;
  final String currency;
  final String billingCycle;
  final int billingDate;
  final DateTime nextBillingDate;
  final bool reminderEnabled;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.name,
    this.platform,
    this.iconUrl,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.billingDate,
    required this.nextBillingDate,
    required this.reminderEnabled,
    required this.isActive,
    this.notes,
    required this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Amount güvenli parse - String veya num gelebilir
    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Bool güvenli parse
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    // DateTime güvenli parse
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Subscription(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? '',
      platform: json['platform'] as String?,
      iconUrl: json['icon_url'] as String?,
      amount: parseAmount(json['amount']),
      currency: json['currency'] as String? ?? 'TRY',
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      billingDate: json['billing_date'] as int? ?? 1,
      nextBillingDate: parseDateTime(json['next_billing_date']),
      reminderEnabled: parseBool(json['reminder_enabled']),
      isActive: parseBool(json['is_active']),
      notes: json['notes'] as String?,
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'platform': platform,
      'icon_url': iconUrl,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle,
      'billing_date': billingDate,
      'next_billing_date': nextBillingDate.toIso8601String(),
      'reminder_enabled': reminderEnabled,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get billingCycleLabel {
    switch (billingCycle) {
      case 'monthly':
        return 'Aylık';
      case 'yearly':
        return 'Yıllık';
      case 'weekly':
        return 'Haftalık';
      default:
        return billingCycle;
    }
  }
}

// Subscription Stats Model
class SubscriptionStats {
  final int totalActive;
  final double monthlyCost;
  final double yearlyCost;
  final double monthlyEquivalent;

  SubscriptionStats({
    required this.totalActive,
    required this.monthlyCost,
    required this.yearlyCost,
    required this.monthlyEquivalent,
  });

  factory SubscriptionStats.fromJson(Map<String, dynamic> json) {
    // Güvenli parse helper
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return SubscriptionStats(
      totalActive: json['total_active'] as int? ?? 0,
      monthlyCost: parseDouble(json['monthly_cost']),
      yearlyCost: parseDouble(json['yearly_cost']),
      monthlyEquivalent: parseDouble(json['monthly_equivalent']),
    );
  }
}

// Subscription Request
class SubscriptionRequest {
  final String name;
  final String? platform;
  final String? iconUrl;
  final double amount;
  final String currency;
  final String billingCycle;
  final int billingDate;
  final String nextBillingDate;
  final bool reminderEnabled;
  final bool isActive;
  final String? notes;

  SubscriptionRequest({
    required this.name,
    this.platform,
    this.iconUrl,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.billingDate,
    required this.nextBillingDate,
    required this.reminderEnabled,
    required this.isActive,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'platform': platform,
      'icon_url': iconUrl,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle,
      'billing_date': billingDate,
      'next_billing_date': nextBillingDate,
      'reminder_enabled': reminderEnabled,
      'is_active': isActive,
      'notes': notes,
    };
  }
}