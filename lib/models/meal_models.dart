class RecipeIngredient {
  final String inventoryId;
  final int quantity;

  RecipeIngredient({
    required this.inventoryId,
    required this.quantity,
  });
}

class Recipe {
  final String id;
  final String name;
  final List<RecipeIngredient> ingredients;
  final int? prepTime;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    this.prepTime,
  });
}

class MealPlan {
  final String id;
  final String day;
  final String? recipeId;
  final bool isCooked;

  MealPlan({
    required this.id,
    required this.day,
    this.recipeId,
    this.isCooked = false,
  });

  MealPlan copyWith({
    String? id,
    String? day,
    String? recipeId,
    bool? isCooked,
  }) {
    return MealPlan(
      id: id ?? this.id,
      day: day ?? this.day,
      recipeId: recipeId ?? this.recipeId,
      isCooked: isCooked ?? this.isCooked,
    );
  }
}