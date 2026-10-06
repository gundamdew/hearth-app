import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_models.dart';
import '../models/user_model.dart';

class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    return BudgetState(
      // Оставляем категории, но сбрасываем текущие траты до 0
      categories: [
        BudgetCategory(id: 'cat1', name: 'Groceries', limit: 800, currentSpent: 0.0),
        BudgetCategory(id: 'cat2', name: 'Rent', limit: 1650, currentSpent: 0.0),
        BudgetCategory(id: 'cat3', name: 'Utilities', limit: 200, currentSpent: 0.0),
        BudgetCategory(id: 'cat4', name: 'Household', limit: 100, currentSpent: 0.0),
        BudgetCategory(id: 'cat5', name: 'Transport', limit: 150, currentSpent: 0.0),
        BudgetCategory(id: 'cat6', name: 'Eating out', limit: 300, currentSpent: 0.0),
      ],
      // Очищаем историю транзакций
      expenses: [],
      incomes: [],
    );
  }

  void addExpense(String title, double amount, String categoryName, String assignee) {
    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: categoryName,
      date: DateTime.now(),
      assignee: assignee,
    );

    final updatedCategories = state.categories.map((cat) {
      if (cat.name == categoryName) {
        return cat.copyWith(currentSpent: cat.currentSpent + amount);
      }
      return cat;
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      expenses: [newExpense, ...state.expenses],
    );
  }

  void addIncome(String title, double amount, String assignee) {
    final newIncome = Income(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      assignee: assignee,
      date: DateTime.now(),
    );
    state = state.copyWith(incomes: [newIncome, ...state.incomes]);
  }

  String calculateDebt(List<AppUser> users) {
    if (users.isEmpty) return 'No residents added.';
    if (users.length == 1) return 'Contributions are balanced.';

    final totalExpenses = state.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final fairShare = totalExpenses / users.length;

    List<String> debtors = [];
    for (var user in users) {
      final spent = state.expenses
          .where((e) => e.assignee == user.name)
          .fold(0.0, (s, e) => s + e.amount);
      
      if (spent < fairShare - 0.5) { 
        debtors.add('${user.name} owes \$${(fairShare - spent).toStringAsFixed(0)}');
      }
    }

    if (debtors.isEmpty) return 'Contributions are perfectly balanced.';
    return debtors.join('  ·  ');
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(() => BudgetNotifier());