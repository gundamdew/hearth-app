import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_models.dart';
import 'inventory_provider.dart';

// Провайдер статических рецептов для "Recipe box"
final recipesProvider = Provider<List<Recipe>>((ref) {
  return [
    Recipe(
      id: 'r1',
      name: 'Tomato & garlic pasta',
      ingredients: [
        RecipeIngredient(inventoryId: '1', quantity: 1), // Pasta
        RecipeIngredient(inventoryId: '3', quantity: 2), // Canned tomatoes
        RecipeIngredient(inventoryId: '10', quantity: 2), // Garlic (Will show RED if inventory has 1)
      ],
    ),
    Recipe(
      id: 'r2',
      name: 'Chickpeas & spinach curry',
      ingredients: [
        RecipeIngredient(inventoryId: '4', quantity: 2), // Chickpeas (RED if inventory has 1)
        RecipeIngredient(inventoryId: '6', quantity: 2), // Spinach (RED if inventory has 1)
        RecipeIngredient(inventoryId: '9', quantity: 1), // Onions
      ],
    ),
    Recipe(
      id: 'r3',
      name: 'Shakshuka',
      ingredients: [
        RecipeIngredient(inventoryId: '5', quantity: 2), // Eggs
        RecipeIngredient(inventoryId: '3', quantity: 1), // Canned tomatoes
        RecipeIngredient(inventoryId: '9', quantity: 1), // Onions
      ],
    ),
    Recipe(
      id: 'r4',
      name: 'Roast chicken & rice',
      ingredients: [
        RecipeIngredient(inventoryId: '8', quantity: 1), // Chicken thighs
        RecipeIngredient(inventoryId: '2', quantity: 1), // Rice
      ],
    ),
  ];
});

// Управление планом питания и вычитанием ингредиентов
class MealPlanNotifier extends Notifier<List<MealPlan>> {
  @override
  List<MealPlan> build() {
    return [
      MealPlan(id: 'm1', day: 'MON', recipeId: 'r1'),
      MealPlan(id: 'm2', day: 'TUE', recipeId: 'r2'),
      MealPlan(id: 'm3', day: 'WED', recipeId: null),
      MealPlan(id: 'm4', day: 'THU', recipeId: 'r3'),
      MealPlan(id: 'm5', day: 'FRI', recipeId: null),
      MealPlan(id: 'm6', day: 'SAT', recipeId: 'r4'),
      MealPlan(id: 'm7', day: 'SUN', recipeId: null),
    ];
  }

  void markCooked(String mealPlanId, String recipeId) {
    // 1. Находим рецепт
    final recipes = ref.read(recipesProvider);
    final recipe = recipes.firstWhere((r) => r.id == recipeId);

    // 2. Вычитаем ингредиенты из inventory
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    for (var ingredient in recipe.ingredients) {
      // Передаем отрицательное значение для вычитания
      inventoryNotifier.updateQuantity(ingredient.inventoryId, -ingredient.quantity);
    }

    // 3. Обновляем статус в плане питания
    state = state.map((meal) {
      if (meal.id == mealPlanId) {
        return meal.copyWith(isCooked: true);
      }
      return meal;
    }).toList();
  }
}

final mealPlanProvider = NotifierProvider<MealPlanNotifier, List<MealPlan>>(() {
  return MealPlanNotifier();
});