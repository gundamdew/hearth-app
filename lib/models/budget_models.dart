import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementInfo {
  final String? debtorName;
  final String? creditorName;
  final double amount;
  final String message;

  const SettlementInfo({
    this.debtorName,
    this.creditorName,
    required this.amount,
    required this.message,
  });

  bool get isBalanced => amount < 0.5 || debtorName == null || creditorName == null;
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String assignee;
  final String splitType;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.assignee,
    this.splitType = 'shared',
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? assignee,
    String? splitType,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      assignee: assignee ?? this.assignee,
      splitType: splitType ?? this.splitType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'assignee': assignee,
      'splitType': splitType,
    };
  }

  factory Expense.fromFirestore(Map<String, dynamic> map, String documentId) {
    return Expense(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignee: map['assignee'] ?? '',
      splitType: (map['splitType'] as String?) ?? 'shared',
    );
  }
}

class Income {
  final String id;
  final String title;
  final double amount;
  final String assignee;
  final DateTime date;

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.assignee,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'assignee': assignee,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Income.fromFirestore(Map<String, dynamic> map, String documentId) {
    return Income(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      assignee: map['assignee'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BudgetCategory {
  final String id;
  final String name;
  final double limit;
  final double currentSpent;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.limit,
    this.currentSpent = 0.0,
  });

  BudgetCategory copyWith({String? id, String? name, double? limit, double? currentSpent}) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      limit: limit ?? this.limit,
      currentSpent: currentSpent ?? this.currentSpent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'limit': limit,
    };
  }

  factory BudgetCategory.fromFirestore(Map<String, dynamic> map, String documentId) {
    return BudgetCategory(
      id: documentId,
      name: map['name'] ?? '',
      limit: (map['limit'] ?? 0).toDouble(),
      // currentSpent вычисляется динамически на основе расходов, поэтому в БД не сохраняем
      currentSpent: 0.0,
    );
  }
}

class BudgetState {
  final List<BudgetCategory> categories;
  final List<Expense> expenses;
  final List<Income> incomes;

  BudgetState({
    required this.categories,
    required this.expenses,
    required this.incomes,
  });

  BudgetState copyWith({
    List<BudgetCategory>? categories,
    List<Expense>? expenses,
    List<Income>? incomes,
  }) {
    return BudgetState(
      categories: categories ?? this.categories,
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
    );
  }
}