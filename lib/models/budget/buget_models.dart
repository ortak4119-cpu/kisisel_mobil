// Budget Model
class Budget {
  final int id;
  final int userId;
  final double monthlyBudget;
  final String currency;

  Budget({
    required this.id,
    required this.userId,
    required this.monthlyBudget,
    required this.currency,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Budget(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      monthlyBudget: parseDouble(json['monthly_budget']),
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'monthly_budget': monthlyBudget,
      'currency': currency,
    };
  }
}

// Budget Stats Model
class BudgetStats {
  final double monthlyBudget;
  final String currency;
  final double totalSpent;
  final double todaySpent;
  final double remaining;
  final double usagePercentage;

  BudgetStats({
    required this.monthlyBudget,
    required this.currency,
    required this.totalSpent,
    required this.todaySpent,
    required this.remaining,
    required this.usagePercentage,
  });

  factory BudgetStats.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BudgetStats(
      monthlyBudget: parseDouble(json['monthly_budget']),
      currency: json['currency'] as String,
      totalSpent: parseDouble(json['total_spent']),
      todaySpent: parseDouble(json['today_spent']),
      remaining: parseDouble(json['remaining']),
      usagePercentage: parseDouble(json['usage_percentage']),
    );
  }
}

// Expense Model
// Expense Model
class Expense {
  final int id;
  final int userId;
  final String category;
  final double amount;
  final String currency;
  final String? description;
  final DateTime expenseDate;
  final String? paymentMethod;
  final String? receiptImageUrl;
  final bool isRecurring;
  final String? recurringPattern;
  final String? location;
  final String? merchant;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.currency,
    this.description,
    required this.expenseDate,
    this.paymentMethod,
    this.receiptImageUrl,
    required this.isRecurring,
    this.recurringPattern,
    this.location,
    this.merchant,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Güvenli DateTime parse
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

    return Expense(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      category: json['category'] as String? ?? 'other',
      amount: parseDouble(json['amount']),
      currency: json['currency'] as String? ?? 'TRY',
      description: json['description'] as String?,
      expenseDate: parseDateTime(json['expense_date']),
      paymentMethod: json['payment_method'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringPattern: json['recurring_pattern'] as String?,
      location: json['location'] as String?,
      merchant: json['merchant'] as String?,
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'currency': currency,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'payment_method': paymentMethod,
      'receipt_image_url': receiptImageUrl,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'location': location,
      'merchant': merchant,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Budget Request
class BudgetRequest {
  final double monthlyBudget;
  final String currency;

  BudgetRequest({
    required this.monthlyBudget,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthly_budget': monthlyBudget,
      'currency': currency,
    };
  }
}

// Expense Request
class ExpenseRequest {
  final String category;
  final double amount;
  final String currency;
  final String? description;
  final String expenseDate;
  final String? paymentMethod;
  final String? receiptImageUrl;
  final bool isRecurring;
  final String? recurringPattern;
  final String? location;
  final String? merchant;

  ExpenseRequest({
    required this.category,
    required this.amount,
    required this.currency,
    this.description,
    required this.expenseDate,
    this.paymentMethod,
    this.receiptImageUrl,
    required this.isRecurring,
    this.recurringPattern,
    this.location,
    this.merchant,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'currency': currency,
      'description': description,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      'receipt_image_url': receiptImageUrl,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'location': location,
      'merchant': merchant,
    };
  }
}

// Monthly Report Model
class MonthlyReport {
  final int month;
  final int year;
  final double totalExpenses;
  final int totalTransactions;
  final Map<String, CategoryExpense> byCategory;
  final double dailyAverage;

  MonthlyReport({
    required this.month,
    required this.year,
    required this.totalExpenses,
    required this.totalTransactions,
    required this.byCategory,
    required this.dailyAverage,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final categoryMap = <String, CategoryExpense>{};
    final byCategoryJson = json['by_category'] as Map<String, dynamic>;

    byCategoryJson.forEach((key, value) {
      categoryMap[key] = CategoryExpense.fromJson(value as Map<String, dynamic>);
    });

    return MonthlyReport(
      month: json['month'] as int,
      year: json['year'] as int,
      totalExpenses: parseDouble(json['total_expenses']),
      totalTransactions: json['total_transactions'] as int,
      byCategory: categoryMap,
      dailyAverage: parseDouble(json['daily_average']),
    );
  }
}

class CategoryExpense {
  final double total;
  final int count;

  CategoryExpense({
    required this.total,
    required this.count,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CategoryExpense(
      total: parseDouble(json['total']),
      count: json['count'] as int,
    );
  }
}