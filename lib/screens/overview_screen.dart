// lib/screens/overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/meal_models.dart';
import '../models/budget_models.dart';
import '../providers/budget_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/meals_provider.dart';
import '../providers/cleaning_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/hearth_ui.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;

    final budgetAsync = ref.watch(budgetStateProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final mealPlanAsync = ref.watch(mealPlanProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final choresAsync = ref.watch(cleaningProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (budgetAsync.isLoading || inventoryAsync.isLoading || mealPlanAsync.isLoading || 
        recipesAsync.isLoading || choresAsync.isLoading || usersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.moss));
    }

    final budgetState = budgetAsync.value ?? BudgetState(categories: [], expenses: [], incomes: []);
    final inventory = inventoryAsync.value ?? [];
    final mealPlan = mealPlanAsync.value ?? [];
    final chores = choresAsync.value ?? [];
    final users = usersAsync.value ?? [];
    final recipesMap = ref.watch(recipesMapProvider);
    final usersByNameMap = ref.watch(usersByNameMapProvider);

    // Financial calculations
    final totalMonthlyLimit = budgetState.categories.fold(0.0, (sum, cat) => sum + cat.limit);
    final totalSpent = budgetState.expenses
        .where((e) => e.splitType != 'settlement')
        .fold(0.0, (sum, exp) => sum + exp.amount);
    final remainingBudget = totalMonthlyLimit - totalSpent;
    final budgetProgress = totalMonthlyLimit > 0 ? (totalSpent / totalMonthlyLimit).clamp(0.0, 1.0) : 0.0;
    final totalIncome = budgetState.incomes.fold(0.0, (sum, inc) => sum + inc.amount);

    // Running low items
    final lowItems = inventory.where((item) => item.isRunningLow).toList();

    // Today's meal
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaysPlan = mealPlan.firstWhere(
      (plan) => plan.id == todayId,
      orElse: () => MealPlan(id: todayId, date: DateTime.now(), recipeId: null),
    );

    final Recipe? todaysRecipe = todaysPlan.recipeId != null ? recipesMap[todaysPlan.recipeId] : null;
    final plannedDinnersCount = mealPlan.where((p) => p.recipeId != null).length;

    // Chores done count
    final choresDoneCount = chores.where((c) => c.isDone).length;

    final now = DateTime.now();
    const weekdays = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
    const months = ['stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca', 'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'];
    final dateFormatted = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
    final residentsSubtitle = users.map((u) => u.name).join(' & ');

    final hour = now.hour;
    final greeting = (hour >= 18 || hour < 5) ? 'Dobry wieczór' : 'Dzień dobry';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader line
          Text(
            residentsSubtitle.isNotEmpty ? '$residentsSubtitle · $dateFormatted'.toUpperCase() : dateFormatted.toUpperCase(),
            style: AppTheme.microStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Main Title
          Text(
            '$greeting, ${currentUser?.name ?? "domowniku"}.',
            style: AppTheme.titleStyle(fontSize: isDesktop ? 48 : 34),
          ),
          SizedBox(height: isDesktop ? 32 : 24),

          // 2x2 Bento Grid or 1 Column Stack
          if (isDesktop || isTablet) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildBudgetCard(context, remainingBudget, totalSpent, totalMonthlyLimit, totalIncome, budgetProgress),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildDinnerCard(context, ref, todaysPlan, todaysRecipe, plannedDinnersCount),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInventoryCard(context, lowItems),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildChoresCard(context, ref, chores, usersByNameMap, choresDoneCount),
                ),
              ],
            ),
          ] else ...[
            _buildBudgetCard(context, remainingBudget, totalSpent, totalMonthlyLimit, totalIncome, budgetProgress),
            const SizedBox(height: 16),
            _buildDinnerCard(context, ref, todaysPlan, todaysRecipe, plannedDinnersCount),
            const SizedBox(height: 16),
            _buildInventoryCard(context, lowItems),
            const SizedBox(height: 16),
            _buildChoresCard(context, ref, chores, usersByNameMap, choresDoneCount),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, double remaining, double spent, double limit, double income, double ratio) {
    final isDanger = ratio > 0.9 || remaining < 0;

    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEFT TO SPEND THIS MONTH', style: AppTheme.microStyle),
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppTheme.muted),
                onPressed: () => context.go('/budget'),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${remaining.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} zł',
            style: AppTheme.monoHuge.copyWith(
              color: isDanger ? AppTheme.danger : AppTheme.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HearthProgressBar(value: ratio),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${spent.round()} zł wydano',
                    style: AppTheme.monoSmall.copyWith(color: AppTheme.muted),
                  ),
                  Text(
                    '${(ratio * 100).round()}% z ${limit.round()} zł',
                    style: AppTheme.monoSmall.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Zarejestrowany przychód · ${income.round()} zł',
                style: AppTheme.monoSmall.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDinnerCard(BuildContext context, WidgetRef ref, MealPlan plan, Recipe? recipe, int plannedCount) {
    final hasRecipe = recipe != null;

    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DZISIEJSZY OBIAD · DZIŚ', style: AppTheme.microStyle),
              Text(
                '$plannedCount z 14 zaplanowanych',
                style: AppTheme.monoSmall.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasRecipe) ...[
            Text(
              recipe.name,
              style: AppTheme.titleStyle(fontSize: 30),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${recipe.ingredients.length} składników · ${recipe.prepTime ?? 30} min',
              style: AppTheme.monoSmall.copyWith(color: AppTheme.muted),
            ),
          ] else ...[
            Text(
              'Brak planów na dzisiaj',
              style: AppTheme.titleStyle(fontSize: 26, color: AppTheme.muted, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasRecipe) ...[
                if (plan.isCooked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.sage.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 16, color: AppTheme.moss),
                        const SizedBox(width: 6),
                        Text(
                          'Ugotowane',
                          style: AppTheme.sansMedium.copyWith(
                            color: AppTheme.moss,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      ref.read(mealsControllerProvider).markCooked(plan.id, recipe.id);
                    },
                    child: const Text('Oznacz jako ugotowane'),
                  ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => context.go('/meals'),
                  child: const Text('Zaplanuj obiad'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, List<dynamic> lowItems) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KOŃCZĄCE SIĘ ZAPASY', style: AppTheme.microStyle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${lowItems.length} prod.',
                  style: AppTheme.monoSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lowItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Wszystko jest uzupełnione.',
                style: AppTheme.titleStyle(fontSize: 20, color: AppTheme.muted, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowItems.take(5).length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
              itemBuilder: (context, index) {
                final item = lowItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.danger,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTheme.sansMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: AppTheme.monoSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/inventory'),
            child: Text(
              'Otwórz spiżarnię →',
              style: AppTheme.sansMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.moss,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoresCard(BuildContext context, WidgetRef ref, List<dynamic> chores, Map<String, dynamic> usersByNameMap, int doneCount) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DZISIEJSZE OBOWIĄZKI', style: AppTheme.microStyle),
              Text(
                '$doneCount/${chores.length}',
                style: AppTheme.monoSmall.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (chores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Brak przypisanych zadań.',
                style: AppTheme.titleStyle(fontSize: 20, color: AppTheme.muted, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chores.take(5).length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
              itemBuilder: (context, index) {
                final chore = chores[index];
                final assignedUser = usersByNameMap[chore.assignee];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      HearthCheckbox(
                        checked: chore.isDone,
                        onChange: () {
                          ref.read(cleaningControllerProvider).toggleStatus(chore.id, chore.isDone);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chore.name,
                          style: AppTheme.sansMedium.copyWith(
                            color: chore.isDone ? AppTheme.muted : AppTheme.ink,
                            decoration: chore.isDone ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ResidentBadge(
                        name: chore.assignee,
                        color: assignedUser?.color,
                        avatar: assignedUser?.avatar,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}