// A simple class to represent an income entry
class IncomeEntry {
  final String id; // Unique ID for each entry
  final double amount;
  final String source;
  final String reason;
  final DateTime date;
  final String currency;

  IncomeEntry({
    required this.id,
    required this.amount,
    required this.source,
    required this.reason,
    required this.date,
    required this.currency,
  });

  // Factory constructor to create an IncomeEntry from a JSON object
  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    return IncomeEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      reason: json['reason'] as String,
      date: DateTime.parse(json['date'] as String),
      currency: json['currency'] as String,
    );
  }

  // Method to convert an IncomeEntry instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'source': source,
      'reason': reason,
      'date': date.toIso8601String(),
      'currency': currency,
    };
  }
}

// A simple class to represent an expense entry
class ExpenseEntry {
  final String id; // Unique ID for each entry
  final double amount;
  final String source; 
  final String reason;
  final DateTime date;
  final String currency;

  ExpenseEntry({
    required this.id,
    required this.amount,
    required this.source,
    required this.reason,
    required this.date,
    required this.currency,
  });

  // Factory constructor to create an ExpenseEntry from a JSON object
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      reason: json['reason'] as String,
      date: DateTime.parse(json['date'] as String),
      currency: json['currency'] as String,
    );
  }

  // Method to convert an ExpenseEntry instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'source': source,
      'reason': reason,
      'date': date.toIso8601String(),
      'currency': currency,
    };
  }
}

// A class to represent a savings goal
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime creationDate;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.currency,
    required this.creationDate,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      creationDate: DateTime.parse(json['creationDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'creationDate': creationDate.toIso8601String(),
    };
  }
}
