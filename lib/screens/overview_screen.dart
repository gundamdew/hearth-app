import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/meal_models.dart';
import '../models/budget_models.dart';
import '../providers/budget_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/meals_provider.dart';
import '../providers/cleaning_provider.dart';
import '../providers/users_provider.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 800;

    final budgetAsync = ref.watch(budgetStateProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final mealPlanAsync = ref.watch(mealPlanProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final choresAsync = ref.watch(cleaningProvider);
    final usersAsync = ref.watch(usersProvider);

    if (budgetAsync.isLoading || inventoryAsync.isLoading || mealPlanAsync.isLoading || 
        recipesAsync.isLoading || choresAsync.isLoading || usersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.mossGreen));
    }

    if (budgetAsync.hasError) return Center(child: Text('Budget error: ${budgetAsync.error}'));
    if (inventoryAsync.hasError) return Center(child: Text('Inventory error: ${inventoryAsync.error}'));
    if (mealPlanAsync.hasError) return Center(child: Text('Meals error: ${mealPlanAsync.error}'));
    if (recipesAsync.hasError) return Center(child: Text('Recipes error: ${recipesAsync.error}'));
    if (choresAsync.hasError) return Center(child: Text('Chores error: ${choresAsync.error}'));
    if (usersAsync.hasError) return Center(child: Text('Users error: ${usersAsync.error}'));

    final budgetState = budgetAsync.value ?? BudgetState(categories: [], expenses: [], incomes: []);
    final inventory = inventoryAsync.value ?? [];
    final mealPlan = mealPlanAsync.value ?? [];
    final recipes = recipesAsync.value ?? [];
    final chores = choresAsync.value ?? [];
    final users = usersAsync.value ?? [];

    final totalIncome = budgetState.incomes.fold(0.0, (sum, inc) => sum + inc.amount);
    final totalSpent = budgetState.expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final remainingBudget = totalIncome - totalSpent;
    final budgetProgress = totalIncome > 0 ? (totalSpent / totalIncome).clamp(0.0, 1.0) : 0.0;

    final runningLowItems = inventory.where((item) => item.isRunningLow).toList();

    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaysPlan = mealPlan.firstWhere(
      (plan) => plan.id == todayId,
      orElse: () => MealPlan(id: todayId, date: DateTime.now(), recipeId: null),
    );
    
    Recipe? todaysRecipe;
    if (todaysPlan.recipeId != null) {
      final matches = recipes.where((r) => r.id == todaysPlan.recipeId);
      if (matches.isNotEmpty) {
        todaysRecipe = matches.first;
      }
    }
    
    final plannedDinnersCount = mealPlan.where((p) => p.recipeId != null).length;

    final headerNames = users.isEmpty 
        ? 'NO RESIDENTS' 
        : users.map((u) => u.name.toUpperCase()).join(' & ');
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase();

    Widget budgetCard = _buildMetricCard(
      context, 
      'LEFT TO SPEND THIS MONTH', 
      '${remainingBudget.toStringAsFixed(0)} USD', 
      LinearProgressIndicator(
        value: budgetProgress,
        backgroundColor: AppTheme.textLight.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(budgetProgress > 0.9 ? AppTheme.red : AppTheme.mossGreen),
        minHeight: 4,
        borderRadius: BorderRadius.circular(2),
      )
    );

    Widget dinnerCard = _buildMetricCard(
      context, 
      'TONIGHT\'S DINNER', 
      todaysRecipe?.name ?? 'Nothing planned yet', 
      Text('$plannedDinnersCount of 14 dinners planned', style: const TextStyle(color: AppTheme.textLight, fontSize: 14)),
      isItalic: todaysRecipe == null
    );

    Widget lowStockCard = _buildListCard(
      context, 
      'RUNNING LOW', 
      '${runningLowItems.length} items', 
      runningLowItems.isEmpty 
        ? const Text('Everything is stocked up!', style: TextStyle(color: AppTheme.textLight))
        : Column(
            children: runningLowItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text('${item.quantity} ${item.unit}', style: GoogleFonts.dmMono(fontSize: 14, color: AppTheme.textLight)),
                ],
              ),
            )).toList(),
          )
    );

    Widget choresCard = _buildListCard(
      context, 
      'TODAY\'S CHORES', 
      '', 
      Column(
        children: chores.map((chore) {
          final user = users.firstWhere((u) => u.name == chore.assignee, orElse: () => AppUser(id: '', name: '?', pinCode: '', color: AppTheme.textLight));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: chore.isDone,
                  activeColor: AppTheme.mossGreen,
                  onChanged: (_) => ref.read(cleaningControllerProvider).toggleStatus(chore.id, chore.isDone),
                ),
                Expanded(
                  child: Text(
                    chore.name,
                    style: TextStyle(fontSize: 16, decoration: chore.isDone ? TextDecoration.lineThrough : null, color: chore.isDone ? AppTheme.textLight : AppTheme.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: user.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(chore.assignee, style: TextStyle(color: user.color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }).toList(),
      )
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$headerNames · $dateStr', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppTheme.textLight)),
          const SizedBox(height: 32),
          
          isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [budgetCard, const SizedBox(height: 16), dinnerCard])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: budgetCard), const SizedBox(width: 24), Expanded(child: dinnerCard)]),
            
          const SizedBox(height: 24),
          
          isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [lowStockCard, const SizedBox(height: 16), choresCard])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: lowStockCard), const SizedBox(width: 24), Expanded(child: choresCard)]),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, Widget bottomWidget, {bool isItalic = false}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          Text(value, style: isItalic 
            ? Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28, fontStyle: FontStyle.italic, color: AppTheme.textLight)
            : GoogleFonts.dmMono(fontSize: 40, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
          const SizedBox(height: 24),
          bottomWidget,
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context, String title, String subtitle, Widget content) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppTheme.textLight)),
              if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }
}