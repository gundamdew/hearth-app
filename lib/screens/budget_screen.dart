import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/budget_models.dart';
import '../providers/budget_provider.dart';
import '../providers/users_provider.dart'; // ДОБАВИТЬ ИМПОРТ

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  String? _selectedAssignee; // Больше не 'Maya' по умолчанию
  String _transactionType = 'Expense';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitTransaction() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (title.isNotEmpty && amount > 0 && _selectedAssignee != null) {
      if (_transactionType == 'Expense' && _selectedCategory != null) {
        ref.read(budgetProvider.notifier).addExpense(title, amount, _selectedCategory!, _selectedAssignee!);
      } else if (_transactionType == 'Income') {
        ref.read(budgetProvider.notifier).addIncome(title, amount, _selectedAssignee!);
      }
      
      _titleController.clear();
      _amountController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final users = ref.watch(usersProvider);
    
    // Динамический расчет долга
    final debtMessage = ref.read(budgetProvider.notifier).calculateDebt(users);

    // Защита от отсутствия выбранного пользователя или его удаления
    if (users.isNotEmpty && (_selectedAssignee == null || !users.any((u) => u.name == _selectedAssignee))) {
      _selectedAssignee = users.first.name;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.sage.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.sage),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SETTLEMENT BALANCE', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text(debtMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mossGreen),
                      child: const Text('Settle Up'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Динамическая генерация карточек статистики для каждого пользователя
              Row(
                children: users.map((user) {
                  final income = budgetState.incomes.where((i) => i.assignee == user.name).fold(0.0, (s, i) => s + i.amount);
                  final expense = budgetState.expenses.where((e) => e.assignee == user.name).fold(0.0, (s, e) => s + e.amount);
                  return _buildUserStatCard(user.name, income, expense, user.color);
                }).toList(),
              ),
              
              const SizedBox(height: 48),
              Text('Categories', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: budgetState.categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final cat = budgetState.categories[index];
                    final progress = cat.limit > 0 ? (cat.currentSpent / cat.limit).clamp(0.0, 1.0) : 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('${cat.currentSpent.toStringAsFixed(0)} / ${cat.limit.toStringAsFixed(0)} USD', style: GoogleFonts.dmMono(fontSize: 14, color: AppTheme.textLight)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: progress, backgroundColor: AppTheme.textLight.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation(AppTheme.mossGreen), minHeight: 4),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),

        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log a transaction', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                    const SizedBox(height: 24),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Expense', label: Text('Expense')),
                        ButtonSegment(value: 'Income', label: Text('Income')),
                      ],
                      selected: {_transactionType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _transactionType = newSelection.first;
                          if (_transactionType == 'Income') _selectedCategory = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(hintText: 'Description', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)))),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          // Динамический выпадающий список пользователей
                          child: DropdownButtonFormField<String>(
                            value: _selectedAssignee,
                            decoration: InputDecoration(enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)))),
                            items: users.map<DropdownMenuItem<String>>((u) {
                              return DropdownMenuItem<String>(value: u.name, child: Text(u.name));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedAssignee = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(hintText: '0.00', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)))),
                          ),
                        ),
                      ],
                    ),
                    if (_transactionType == 'Expense') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: _selectedCategory,
                        hint: const Text('Category'),
                        decoration: InputDecoration(enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)))),
                        items: budgetState.categories.map<DropdownMenuItem<String?>>((c) {
                          return DropdownMenuItem<String?>(value: c.name, child: Text(c.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitTransaction, child: const Text('Add transaction'))),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text('RECENT EXPENSES', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: budgetState.expenses.length,
                  itemBuilder: (context, index) {
                    final exp = budgetState.expenses[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${exp.assignee} · ${exp.category}'),
                      trailing: Text('${exp.amount.toStringAsFixed(0)} USD', style: GoogleFonts.dmMono(fontSize: 16)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatCard(String name, double income, double expense, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16), // Отступ между карточками
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text('In: \$${income.toStringAsFixed(0)}', style: GoogleFonts.dmMono(fontSize: 14)),
            Text('Out: \$${expense.toStringAsFixed(0)}', style: GoogleFonts.dmMono(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}