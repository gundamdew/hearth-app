import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_models.dart';

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  return FirebaseFirestore.instance.collection('recipes').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => Recipe.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final mealPlanProvider = StreamProvider<List<MealPlan>>((ref) {
  return FirebaseFirestore.instance.collection('meal_plans').orderBy('day').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => MealPlan.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final mealsControllerProvider = Provider((ref) => MealsController(ref));

class MealsController {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  MealsController(this._ref);

  Future<void> initializeMealPlans() async {
    final snap = await _db.collection('meal_plans').limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _db.batch();
      final days = ['1_MON', '2_TUE', '3_WED', '4_THU', '5_FRI', '6_SAT', '7_SUN'];
      for (var dayData in days) {
        final parts = dayData.split('_');
        final doc = _db.collection('meal_plans').doc(parts[0]);
        batch.set(doc, {'day': parts[1], 'recipeId': null, 'isCooked': false});
      }
      await batch.commit();
    }
  }

  Future<void> addRecipe(String name, int prepTime, List<RecipeIngredient> ingredients) async {
    final recipe = Recipe(id: '', name: name, prepTime: prepTime, ingredients: ingredients);
    await _db.collection('recipes').add(recipe.toMap());
  }

  Future<void> assignRecipe(String mealPlanId, String recipeId) async {
    await _db.collection('meal_plans').doc(mealPlanId).update({'recipeId': recipeId, 'isCooked': false});
  }

  Future<void> clearRecipe(String mealPlanId) async {
    await _db.collection('meal_plans').doc(mealPlanId).update({'recipeId': null, 'isCooked': false});
  }

  Future<void> markCooked(String mealPlanId, String recipeId) async {
    final recipesVal = _ref.read(recipesProvider).value ?? [];
    final recipe = recipesVal.firstWhere((r) => r.id == recipeId);

    final batch = _db.batch();

    for (var ingredient in recipe.ingredients) {
      if (ingredient.inventoryId.isNotEmpty) {
        batch.update(_db.collection('inventory').doc(ingredient.inventoryId), {
          'quantity': FieldValue.increment(-ingredient.quantity)
        });
      }
    }

    batch.update(_db.collection('meal_plans').doc(mealPlanId), {'isCooked': true});
    await batch.commit();
  }
}