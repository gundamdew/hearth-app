import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/meal_models.dart';
import '../providers/meals_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(mealPlanProvider);
    final recipes = ref.watch(recipesProvider);
    final inventory = ref.watch(inventoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Верхний блок: План на неделю
        Text(
          'This week\'s dinners',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: mealPlan.map((plan) => _buildMealPlanCard(context, ref, plan, recipes)).toList(),
          ),
        ),
        const SizedBox(height: 48),
        
        // Нижний блок: Рецепты и Форма
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Сетка рецептов
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipe box',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeCard(context, recipes[index], inventory);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              
              // Сайдбар: Добавление рецепта
              Expanded(
                flex: 3,
                child: _buildNewRecipeCard(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanCard(BuildContext context, WidgetRef ref, MealPlan plan, List<Recipe> recipes) {
    final recipe = plan.recipeId != null 
        ? recipes.firstWhere((r) => r.id == plan.recipeId) 
        : null;

    return Container(
      width: 160,
      height: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.day,
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              recipe?.name ?? '— Nothing planned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: recipe != null ? AppTheme.textDark : AppTheme.textLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (recipe != null) ...[
            const SizedBox(height: 8),
            Divider(color: AppTheme.textLight.withValues(alpha: 0.1)),
            TextButton.icon(
              onPressed: plan.isCooked ? null : () {
                ref.read(mealPlanProvider.notifier).markCooked(plan.id, plan.recipeId!);
              },
              icon: Icon(
                plan.isCooked ? Icons.check_circle : Icons.check, 
                size: 16,
                color: plan.isCooked ? AppTheme.mossGreen : AppTheme.textLight,
              ),
              label: Text(
                'Mark cooked',
                style: TextStyle(
                  fontSize: 12,
                  color: plan.isCooked ? AppTheme.mossGreen : AppTheme.textLight,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                alignment: Alignment.centerLeft,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, List<InventoryItem> inventory) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '${recipe.ingredients.length} ingredients',
            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ingredients.map((reqIng) {
              // Ищем ингредиент на складе
              final inventoryItem = inventory.firstWhere(
                (item) => item.id == reqIng.inventoryId,
                orElse: () => InventoryItem(id: '', name: 'Unknown', location: '', quantity: 0, unit: '', lowStockThreshold: 0),
              );
              
              // Логика проверки: хватает ли запасов для рецепта?
              final isMissing = inventoryItem.quantity < reqIng.quantity;
              final color = isMissing ? AppTheme.red : AppTheme.mossGreen;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isMissing ? Icons.close : Icons.check, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${reqIng.quantity} ${inventoryItem.name}',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNewRecipeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New recipe', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(flex: 3, child: _buildSimpleTextField('Recipe name')),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildSimpleTextField('30')),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'INGREDIENTS',
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 1, child: _buildSimpleTextField('1')),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildSimpleTextField('Find in inventory', icon: Icons.search)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '+ Add ingredient',
              style: TextStyle(color: AppTheme.textLight, fontSize: 14, decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTextField(String hint, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
          if (icon != null) Icon(icon, size: 16, color: AppTheme.textLight),
        ],
      ),
    );
  }
}