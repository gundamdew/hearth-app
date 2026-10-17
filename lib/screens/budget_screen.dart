// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/budget_models.dart';
import '../models/user_model.dart';
import '../providers/budget_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/hearth_ui.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  String _selectedType = 'Wydatek';
  String _selectedSplitType = 'shared';
  String? _selectedCategory;
  String? _selectedAssignee;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submitTransaction(List<BudgetCategory> categories, List<AppUser> users) {
    final title = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final assignee = _selectedAssignee ?? (users.isNotEmpty ? users.first.name : '');

    if (title.isNotEmpty && amount > 0 && assignee.isNotEmpty) {
      if (_selectedType == 'Wydatek' || _selectedType == 'Expense') {
        final cat = _selectedCategory ?? (categories.isNotEmpty ? categories.first.name : 'Ogólne');
        ref.read(budgetControllerProvider).addExpense(
          title,
          amount,
          cat,
          assignee,
          splitType: _selectedSplitType,
        );
      } else {
        ref.read(budgetControllerProvider).addIncome(title, amount, assignee);
      }

      _descCtrl.clear();
      _amountCtrl.clear();
      _selectedSplitType = 'shared';
      FocusScope.of(context).unfocus();
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController();

    showHearthModal(
      context: context,
      title: 'Dodaj kategorię',
      sub: 'Nowa kategoria',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nazwa kategorii',
            style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'np. Rozrywka'),
          ),
          const SizedBox(height: 16),
          Text(
            'Miesięczny limit (zł)',
            style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: limitCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmMono(fontSize: 14),
            decoration: const InputDecoration(hintText: '0'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final limit = double.tryParse(limitCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (name.isNotEmpty && limit >= 0) {
                  ref.read(budgetControllerProvider).addCategory(name, limit);
                  Navigator.pop(context);
                }
              },
              child: const Text('Dodaj kategorię'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, BudgetCategory cat, int totalCategoriesCount) {
    final ctrl = TextEditingController(text: cat.limit.round().toString());
    showHearthModal(
      context: context,
      title: 'Edytuj limit: ${cat.name}',
      sub: 'Limit wydatków',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ustaw miesięczny limit dla kategorii ${cat.name} (w zł):',
            style: GoogleFonts.instrumentSans(fontSize: 14, color: AppTheme.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmMono(fontSize: 14),
            autofocus: true,
            decoration: const InputDecoration(hintText: 'np. 500'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: totalCategoriesCount <= 1
                    ? null
                    : () {
                        ref.read(budgetControllerProvider).deleteCategory(cat.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Usunięto kategorię "${cat.name}"'),
                            backgroundColor: AppTheme.ink,
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(
                    color: totalCategoriesCount <= 1
                        ? AppTheme.line
                        : AppTheme.danger.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text('Delete'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newLimit = double.tryParse(ctrl.text.replaceAll(',', '.').trim()) ?? cat.limit;
                    ref.read(budgetControllerProvider).updateCategoryLimit(cat.id, newLimit);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          if (totalCategoriesCount <= 1) ...[
            const SizedBox(height: 12),
            Text(
              'Nie można usunąć jedynej kategorii.',
              style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ],
      ),
    );
  }

  void _showSettleUpDialog(BuildContext context, SettlementInfo settlement) {
    final debtor = settlement.debtorName ?? '';
    final creditor = settlement.creditorName ?? '';
    final amount = settlement.amount.round();

    showHearthModal(
      context: context,
      title: 'Settle Up',
      sub: 'Potwierdź rozliczenie',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record settlement of $amount USD from $debtor to $creditor?',
            style: GoogleFonts.instrumentSans(fontSize: 16, color: AppTheme.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'Zapisze to transakcję rozliczenia i wyzeruje bieżący stan zadłużenia.',
            style: GoogleFonts.instrumentSans(fontSize: 13, color: AppTheme.muted),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(budgetControllerProvider).settleUp(debtor, settlement.amount);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Zarejestrowano rozliczenie $amount USD od $debtor dla $creditor.'),
                        backgroundColor: AppTheme.moss,
                      ),
                    );
                  }
                },
                child: const Text('Potwierdź'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBadge(String splitType) {
    final isPersonal = splitType == 'personal';
    final isSettlement = splitType == 'settlement';
    final label = isSettlement ? 'Settlement' : (isPersonal ? 'Personal' : 'Shared');
    final color = isSettlement
        ? AppTheme.indigo
        : (isPersonal ? AppTheme.amber : AppTheme.moss);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    final budgetAsync = ref.watch(budgetStateProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    if (budgetAsync.isLoading || usersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.moss));
    }

    final budgetState = budgetAsync.value ?? BudgetState(categories: [], expenses: [], incomes: []);
    final users = usersAsync.value ?? [];

    if (_selectedAssignee == null && currentUser != null) {
      _selectedAssignee = currentUser.name;
    } else if (_selectedAssignee == null && users.isNotEmpty) {
      _selectedAssignee = users.first.name;
    }

    if (_selectedCategory == null && budgetState.categories.isNotEmpty) {
      _selectedCategory = budgetState.categories.first.name;
    }

    // Settlement calculations
    final settlement = calculateDebt(budgetState.expenses, users);
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase();

    // Resident Outflows & Incomes for selected month
    final flows = users.map((u) {
      final userExpenses = budgetState.expenses.where((e) => e.assignee == u.name);
      final userIncomes = budgetState.incomes.where((i) => i.assignee == u.name);
      final outTotal = userExpenses.fold(0.0, (s, e) => s + e.amount);
      final inTotal = userIncomes.fold(0.0, (s, i) => s + i.amount);
      return (user: u, out: outTotal, income: inTotal);
    }).toList();

    // Transactions list combining expenses and incomes
    final List<({
      String id,
      String title,
      double amount,
      DateTime date,
      String type,
      String assignee,
      String category,
      String splitType,
    })> allTransactions = [
      ...budgetState.expenses.map((e) => (
        id: e.id,
        title: e.title,
        amount: e.amount,
        date: e.date,
        type: 'Expense',
        assignee: e.assignee,
        category: e.category,
        splitType: e.splitType,
      )),
      ...budgetState.incomes.map((i) => (
        id: i.id,
        title: i.title,
        amount: i.amount,
        date: i.date,
        type: 'Income',
        assignee: i.assignee,
        category: 'Przychód',
        splitType: '',
      )),
    ];
    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    final monthSelector = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20, color: AppTheme.ink),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).previousMonth();
            },
          ),
          InkWell(
            onTap: () {
              ref.read(selectedMonthProvider.notifier).resetToCurrent();
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                monthLabel,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20, color: AppTheme.ink),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).nextMonth();
            },
          ),
        ],
      ),
    );

    final leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resident flow cards
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoCols = constraints.maxWidth >= 450;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: useTwoCols ? 2 : 1,
                mainAxisExtent: 88,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: flows.length,
              itemBuilder: (context, index) {
                final flow = flows[index];
                return Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      HearthAvatar(
                        name: flow.user.name,
                        color: flow.user.color,
                        avatar: flow.user.avatar,
                        size: 44,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              flow.user.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              children: [
                                Text(
                                  'Wpływy: ${flow.income.round()} zł',
                                  style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.moss),
                                ),
                                Text(
                                  'Wydatki: ${flow.out.round()} zł',
                                  style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // Categories section
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                sub: 'W tym miesiącu',
                title: 'Kategorie',
                action: TextButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.moss),
                  label: Text(
                    '+ Add category',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.moss,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (budgetState.categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Brak kategorii. Dodaj pierwszą kategorię!',
                    style: GoogleFonts.instrumentSans(color: AppTheme.muted),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: budgetState.categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final cat = budgetState.categories[index];
                    final ratio = cat.limit > 0 ? (cat.currentSpent / cat.limit) : 0.0;
                    final isOverBudget = cat.currentSpent > cat.limit;

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showEditCategoryDialog(context, cat, budgetState.categories.length),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${cat.currentSpent.round()} / ${cat.limit.round()} zł',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 12,
                                    color: isOverBudget ? AppTheme.red : AppTheme.muted,
                                    fontWeight: isOverBudget ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.muted),
                                  splashRadius: 14,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  onPressed: () => _showEditCategoryDialog(context, cat, budgetState.categories.length),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            HearthProgressBar(
                              value: ratio,
                              color: isOverBudget ? AppTheme.red : AppTheme.moss,
                              dangerThreshold: 1.0,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );

    final rightPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction Form
        FormCard(
          sub: 'Nowy wpis',
          title: 'Zarejestruj transakcję',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HearthSegmented<String>(
                value: _selectedType,
                options: const ['Wydatek', 'Przychód'],
                onChanged: (val) => setState(() => _selectedType = val),
                labelBuilder: (s) => s,
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'Wydatek' || _selectedType == 'Expense') ...[
                Text(
                  'Typ podziału',
                  style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted),
                ),
                const SizedBox(height: 6),
                HearthSegmented<String>(
                  value: _selectedSplitType,
                  options: const ['shared', 'personal'],
                  onChanged: (val) => setState(() => _selectedSplitType = val),
                  labelBuilder: (s) => s == 'shared' ? 'Shared (50/50)' : 'Personal',
                ),
                const SizedBox(height: 16),
              ],
              Text('Opis', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(hintText: 'np. Zakupy w Biedronce'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kto płacił', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                        const SizedBox(height: 6),
                        HearthSelect<String>(
                          value: _selectedAssignee ?? '',
                          items: users.map((u) => u.name).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAssignee = val);
                            }
                          },
                          labelBuilder: (name) => name,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kwota (zł)', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.dmMono(fontSize: 14),
                          decoration: const InputDecoration(hintText: '0.00'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedType == 'Wydatek' || _selectedType == 'Expense') ...[
                const SizedBox(height: 16),
                Text('Kategoria', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                const SizedBox(height: 6),
                HearthSelect<String>(
                  value: _selectedCategory ?? '',
                  items: budgetState.categories.map((c) => c.name).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                  labelBuilder: (name) => name,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _submitTransaction(budgetState.categories, users),
                  child: Text(_selectedType == 'Wydatek' ? 'Dodaj wydatek' : 'Dodaj przychód'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent Transactions Section
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: SectionHeader(sub: 'Przesuń w lewo, aby usunąć', title: 'Ostatnie transakcje'),
              ),
              if (allTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Brak zarejestrowanych transakcji.', style: AppTheme.titleStyle(fontSize: 18, color: AppTheme.muted)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allTransactions.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
                  itemBuilder: (context, index) {
                    final tx = allTransactions[index];
                    final isInc = tx.type == 'Income';
                    final sign = isInc ? '+' : '−';

                    return Dismissible(
                      key: Key(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppTheme.danger,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Usuń', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(budgetControllerProvider).deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Usunięto "${tx.title}"'),
                            backgroundColor: AppTheme.ink,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tx.title,
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (tx.type == 'Expense') ...[
                                        const SizedBox(width: 8),
                                        _buildSplitBadge(tx.splitType),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.assignee} · ${tx.category}',
                                    style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$sign${tx.amount.round()} zł',
                              style: GoogleFonts.dmMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isInc ? AppTheme.moss : AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUDŻET I ROZLICZENIA',
                style: AppTheme.microStyle,
              ),
              monthSelector,
            ],
          ),
          const SizedBox(height: 16),

          // Settlement Balance Banner
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.sage.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SETTLEMENT BALANCE',
                        style: AppTheme.microStyle.copyWith(color: AppTheme.moss.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        settlement.message,
                        style: AppTheme.titleStyle(fontSize: isDesktop ? 28 : 22, color: AppTheme.moss),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: settlement.amount > 0 && settlement.debtorName != null
                      ? () => _showSettleUpDialog(context, settlement)
                      : null,
                  child: const Text('Settle Up'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Multi-column or single column
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: leftPanel),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: rightPanel),
              ],
            ),
          ] else ...[
            leftPanel,
            const SizedBox(height: 32),
            rightPanel,
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}