import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_models.dart';
import '../models/user_model.dart';

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return FirebaseFirestore.instance.collection('budget_transactions')
    .where('type', isEqualTo: 'expense')
    .orderBy('date', descending: true)
    .snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => Expense.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final incomesProvider = StreamProvider<List<Income>>((ref) {
  return FirebaseFirestore.instance.collection('budget_transactions')
    .where('type', isEqualTo: 'income')
    .orderBy('date', descending: true)
    .snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => Income.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final categoriesProvider = StreamProvider<List<BudgetCategory>>((ref) {
  return FirebaseFirestore.instance.collection('budget_categories').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => BudgetCategory.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final budgetStateProvider = Provider<AsyncValue<BudgetState>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final incomes = ref.watch(incomesProvider);
  final categories = ref.watch(categoriesProvider);

  if (expenses is AsyncLoading || incomes is AsyncLoading || categories is AsyncLoading) {
    return const AsyncLoading();
  }

  if (expenses is AsyncError || incomes is AsyncError || categories is AsyncError) {
    return AsyncError('Error loading budget', StackTrace.current);
  }

  final cats = categories.value ?? [];
  final exps = expenses.value ?? [];
  
  final updatedCats = cats.map((cat) {
    final spent = exps.where((e) => e.category == cat.name).fold(0.0, (total, e) => total + e.amount);
    return cat.copyWith(currentSpent: spent);
  }).toList();

  return AsyncData(BudgetState(
    categories: updatedCats,
    expenses: exps,
    incomes: incomes.value ?? [],
  ));
});

final budgetControllerProvider = Provider((ref) => BudgetController());

class BudgetController {
  final _db = FirebaseFirestore.instance;

  Future<void> initializeCategories() async {
    final snap = await _db.collection('budget_categories').limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _db.batch();
      final defaults = {
        'Groceries': 800.0, 'Rent': 1650.0, 'Utilities': 200.0,
        'Household': 100.0, 'Transport': 150.0, 'Eating out': 300.0
      };
      defaults.forEach((name, limit) {
        final doc = _db.collection('budget_categories').doc();
        batch.set(doc, {'name': name, 'limit': limit});
      });
      await batch.commit();
    }
  }

  Future<void> addExpense(String title, double amount, String categoryName, String assignee) async {
    await _db.collection('budget_transactions').add({
      'type': 'expense',
      'title': title,
      'amount': amount,
      'category': categoryName,
      'date': FieldValue.serverTimestamp(),
      'assignee': assignee,
    });
  }

  Future<void> addIncome(String title, double amount, String assignee) async {
    await _db.collection('budget_transactions').add({
      'type': 'income',
      'title': title,
      'amount': amount,
      'assignee': assignee,
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategoryLimit(String id, double newLimit) async {
    await _db.collection('budget_categories').doc(id).update({'limit': newLimit});
  }
}

String calculateDebt(List<Expense> expenses, List<AppUser> users) {
  if (users.isEmpty) return 'No residents added.';
  if (users.length == 1) return 'Contributions are balanced.';

  final totalExpenses = expenses.fold(0.0, (total, e) => total + e.amount);
  final fairShare = totalExpenses / users.length;

  List<String> debtors = [];
  for (var user in users) {
    final spent = expenses
        .where((e) => e.assignee == user.name)
        .fold(0.0, (total, e) => total + e.amount);
    
    if (spent < fairShare - 0.5) { 
      debtors.add('${user.name} owes \$${(fairShare - spent).toStringAsFixed(0)}');
    }
  }

  if (debtors.isEmpty) return 'Contributions are perfectly balanced.';
  return debtors.join('  ·  ');
}