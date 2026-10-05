import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_models.dart';

class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    final initialCategories = [
      BudgetCategory(id: 'cat1', name: 'Groceries', limit: 800, currentSpent: 450),
      BudgetCategory(id: 'cat2', name: 'Rent', limit: 1650, currentSpent: 1650),
      BudgetCategory(id: 'cat3', name: 'Utilities', limit: 200, currentSpent: 185), 
      BudgetCategory(id: 'cat4', name: 'Household', limit: 100, currentSpent: 110), 
      BudgetCategory(id: 'cat5', name: 'Transport', limit: 150, currentSpent: 40),
      BudgetCategory(id: 'cat6', name: 'Eating out', limit: 300, currentSpent: 120),
    ];

    final initialExpenses = [
      Expense(
        id: 'e1',
        title: 'Trader Joe\'s weekly shop',
        amount: 87.0,
        category: 'Groceries',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'e2',
        title: 'Electric - PG&E',
        amount: 84.0,
        category: 'Utilities',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Expense(
        id: 'e3',
        title: 'October rent',
        amount: 1650.0,
        category: 'Rent',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    return BudgetState(
      categories: initialCategories,
      expenses: initialExpenses,
    );
  }

  void addExpense(String title, double amount, String categoryName) {
    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: categoryName,
      date: DateTime.now(),
    );

    final updatedCategories = state.categories.map((cat) {
      if (cat.name == categoryName) {
        return cat.copyWith(currentSpent: cat.currentSpent + amount);
      }
      return cat;
    }).toList();

    final updatedExpenses = [newExpense, ...state.expenses];

    state = state.copyWith(
      categories: updatedCategories,
      expenses: updatedExpenses,
    );
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(() {
  return BudgetNotifier();
});
