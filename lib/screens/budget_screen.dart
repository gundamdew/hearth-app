import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/budget_models.dart';
import '../providers/budget_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  String? _selectedAssignee;
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
        ref.read(budgetControllerProvider).addExpense(title, amount, _selectedCategory!, _selectedAssignee!);
      } else if (_transactionType == 'Income') {
        ref.read(budgetControllerProvider).addIncome(title, amount, _selectedAssignee!);
      }
      
      _titleController.clear();
      _amountController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final budgetAsync = ref.watch(budgetStateProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider); 

    if (budgetAsync.isLoading || usersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.mossGreen));
    }

    final budgetState = budgetAsync.value ?? BudgetState(categories: [], expenses: [], incomes: []);
    final users = usersAsync.value ?? [];
    final debtMessage = calculateDebt(budgetState.expenses, users);

    if (_selectedAssignee == null && currentUser != null && users.any((u) => u.name == currentUser.name)) {
      _selectedAssignee = currentUser.name;
    } else if (_selectedAssignee == null && users.isNotEmpty) {
      _selectedAssignee = users.first.name;
    }

    Widget categoriesList = ListView.separated(
      shrinkWrap: isMobile,
      physics: isMobile ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
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
    );

    Widget leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppTheme.sage.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.sage)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SETTLEMENT BALANCE', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(debtMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: users.map((user) {
              final income = budgetState.incomes.where((i) => i.assignee == user.name).fold(0.0, (s, i) => s + i.amount);
              final expense = budgetState.expenses.where((e) => e.assignee == user.name).fold(0.0, (s, e) => s + e.amount);
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: user.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: user.color)),
                    const SizedBox(height: 8),
                    Text('In: \$${income.toStringAsFixed(0)}', style: GoogleFonts.dmMono(fontSize: 14)),
                    Text('Out: \$${expense.toStringAsFixed(0)}', style: GoogleFonts.dmMono(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 48),
        Text('Categories', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
        const SizedBox(height: 24),
        isMobile ? categoriesList : Expanded(child: categoriesList),
      ],
    );

    Widget rightPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log a transaction', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'Expense', label: Text('Expense')), ButtonSegment(value: 'Income', label: Text('Income'))],
                selected: {_transactionType},
                onSelectionChanged: (val) => setState(() { _transactionType = val.first; if (_transactionType == 'Income') _selectedCategory = null; }),
              ),
              const SizedBox(height: 16),
              TextField(controller: _titleController, decoration: InputDecoration(hintText: 'Description', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2))))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.cardBackground, border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedAssignee,
                          items: users.map((u) => DropdownMenuItem(value: u.name, child: Text(u.name))).toList(),
                          onChanged: (val) => setState(() => _selectedAssignee = val),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: '0.00', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2))))),
                  ),
                ],
              ),
              if (_transactionType == 'Expense') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.cardBackground, border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedCategory,
                      hint: const Text('Category'),
                      items: budgetState.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _submitTransaction, child: const Text('Add transaction')),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Text('RECENT EXPENSES', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
        const SizedBox(height: 16),
        isMobile
          ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
            )
          : Expanded(
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
    );

    return isMobile 
      ? SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftPanel, const SizedBox(height: 48), rightPanel]))
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: leftPanel), const SizedBox(width: 48), Expanded(flex: 4, child: rightPanel)]);
  }
}