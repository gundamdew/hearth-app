import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/meal_models.dart';
import '../providers/meals_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  final TextEditingController _recipeNameCtrl = TextEditingController();
  final TextEditingController _prepTimeCtrl = TextEditingController();
  
  final TextEditingController _ingQtyCtrl = TextEditingController(text: '1');
  String? _selectedInventoryId;
  final List<RecipeIngredient> _tempIngredients = [];

  @override
  void dispose() {
    _recipeNameCtrl.dispose();
    _prepTimeCtrl.dispose();
    _ingQtyCtrl.dispose();
    super.dispose();
  }

  void _addIngredient(List<InventoryItem> inventory) {
    if (_selectedInventoryId != null) {
      final qty = int.tryParse(_ingQtyCtrl.text) ?? 1;
      final invItem = inventory.firstWhere((i) => i.id == _selectedInventoryId);
      setState(() {
        _tempIngredients.add(RecipeIngredient(
          inventoryId: invItem.id,
          name: invItem.name,
          quantity: qty,
        ));
        _ingQtyCtrl.text = '1';
        _selectedInventoryId = null;
      });
    }
  }

  void _saveRecipe() {
    final name = _recipeNameCtrl.text.trim();
    final prepTime = int.tryParse(_prepTimeCtrl.text) ?? 30;

    if (name.isNotEmpty && _tempIngredients.isNotEmpty) {
      ref.read(mealsControllerProvider).addRecipe(name, prepTime, List.from(_tempIngredients));
      
      setState(() {
        _recipeNameCtrl.clear();
        _prepTimeCtrl.clear();
        _tempIngredients.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _showRecipePicker(BuildContext context, WidgetRef ref, String mealPlanId, List<Recipe> recipes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Assign Recipe', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: recipes.length,
              separatorBuilder: (context, index) => Divider(color: AppTheme.textLight.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: Text('${recipe.ingredients.length} ingredients · ${recipe.prepTime ?? 30} min', style: const TextStyle(color: AppTheme.textLight)),
                  trailing: const Icon(Icons.add_circle_outline, color: AppTheme.mossGreen),
                  onTap: () {
                    ref.read(mealsControllerProvider).assignRecipe(mealPlanId, recipe.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanAsync = ref.watch(mealPlanProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    if (mealPlanAsync.isLoading || recipesAsync.isLoading || inventoryAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.mossGreen));
    }

    if (mealPlanAsync.hasError) return Center(child: Text('Meals error: ${mealPlanAsync.error}'));
    if (recipesAsync.hasError) return Center(child: Text('Recipes error: ${recipesAsync.error}'));
    if (inventoryAsync.hasError) return Center(child: Text('Inventory error: ${inventoryAsync.error}'));

    final mealPlan = mealPlanAsync.value ?? [];
    final recipes = recipesAsync.value ?? [];
    final inventory = inventoryAsync.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Upcoming Menu', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28)),
            Text(
              '${mealPlan.where((p) => p.recipeId != null).length} PLANNED', 
              style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppTheme.textLight, fontSize: 12)
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: mealPlan.map((plan) => _buildInteractiveDayCard(context, ref, plan, recipes)).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 48),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recipe Box', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
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
              const SizedBox(width: 40),
              
              Expanded(
                flex: 4, 
                child: _buildNewRecipeCard(context, inventory),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveDayCard(BuildContext context, WidgetRef ref, MealPlan plan, List<Recipe> recipes) {
    final recipe = plan.recipeId != null 
        ? recipes.firstWhere((r) => r.id == plan.recipeId, orElse: () => Recipe(id: '', name: 'Deleted Recipe', ingredients: [])) 
        : null;

    final hasRecipe = recipe != null;

    final dayName = DateFormat('EEEE').format(plan.date).toUpperCase();
    final dateStr = DateFormat('MMM d').format(plan.date).toUpperCase();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String displayLabel = dayName;
    if (plan.date.isAtSameMomentAs(today)) displayLabel = 'TODAY';
    else if (plan.date.isAtSameMomentAs(tomorrow)) displayLabel = 'TOMORROW';

    return GestureDetector(
      onTap: () {
        if (!hasRecipe) _showRecipePicker(context, ref, plan.id, recipes);
      },
      child: Container(
        width: 140,
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasRecipe ? AppTheme.mossGreen.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasRecipe ? AppTheme.mossGreen.withValues(alpha: 0.2) : AppTheme.textLight.withValues(alpha: 0.2),
            style: hasRecipe ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel, 
                      style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: hasRecipe ? AppTheme.mossGreen : AppTheme.textDark)
                    ),
                    Text(
                      dateStr, 
                      style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.0, color: AppTheme.textLight)
                    ),
                  ],
                ),
                if (hasRecipe)
                  GestureDetector(
                    onTap: () => ref.read(mealsControllerProvider).clearRecipe(plan.id),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.textLight),
                  )
              ],
            ),
            const Spacer(),
            if (hasRecipe) ...[
              Text(
                recipe.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (!plan.isCooked)
                GestureDetector(
                  onTap: () => ref.read(mealsControllerProvider).markCooked(plan.id, plan.recipeId!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.mossGreen, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Cook', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: AppTheme.mossGreen),
                    SizedBox(width: 4),
                    Text('Done', style: TextStyle(color: AppTheme.mossGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                )
            ] else ...[
              Center(
                child: Icon(Icons.add, size: 32, color: AppTheme.textLight.withValues(alpha: 0.3)),
              ),
              const Spacer(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, List<InventoryItem> inventory) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${recipe.ingredients.length} ingredients · ${recipe.prepTime ?? 30} min', style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe.ingredients.map((reqIng) {
                  final inventoryItem = inventory.firstWhere(
                    (item) => item.id == reqIng.inventoryId,
                    orElse: () => InventoryItem(id: '', name: reqIng.name, location: '', quantity: 0, unit: '', lowStockThreshold: 0),
                  );
                  
                  final isMissing = inventoryItem.quantity < reqIng.quantity;
                  final color = isMissing ? AppTheme.red : AppTheme.mossGreen;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isMissing ? Icons.warning_amber_rounded : Icons.check, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text('${reqIng.quantity} ${reqIng.name}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewRecipeCard(BuildContext context, List<InventoryItem> inventory) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Draft New Recipe', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: 3, child: TextField(controller: _recipeNameCtrl, decoration: const InputDecoration(hintText: 'Recipe title'))),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: TextField(controller: _prepTimeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Min'))),
            ],
          ),
          const SizedBox(height: 32),
          Text('INGREDIENTS', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          
          ..._tempIngredients.map((ing) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ing.quantity}x ${ing.name}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.red),
                  onPressed: () => setState(() => _tempIngredients.remove(ing)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          )),
          if (_tempIngredients.isNotEmpty) const SizedBox(height: 16),

          Row(
            children: [
              Expanded(flex: 1, child: TextField(controller: _ingQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Qty'))),
              const SizedBox(width: 16),
              Expanded(
                flex: 3, 
                child: DropdownButtonFormField<String>(
                  value: _selectedInventoryId,
                  hint: const Text('Select from inventory'),
                  items: inventory.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                  onChanged: (val) => setState(() => _selectedInventoryId = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _addIngredient(inventory),
            icon: const Icon(Icons.add),
            label: const Text('Add ingredient'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveRecipe,
              child: const Text('Save to Recipe Box'),
            ),
          ),
        ],
      ),
    );
  }
}