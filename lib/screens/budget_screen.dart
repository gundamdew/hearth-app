import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/budget_models.dart';
import '../providers/budget_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart'; // НОВЫЙ ИМПОРТ

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

  void _showEditLimitDialog(BuildContext context, WidgetRef ref, BudgetCategory cat) {
    final controller = TextEditingController(text: cat.limit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${cat.name} Limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter new limit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? cat.limit;
              ref.read(budgetControllerProvider).updateCategoryLimit(cat.id, newLimit);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetStateProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider); // Получаем текущего пользователя

    if (budgetAsync is AsyncLoading || usersAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.mossGreen));
    }

    final budgetState = budgetAsync.value!;
    final users = usersAsync.value!;
    
    final debtMessage = calculateDebt(budgetState.expenses, users);

    // Интеллектуальный выбор пользователя: ставим того, кто вошел по PIN
    if (_selectedAssignee == null && currentUser != null && users.any((u) => u.name == currentUser.name)) {
      _selectedAssignee = currentUser.name;
    } else if (_selectedAssignee == null && users.isNotEmpty) {
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
                            Row(
                              children: [
                                Text('${cat.currentSpent.toStringAsFixed(0)} / ${cat.limit.toStringAsFixed(0)} USD', style: GoogleFonts.dmMono(fontSize: 14, color: AppTheme.textLight)),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16, color: AppTheme.textLight),
                                  onPressed: () => _showEditLimitDialog(context, ref, cat),
                                )
                              ],
                            ),
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
        margin: const EdgeInsets.only(right: 16),
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