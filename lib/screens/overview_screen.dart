import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/budget_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/meals_provider.dart';
import '../providers/cleaning_provider.dart';
import '../providers/users_provider.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetStateProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final mealPlanAsync = ref.watch(mealPlanProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final choresAsync = ref.watch(cleaningProvider);
    final usersAsync = ref.watch(usersProvider);

    // Показываем лоадер, пока данные синхронизируются с облаком
    if (budgetAsync is AsyncLoading || inventoryAsync is AsyncLoading || 
        mealPlanAsync is AsyncLoading || recipesAsync is AsyncLoading || 
        choresAsync is AsyncLoading || usersAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.mossGreen));
    }

    final budgetState = budgetAsync.value!;
    final inventory = inventoryAsync.value!;
    final mealPlan = mealPlanAsync.value!;
    final recipes = recipesAsync.value!;
    final chores = choresAsync.value!;
    final users = usersAsync.value!;

    final totalIncome = budgetState.incomes.fold(0.0, (sum, inc) => sum + inc.amount);
    final totalSpent = budgetState.expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final remainingBudget = totalIncome - totalSpent;
    final budgetProgress = totalIncome > 0 ? (totalSpent / totalIncome).clamp(0.0, 1.0) : 0.0;

    final runningLowItems = inventory.where((item) => item.isRunningLow).toList();

    final todaysPlan = mealPlan.firstWhere(
      (plan) => plan.day == 'MON', // В реальном приложении здесь будет логика текущего дня
      orElse: () => mealPlan.first,
    );
    final todaysRecipe = todaysPlan.recipeId != null 
        ? recipes.firstWhere((r) => r.id == todaysPlan.recipeId) 
        : null;
    final plannedDinnersCount = mealPlan.where((p) => p.recipeId != null).length;

    final headerNames = users.isEmpty 
        ? 'NO RESIDENTS' 
        : users.map((u) => u.name.toUpperCase()).join(' & ');
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$headerNames · $dateStr',
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Container(
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
                        'LEFT TO SPEND THIS MONTH',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${remainingBudget.toStringAsFixed(0)} USD',
                        style: GoogleFonts.dmMono(
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: budgetProgress,
                        backgroundColor: AppTheme.textLight.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          budgetProgress > 0.9 ? AppTheme.red : AppTheme.mossGreen,
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Container(
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
                        'TONIGHT\'S DINNER',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        todaysRecipe?.name ?? 'Nothing planned yet',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          fontStyle: todaysRecipe == null ? FontStyle.italic : FontStyle.normal,
                          color: todaysRecipe == null ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '$plannedDinnersCount of 7 dinners planned',
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RUNNING LOW',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppTheme.textLight,
                            ),
                          ),
                          Text(
                            '${runningLowItems.length} items',
                            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (runningLowItems.isEmpty)
                        const Text('Everything is stocked up!', style: TextStyle(color: AppTheme.textLight)),
                      ...runningLowItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text(
                              '${item.quantity} ${item.unit}',
                              style: GoogleFonts.dmMono(fontSize: 14, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Container(
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
                        'TODAY\'S CHORES',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...chores.map((chore) {
                        final user = users.firstWhere((u) => u.name == chore.assignee, orElse: () => AppUser(id: '', name: '?', pinCode: '', color: AppTheme.textLight));

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: chore.isDone,
                                activeColor: AppTheme.mossGreen,
                                onChanged: (_) {
                                  ref.read(cleaningControllerProvider).toggleStatus(chore.id, chore.isDone);
                                },
                              ),
                              Expanded(
                                child: Text(
                                  chore.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: chore.isDone ? TextDecoration.lineThrough : null,
                                    color: chore.isDone ? AppTheme.textLight : AppTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  chore.assignee,
                                  style: TextStyle(
                                    color: user.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}