// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        ref.read(budgetControllerProvider).addExpense(title, amount, cat, assignee);
      } else {
        ref.read(budgetControllerProvider).addIncome(title, amount, assignee);
      }

      _descCtrl.clear();
      _amountCtrl.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showEditLimitDialog(BuildContext context, BudgetCategory cat) {
    final ctrl = TextEditingController(text: cat.limit.round().toString());
    showHearthModal(
      context: context,
      title: 'Edytuj limit dla: ${cat.name}',
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
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'np. 500'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final newLimit = double.tryParse(ctrl.text.trim()) ?? cat.limit;
                ref.read(budgetControllerProvider).updateCategoryLimit(cat.id, newLimit);
                Navigator.pop(context);
              },
              child: const Text('Zapisz limit'),
            ),
          ),
        ],
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
    final debtSummary = calculateDebt(budgetState.expenses, users);
    final isBalanced = debtSummary.contains('zrównoważone') || debtSummary.contains('Brak') || debtSummary.contains('balanced');

    // Resident Outflows & Incomes
    final flows = users.map((u) {
      final userExpenses = budgetState.expenses.where((e) => e.assignee == u.name);
      final userIncomes = budgetState.incomes.where((i) => i.assignee == u.name);
      final outTotal = userExpenses.fold(0.0, (s, e) => s + e.amount);
      final inTotal = userIncomes.fold(0.0, (s, i) => s + i.amount);
      return (user: u, out: outTotal, income: inTotal);
    }).toList();

    // Transactions list combining expenses and incomes
    final allTransactions = [
      ...budgetState.expenses.map((e) => (id: e.id, title: e.title, amount: e.amount, date: e.date, type: 'Expense', assignee: e.assignee, category: e.category)),
      ...budgetState.incomes.map((i) => (id: i.id, title: i.title, amount: i.amount, date: i.date, type: 'Income', assignee: i.assignee, category: 'Przychód')),
    ];
    allTransactions.sort((a, b) => b.date.compareTo(a.date));

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
              const SectionHeader(sub: 'W tym miesiącu', title: 'Kategorie'),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: budgetState.categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final cat = budgetState.categories[index];
                  final ratio = cat.limit > 0 ? (cat.currentSpent / cat.limit) : 0.0;

                  return Column(
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
                            style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.muted),
                            splashRadius: 14,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            onPressed: () => _showEditLimitDialog(context, cat),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      HearthProgressBar(value: ratio),
                    ],
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
                            if (val != null) setState(() => _selectedAssignee = val);
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
              if (_selectedType == 'Wydatek') ...[
                const SizedBox(height: 16),
                Text('Kategoria', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                const SizedBox(height: 6),
                HearthSelect<String>(
                  value: _selectedCategory ?? '',
                  items: budgetState.categories.map((c) => c.name).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
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
                        FirebaseFirestore.instance.collection('budget_transactions').doc(tx.id).delete();
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
                                  Text(
                                    tx.title,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
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
                        'ROZLICZENIE WYDATKÓW',
                        style: AppTheme.microStyle.copyWith(color: AppTheme.moss.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        debtSummary,
                        style: AppTheme.titleStyle(fontSize: isDesktop ? 28 : 22, color: AppTheme.moss),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isBalanced
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Wydatki zostały rozliczone!'),
                              backgroundColor: AppTheme.moss,
                            ),
                          );
                        },
                  child: const Text('Rozlicz się'),
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