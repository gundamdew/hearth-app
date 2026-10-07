import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/meal_models.dart';

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  return FirebaseFirestore.instance.collection('recipes').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => Recipe.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final mealPlanProvider = StreamProvider<List<MealPlan>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return FirebaseFirestore.instance.collection('meal_plans')
    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
    .orderBy('date')
    .limit(14)
    .snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => MealPlan.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final mealsControllerProvider = Provider((ref) => MealsController(ref));

class MealsController {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  MealsController(this._ref);

  Future<void> initializeMealPlans() async {
    final batch = _db.batch();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < 14; i++) {
      final targetDate = today.add(Duration(days: i));
      final id = DateFormat('yyyy-MM-dd').format(targetDate);
      
      final docRef = _db.collection('meal_plans').doc(id);
      final docSnap = await docRef.get();
      
      if (!docSnap.exists) {
        batch.set(docRef, {
          'date': Timestamp.fromDate(targetDate),
          'recipeId': null,
          'isCooked': false,
        });
      }
    }
    await batch.commit();
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
    final matches = recipesVal.where((r) => r.id == recipeId);
    if (matches.isEmpty) return;
    
    final recipe = matches.first;
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