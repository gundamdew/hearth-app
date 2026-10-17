import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_models.dart';
import '../models/user_model.dart';

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void resetToCurrent() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return FirebaseFirestore.instance.collection('budget_transactions').snapshots().map((snapshot) {
    final exps = snapshot.docs
        .where((doc) => doc.data()['type'] == 'expense')
        .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
        .toList();
    exps.sort((a, b) => b.date.compareTo(a.date));
    return exps;
  });
});

final incomesProvider = StreamProvider<List<Income>>((ref) {
  return FirebaseFirestore.instance.collection('budget_transactions').snapshots().map((snapshot) {
    final incs = snapshot.docs
        .where((doc) => doc.data()['type'] == 'income')
        .map((doc) => Income.fromFirestore(doc.data(), doc.id))
        .toList();
    incs.sort((a, b) => b.date.compareTo(a.date));
    return incs;
  });
});

final categoriesProvider = StreamProvider<List<BudgetCategory>>((ref) {
  return FirebaseFirestore.instance.collection('budget_categories').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => BudgetCategory.fromFirestore(doc.data(), doc.id)).toList(),
  );
});

final budgetStateProvider = Provider<AsyncValue<BudgetState>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final incomes = ref.watch(incomesProvider);
  final categories = ref.watch(categoriesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  if (expenses.isLoading || incomes.isLoading || categories.isLoading) {
    return const AsyncLoading();
  }

  if (expenses.hasError) {
    return AsyncError(expenses.error!, expenses.stackTrace!);
  }
  if (incomes.hasError) {
    return AsyncError(incomes.error!, incomes.stackTrace!);
  }
  if (categories.hasError) {
    return AsyncError(categories.error!, categories.stackTrace!);
  }

  final cats = categories.value ?? [];
  final allExps = expenses.value ?? [];
  final allIncs = incomes.value ?? [];

  // Filter expenses and incomes by selected month
  final monthExps = allExps.where((e) {
    return e.date.year == selectedMonth.year && e.date.month == selectedMonth.month;
  }).toList();

  final monthIncs = allIncs.where((i) {
    return i.date.year == selectedMonth.year && i.date.month == selectedMonth.month;
  }).toList();

  // Sum only expenses for selectedMonth, excluding settlement
  final updatedCats = cats.map((cat) {
    final spent = monthExps
        .where((e) => e.category == cat.name && e.splitType != 'settlement')
        .fold(0.0, (total, e) => total + e.amount);
    return cat.copyWith(currentSpent: spent);
  }).toList();

  return AsyncData(BudgetState(
    categories: updatedCats,
    expenses: monthExps,
    incomes: monthIncs,
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
        'Groceries': 800.0,
        'Rent': 1650.0,
        'Utilities': 200.0,
        'Household': 100.0,
        'Transport': 150.0,
        'Eating out': 300.0,
      };
      defaults.forEach((name, limit) {
        final doc = _db.collection('budget_categories').doc();
        batch.set(doc, {'name': name, 'limit': limit});
      });
      await batch.commit();
    }
  }

  Future<void> addExpense(
    String title,
    double amount,
    String categoryName,
    String assignee, {
    String splitType = 'shared',
  }) async {
    await _db.collection('budget_transactions').add({
      'type': 'expense',
      'title': title,
      'amount': amount,
      'category': categoryName,
      'date': Timestamp.now(),
      'assignee': assignee,
      'splitType': splitType,
    });
  }

  Future<void> addIncome(String title, double amount, String assignee) async {
    await _db.collection('budget_transactions').add({
      'type': 'income',
      'title': title,
      'amount': amount,
      'assignee': assignee,
      'date': Timestamp.now(),
    });
  }

  Future<void> updateCategoryLimit(String categoryId, double newLimit) async {
    await _db.collection('budget_categories').doc(categoryId).update({'limit': newLimit});
  }

  Future<void> addCategory(String name, double limit) async {
    await _db.collection('budget_categories').add({
      'name': name.trim(),
      'limit': limit,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('budget_categories').doc(categoryId).delete();
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _db.collection('budget_transactions').doc(transactionId).delete();
  }

  Future<void> settleUp(String debtorName, double amount) async {
    await _db.collection('budget_transactions').add({
      'type': 'expense',
      'splitType': 'settlement',
      'title': 'Settlement transfer',
      'category': 'Settlement',
      'assignee': debtorName,
      'amount': amount,
      'date': Timestamp.now(),
    });
  }
}

SettlementInfo calculateDebt(List<Expense> expenses, List<AppUser> users) {
  if (users.isEmpty) {
    return const SettlementInfo(
      debtorName: null,
      creditorName: null,
      amount: 0.0,
      message: 'No residents found.',
    );
  }
  if (users.length == 1) {
    return const SettlementInfo(
      debtorName: null,
      creditorName: null,
      amount: 0.0,
      message: 'Contributions are perfectly balanced.',
    );
  }

  final sharedExpenses = expenses.where((e) => e.splitType == 'shared').toList();
  final totalShared = sharedExpenses.fold(0.0, (total, e) => total + e.amount);
  final fairShare = totalShared / users.length;

  final Map<String, double> sharedPaid = {for (var u in users) u.name: 0.0};
  for (final exp in sharedExpenses) {
    if (sharedPaid.containsKey(exp.assignee)) {
      sharedPaid[exp.assignee] = (sharedPaid[exp.assignee] ?? 0.0) + exp.amount;
    }
  }

  final Map<String, double> settlementsPaid = {for (var u in users) u.name: 0.0};
  for (final exp in expenses.where((e) => e.splitType == 'settlement')) {
    if (settlementsPaid.containsKey(exp.assignee)) {
      settlementsPaid[exp.assignee] = (settlementsPaid[exp.assignee] ?? 0.0) + exp.amount;
    }
  }

  if (users.length == 2) {
    final u1 = users[0].name;
    final u2 = users[1].name;

    final net1 = (sharedPaid[u1]! - fairShare) + settlementsPaid[u1]! - settlementsPaid[u2]!;
    final net2 = (sharedPaid[u2]! - fairShare) + settlementsPaid[u2]! - settlementsPaid[u1]!;

    if (net1 < -0.5) {
      final amount = net1.abs();
      return SettlementInfo(
        debtorName: u1,
        creditorName: u2,
        amount: amount,
        message: '$u1 owes $u2 ${amount.round()} USD',
      );
    } else if (net2 < -0.5) {
      final amount = net2.abs();
      return SettlementInfo(
        debtorName: u2,
        creditorName: u1,
        amount: amount,
        message: '$u2 owes $u1 ${amount.round()} USD',
      );
    } else {
      return const SettlementInfo(
        debtorName: null,
        creditorName: null,
        amount: 0.0,
        message: 'Contributions are perfectly balanced.',
      );
    }
  }

  final Map<String, double> balances = {};
  for (final u in users) {
    balances[u.name] = (sharedPaid[u.name]! - fairShare) + settlementsPaid[u.name]!;
  }

  final totalSettlement = settlementsPaid.values.fold(0.0, (s, a) => s + a);
  if (totalSettlement > 0) {
    double remainingToDeduct = totalSettlement;
    final creditorNames = users
        .where((u) => sharedPaid[u.name]! > fairShare)
        .map((u) => u.name)
        .toList();
    creditorNames.sort((a, b) => (sharedPaid[b]!).compareTo(sharedPaid[a]!));
    for (final cName in creditorNames) {
      final canDeduct = balances[cName] ?? 0.0;
      if (canDeduct > 0) {
        final deduction = remainingToDeduct > canDeduct ? canDeduct : remainingToDeduct;
        balances[cName] = balances[cName]! - deduction;
        remainingToDeduct -= deduction;
        if (remainingToDeduct <= 0) {
          break;
        }
      }
    }
  }

  String? debtor;
  String? creditor;
  double minBal = 0.0;
  double maxBal = 0.0;

  for (final entry in balances.entries) {
    if (entry.value < minBal) {
      minBal = entry.value;
      debtor = entry.key;
    }
    if (entry.value > maxBal) {
      maxBal = entry.value;
      creditor = entry.key;
    }
  }

  final owed = (debtor != null && creditor != null) ? minBal.abs().clamp(0.0, maxBal) : 0.0;
  if (owed < 0.5 || debtor == null || creditor == null) {
    return const SettlementInfo(
      debtorName: null,
      creditorName: null,
      amount: 0.0,
      message: 'Contributions are perfectly balanced.',
    );
  }

  return SettlementInfo(
    debtorName: debtor,
    creditorName: creditor,
    amount: owed,
    message: '$debtor owes $creditor ${owed.round()} USD',
  );
}