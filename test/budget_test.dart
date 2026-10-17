import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chata/models/budget_models.dart';
import 'package:smart_chata/models/user_model.dart';
import 'package:smart_chata/providers/budget_provider.dart';

void main() {
  group('Flexible Envelopes + Split Math Unit Tests', () {
    final user1 = AppUser(
      id: '1',
      name: 'Vladimir',
      pinCode: '1111',
      color: Colors.blue,
    );
    final user2 = AppUser(
      id: '2',
      name: 'Ular',
      pinCode: '2222',
      color: Colors.green,
    );
    final users = [user1, user2];

    test('Debt calculation with shared expenses: 50/50 split', () {
      final expenses = [
        Expense(
          id: 'e1',
          title: 'Groceries',
          amount: 200.0,
          category: 'Groceries',
          date: DateTime.now(),
          assignee: 'Vladimir',
          splitType: 'shared',
        ),
      ];

      final settlement = calculateDebt(expenses, users);
      expect(settlement.isBalanced, false);
      expect(settlement.debtorName, 'Ular');
      expect(settlement.creditorName, 'Vladimir');
      expect(settlement.amount, 100.0);
      expect(settlement.message, 'Ular owes Vladimir 100 USD');
    });

    test('Personal expenses are ignored in debt calculations', () {
      final expenses = [
        Expense(
          id: 'e1',
          title: 'Groceries',
          amount: 200.0,
          category: 'Groceries',
          date: DateTime.now(),
          assignee: 'Vladimir',
          splitType: 'shared',
        ),
        Expense(
          id: 'e2',
          title: 'Vladimir shoes',
          amount: 300.0,
          category: 'Household',
          date: DateTime.now(),
          assignee: 'Vladimir',
          splitType: 'personal',
        ),
      ];

      final settlement = calculateDebt(expenses, users);
      expect(settlement.isBalanced, false);
      expect(settlement.debtorName, 'Ular');
      expect(settlement.creditorName, 'Vladimir');
      // Debt should still be 100, not affected by the 300 personal expense
      expect(settlement.amount, 100.0);
      expect(settlement.message, 'Ular owes Vladimir 100 USD');
    });

    test('Settlement transaction zeroes the debt balance', () {
      final expenses = [
        Expense(
          id: 'e1',
          title: 'Groceries',
          amount: 200.0,
          category: 'Groceries',
          date: DateTime.now(),
          assignee: 'Vladimir',
          splitType: 'shared',
        ),
        Expense(
          id: 'e2',
          title: 'Settlement transfer',
          amount: 100.0,
          category: 'Settlement',
          date: DateTime.now(),
          assignee: 'Ular',
          splitType: 'settlement',
        ),
      ];

      final settlement = calculateDebt(expenses, users);
      expect(settlement.isBalanced, true);
      expect(settlement.amount, 0.0);
      expect(settlement.message, 'Contributions are perfectly balanced.');
    });

    test('Equal contributions result in balanced state', () {
      final expenses = [
        Expense(
          id: 'e1',
          title: 'Groceries',
          amount: 150.0,
          category: 'Groceries',
          date: DateTime.now(),
          assignee: 'Vladimir',
          splitType: 'shared',
        ),
        Expense(
          id: 'e2',
          title: 'Utilities',
          amount: 150.0,
          category: 'Utilities',
          date: DateTime.now(),
          assignee: 'Ular',
          splitType: 'shared',
        ),
      ];

      final settlement = calculateDebt(expenses, users);
      expect(settlement.isBalanced, true);
      expect(settlement.amount, 0.0);
      expect(settlement.message, 'Contributions are perfectly balanced.');
    });

    test('SelectedMonthNotifier next, previous, reset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(selectedMonthProvider);

      container.read(selectedMonthProvider.notifier).nextMonth();
      expect(container.read(selectedMonthProvider).month, (initial.month % 12) + 1);

      container.read(selectedMonthProvider.notifier).previousMonth();
      expect(container.read(selectedMonthProvider).month, initial.month);

      container.read(selectedMonthProvider.notifier).previousMonth();
      final prevMonthExpected = initial.month == 1 ? 12 : initial.month - 1;
      expect(container.read(selectedMonthProvider).month, prevMonthExpected);

      container.read(selectedMonthProvider.notifier).resetToCurrent();
      expect(container.read(selectedMonthProvider).year, initial.year);
      expect(container.read(selectedMonthProvider).month, initial.month);
    });
  });
}
