import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../providers/budget_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/meals_provider.dart';
import '../providers/cleaning_provider.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Подписываемся на все провайдеры
    final budgetState = ref.watch(budgetProvider);
    final inventory = ref.watch(inventoryProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final recipes = ref.watch(recipesProvider);
    final chores = ref.watch(cleaningProvider);

    // Вычисления для Бюджета
    final totalLimit = budgetState.categories.fold(0.0, (sum, cat) => sum + cat.limit);
    final totalSpent = budgetState.categories.fold(0.0, (sum, cat) => sum + cat.currentSpent);
    final remainingBudget = totalLimit - totalSpent;
    final budgetProgress = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

    // Вычисления для Инвентаря
    final runningLowItems = inventory.where((item) => item.isRunningLow).toList();

    // Вычисления для Плана питания
    final todaysPlan = mealPlan.firstWhere(
      (plan) => plan.day == 'MON', 
      orElse: () => mealPlan.first,
    );
    final todaysRecipe = todaysPlan.recipeId != null 
        ? recipes.firstWhere((r) => r.id == todaysPlan.recipeId) 
        : null;
    final plannedDinnersCount = mealPlan.where((p) => p.recipeId != null).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MAYA & JONAH · MONDAY, OCTOBER 4',
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 32),
          
          // ВЕРХНИЙ РЯД
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Блок Бюджета
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
              
              // 2. Блок Ужина
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
                        style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // НИЖНИЙ РЯД
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3. Блок заканчивающихся запасов
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
                            style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (runningLowItems.isEmpty)
                        Text('Everything is stocked up!', style: TextStyle(color: AppTheme.textLight)),
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
              
              // 4. Блок задач
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
                        final isMaya = chore.assignee == 'Maya';
                        final userColor = isMaya ? AppTheme.terracotta : AppTheme.sage;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: chore.isDone,
                                activeColor: AppTheme.mossGreen,
                                onChanged: (_) {
                                  ref.read(cleaningProvider.notifier).toggleStatus(chore.id);
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
                                  color: userColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  chore.assignee,
                                  style: TextStyle(
                                    color: userColor,
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