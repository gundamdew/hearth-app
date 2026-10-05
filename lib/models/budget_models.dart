class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
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

  BudgetCategory copyWith({
    String? id,
    String? name,
    double? limit,
    double? currentSpent,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      limit: limit ?? this.limit,
      currentSpent: currentSpent ?? this.currentSpent,
    );
  }
}

class BudgetState {
  final List<BudgetCategory> categories;
  final List<Expense> expenses;

  BudgetState({
    required this.categories,
    required this.expenses,
  });

  BudgetState copyWith({
    List<BudgetCategory>? categories,
    List<Expense>? expenses,
  }) {
    return BudgetState(
      categories: categories ?? this.categories,
      expenses: expenses ?? this.expenses,
    );
  }
}