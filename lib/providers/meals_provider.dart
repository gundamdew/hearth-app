import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_models.dart';
import 'inventory_provider.dart';

class RecipesNotifier extends Notifier<List<Recipe>> {
  @override
  List<Recipe> build() {
    return [
      Recipe(
        id: 'r1',
        name: 'Tomato & garlic pasta',
        prepTime: 30,
        ingredients: [
          RecipeIngredient(inventoryId: '1', name: 'Pasta', quantity: 1),
          RecipeIngredient(inventoryId: '3', name: 'Canned tomatoes', quantity: 2),
          RecipeIngredient(inventoryId: '10', name: 'Garlic', quantity: 2),
        ],
      ),
      Recipe(
        id: 'r2',
        name: 'Chickpeas & spinach curry',
        prepTime: 45,
        ingredients: [
          RecipeIngredient(inventoryId: '4', name: 'Chickpeas', quantity: 2),
          RecipeIngredient(inventoryId: '6', name: 'Spinach', quantity: 2),
          RecipeIngredient(inventoryId: '9', name: 'Onions', quantity: 1),
        ],
      ),
      Recipe(
        id: 'r3',
        name: 'Shakshuka',
        prepTime: 25,
        ingredients: [
          RecipeIngredient(inventoryId: '5', name: 'Eggs', quantity: 2),
          RecipeIngredient(inventoryId: '3', name: 'Canned tomatoes', quantity: 1),
          RecipeIngredient(inventoryId: '9', name: 'Onions', quantity: 1),
        ],
      ),
      Recipe(
        id: 'r4',
        name: 'Roast chicken & rice',
        prepTime: 60,
        ingredients: [
          RecipeIngredient(inventoryId: '8', name: 'Chicken thighs', quantity: 1),
          RecipeIngredient(inventoryId: '2', name: 'Rice', quantity: 1),
        ],
      ),
    ];
  }

  void addRecipe(String name, int prepTime, List<RecipeIngredient> ingredients) {
    final newRecipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      prepTime: prepTime,
      ingredients: ingredients,
    );
    state = [...state, newRecipe];
  }
}

final recipesProvider = NotifierProvider<RecipesNotifier, List<Recipe>>(() {
  return RecipesNotifier();
});

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
    final recipes = ref.read(recipesProvider);
    final recipe = recipes.firstWhere((r) => r.id == recipeId);

    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    for (var ingredient in recipe.ingredients) {
      inventoryNotifier.updateQuantity(ingredient.inventoryId, -ingredient.quantity);
    }

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