import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      ref.read(recipesProvider.notifier).addRecipe(name, prepTime, List.from(_tempIngredients));
      
      setState(() {
        _recipeNameCtrl.clear();
        _prepTimeCtrl.clear();
        _tempIngredients.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealPlan = ref.watch(mealPlanProvider);
    final recipes = ref.watch(recipesProvider);
    final inventory = ref.watch(inventoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This week\'s dinners', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: mealPlan.map((plan) => _buildMealPlanCard(context, ref, plan, recipes)).toList(),
          ),
        ),
        const SizedBox(height: 48),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recipe box', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
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

  Widget _buildMealPlanCard(BuildContext context, WidgetRef ref, MealPlan plan, List<Recipe> recipes) {
    final recipe = plan.recipeId != null 
        ? recipes.firstWhere((r) => r.id == plan.recipeId, orElse: () => Recipe(id: '', name: 'Deleted Recipe', ingredients: [])) 
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
          Text(plan.day, style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppTheme.textLight)),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              recipe?.name ?? '— Nothing planned',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: recipe != null ? AppTheme.textDark : AppTheme.textLight),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (recipe != null) ...[
            const SizedBox(height: 8),
            Divider(color: AppTheme.textLight.withValues(alpha: 0.1)),
            TextButton.icon(
              onPressed: plan.isCooked ? null : () => ref.read(mealPlanProvider.notifier).markCooked(plan.id, plan.recipeId!),
              icon: Icon(plan.isCooked ? Icons.check_circle : Icons.check, size: 16, color: plan.isCooked ? AppTheme.mossGreen : AppTheme.textLight),
              label: Text('Mark cooked', style: TextStyle(fontSize: 12, color: plan.isCooked ? AppTheme.mossGreen : AppTheme.textLight)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), alignment: Alignment.centerLeft),
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
          Text(recipe.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('${recipe.ingredients.length} ingredients', style: const TextStyle(fontSize: 14, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe.ingredients.map((reqIng) {
                  // Даже если продукт удален из инвентаря, рецепт выведет оригинальное имя и отметит его красным цветом
                  final inventoryItem = inventory.firstWhere(
                    (item) => item.id == reqIng.inventoryId,
                    orElse: () => InventoryItem(id: '', name: reqIng.name, location: '', quantity: 0, unit: '', lowStockThreshold: 0),
                  );
                  
                  final isMissing = inventoryItem.quantity < reqIng.quantity;
                  final color = isMissing ? AppTheme.red : AppTheme.mossGreen;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isMissing ? Icons.close : Icons.check, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text('${reqIng.quantity} ${reqIng.name}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
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
                Expanded(flex: 3, child: _buildTextField(_recipeNameCtrl, 'Recipe name')),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildTextField(_prepTimeCtrl, '30 min', isNumber: true)),
              ],
            ),
            const SizedBox(height: 24),
            Text('INGREDIENTS', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppTheme.textLight)),
            const SizedBox(height: 12),
            
            ..._tempIngredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${ing.quantity}x ${ing.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.red),
                    onPressed: () => setState(() => _tempIngredients.remove(ing)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            )),
            if (_tempIngredients.isNotEmpty) const SizedBox(height: 12),

            Row(
              children: [
                Expanded(flex: 1, child: _buildTextField(_ingQtyCtrl, '1', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3, 
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: _selectedInventoryId,
                        hint: const Text('Find in inventory', style: TextStyle(fontSize: 14)),
                        items: inventory.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                        onChanged: (val) => setState(() => _selectedInventoryId = val),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _addIngredient(inventory),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), alignment: Alignment.centerLeft),
              child: const Text('+ Add ingredient', style: TextStyle(decoration: TextDecoration.underline)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecipe,
                child: const Text('Save recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.mossGreen), borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}