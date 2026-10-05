import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (title.isNotEmpty && amount > 0 && _selectedCategory != null) {
      ref.read(budgetProvider.notifier).addExpense(title, amount, _selectedCategory!);
      _titleController.clear();
      _amountController.clear();
      setState(() {
        _selectedCategory = null;
      });
      FocusScope.of(context).unfocus();
    }
  }

  Color _getCategoryColor(double spent, double limit) {
    if (limit == 0) return AppTheme.mossGreen;
    final ratio = spent / limit;
    if (ratio < 0.8) {
      return AppTheme.mossGreen;
    } else if (ratio < 1.0) {
      return AppTheme.amber;
    } else {
      return AppTheme.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final categories = budgetState.categories;
    final expenses = budgetState.expenses;

    final totalLimit = categories.fold(0.0, (sum, cat) => sum + cat.limit);
    final totalSpent = categories.fold(0.0, (sum, cat) => sum + cat.currentSpent);
    final remaining = totalLimit - totalSpent;

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
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL FOR THE MONTH',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${totalLimit.toStringAsFixed(0)} USD',
                          style: GoogleFonts.dmMono(
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Remaining',
                              style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                            ),
                            Text(
                              '${remaining.toStringAsFixed(0)} USD',
                              style: GoogleFonts.dmMono(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: remaining >= 0 ? AppTheme.mossGreen : AppTheme.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: (totalSpent / totalLimit).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.textLight.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(
                        _getCategoryColor(totalSpent, totalLimit),
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final progress = (cat.currentSpent / cat.limit).clamp(0.0, 1.0);
                    final barColor = _getCategoryColor(cat.currentSpent, cat.limit);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cat.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${cat.currentSpent.toStringAsFixed(0)} / ${cat.limit.toStringAsFixed(0)} USD',
                              style: GoogleFonts.dmMono(
                                fontSize: 14,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.textLight.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(barColor),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
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
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log an expense',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'What was it for?',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedCategory,
                                hint: const Text('Category', style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
                                items: categories.map<DropdownMenuItem<String>>((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat.name,
                                    child: Text(cat.name),
                                  );
                                }).toList(),
                                onChanged: (String? val) {
                                  setState(() {
                                    _selectedCategory = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _amountController,
                            hint: '0.00',
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitExpense,
                        child: const Text('Add expense'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'RECENT',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: expenses.length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppTheme.textLight.withValues(alpha: 0.1),
                    height: 24,
                  ),
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('yyyy-MM-dd').format(exp.date)}  ·  ${exp.category}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${exp.amount.toStringAsFixed(0)} USD',
                          style: GoogleFonts.dmMono(
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.mossGreen),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}