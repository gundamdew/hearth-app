// lib/screens/meals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/meal_models.dart';
import '../models/inventory_item.dart';
import '../providers/meals_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/hearth_ui.dart';

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  final TextEditingController _recipeNameCtrl = TextEditingController();
  final TextEditingController _prepTimeCtrl = TextEditingController(text: '30');
  final TextEditingController _ingQtyCtrl = TextEditingController(text: '1');
  String? _selectedInventoryId;
  final List<RecipeIngredient> _draftIngredients = [];

  @override
  void dispose() {
    _recipeNameCtrl.dispose();
    _prepTimeCtrl.dispose();
    _ingQtyCtrl.dispose();
    super.dispose();
  }

  void _showAssignRecipeModal(BuildContext context, MealPlan plan, List<Recipe> recipes, List<InventoryItem> inventory) {
    final dayLabel = _getDayLabel(plan.date);

    showHearthModal(
      context: context,
      title: 'Assign Recipe',
      sub: dayLabel,
      child: Column(
        children: recipes.map((recipe) {
          int missingCount = 0;
          for (var ing in recipe.ingredients) {
            final matches = inventory.where((i) => i.id == ing.inventoryId || i.name.toLowerCase() == ing.name.toLowerCase());
            final stockedQty = matches.isNotEmpty ? matches.first.quantity : 0;
            if (stockedQty < ing.quantity) {
              missingCount++;
            }
          }

          return InkWell(
            onTap: () {
              ref.read(mealsControllerProvider).assignRecipe(plan.id, recipe.id);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: AppTheme.titleStyle(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${recipe.ingredients.length} ingredients · ${recipe.prepTime ?? 30} min',
                          style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  if (missingCount > 0)
                    Text(
                      '$missingCount missing',
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.danger, fontWeight: FontWeight.w500),
                    )
                  else
                    const Icon(Icons.check, size: 16, color: AppTheme.moss),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    final mealsAsync = ref.watch(mealPlanProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    if (mealsAsync.isLoading || recipesAsync.isLoading || inventoryAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.moss));
    }

    final mealPlans = mealsAsync.value ?? [];
    final recipes = recipesAsync.value ?? [];
    final inventory = inventoryAsync.value ?? [];

    final plannedCount = mealPlans.where((p) => p.recipeId != null).length;

    // Upcoming Menu Carousel Section
    final carouselSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          sub: 'Next 14 days',
          title: 'Upcoming Menu',
          action: Text(
            '$plannedCount of 14 planned',
            style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: mealPlans.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final plan = mealPlans[index];
              final dayLabel = _getDayLabel(plan.date);
              final isToday = dayLabel == 'Today';
              final recipeMatches = recipes.where((r) => r.id == plan.recipeId);
              final recipe = recipeMatches.isNotEmpty ? recipeMatches.first : null;

              if (recipe == null) {
                return GestureDetector(
                  onTap: () => _showAssignRecipeModal(context, plan, recipes, inventory),
                  child: Container(
                    width: 175,
                    height: 175,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.muted.withValues(alpha: 0.25),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel.toUpperCase(),
                          style: AppTheme.microStyle.copyWith(
                            color: isToday ? AppTheme.moss : AppTheme.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppTheme.stone,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 20, color: AppTheme.muted),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                width: 175,
                height: 175,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: plan.isCooked ? AppTheme.canvas : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.moss.withValues(alpha: 0.35)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(30, 32, 29, 0.03),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dayLabel.toUpperCase(),
                            style: AppTheme.microStyle.copyWith(
                              color: isToday ? AppTheme.moss : AppTheme.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(mealsControllerProvider).clearRecipe(plan.id),
                          child: const Icon(Icons.close, size: 16, color: AppTheme.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.name,
                      style: AppTheme.titleStyle(
                        fontSize: 17,
                        color: plan.isCooked ? AppTheme.muted : AppTheme.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.prepTime ?? 30} min',
                      style: GoogleFonts.dmMono(fontSize: 11, color: AppTheme.muted),
                    ),
                    const Spacer(),
                    if (plan.isCooked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sage.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 12, color: AppTheme.moss),
                            const SizedBox(width: 4),
                            Text(
                              'Done',
                              style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.moss),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => ref.read(mealsControllerProvider).markCooked(plan.id, recipe.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.moss,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.soup_kitchen, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Cook',
                                style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    // Recipe Box Grid
    final recipeBoxSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(sub: '${recipes.length} recipes', title: 'Recipe Box'),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoCols = constraints.maxWidth >= 450;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: useTwoCols ? 2 : 1,
                mainAxisExtent: 170,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final r = recipes[index];

                return Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: AppTheme.titleStyle(fontSize: 20),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.ingredients.length} ingredients · ${r.prepTime ?? 30} min',
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: r.ingredients.map((ing) {
                          final invMatches = inventory.where((i) => i.id == ing.inventoryId || i.name.toLowerCase() == ing.name.toLowerCase());
                          final hasStock = invMatches.isNotEmpty && invMatches.first.quantity >= ing.quantity;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasStock ? AppTheme.sage.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasStock ? Icons.check : Icons.warning_amber_rounded,
                                  size: 11,
                                  color: hasStock ? AppTheme.moss : AppTheme.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${ing.quantity} ${ing.name}',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 11,
                                    color: hasStock ? AppTheme.moss : AppTheme.danger,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );

    // Draft Recipe Form
    final recipeForm = FormCard(
      sub: 'Recipe box',
      title: 'Draft New Recipe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recipe title', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _recipeNameCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Pierogi ruskie'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prep (min)', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _prepTimeCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.dmMono(fontSize: 14),
                      decoration: const InputDecoration(hintText: '30'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Ingredients', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
          const SizedBox(height: 6),

          // Added ingredients list
          if (_draftIngredients.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _draftIngredients.length,
                separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
                itemBuilder: (context, index) {
                  final ing = _draftIngredients[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Text('${ing.quantity}', style: GoogleFonts.dmMono(fontSize: 13, color: AppTheme.ink)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(ing.name, style: const TextStyle(fontSize: 14))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14, color: AppTheme.muted),
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () => setState(() => _draftIngredients.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Add ingredient row
          Row(
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _ingQtyCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.dmMono(fontSize: 14),
                  decoration: const InputDecoration(hintText: '1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HearthSelect<String>(
                  value: _selectedInventoryId ?? '',
                  placeholder: 'Select from inventory',
                  items: inventory.map((i) => i.id).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedInventoryId = val);
                  },
                  labelBuilder: (id) {
                    final item = inventory.firstWhere((i) => i.id == id, orElse: () => InventoryItem(id: '', name: '', location: '', quantity: 0, unit: '', lowStockThreshold: 1));
                    return '${item.name} (${item.unit})';
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _selectedInventoryId == null
                  ? null
                  : () {
                      final item = inventory.firstWhere((i) => i.id == _selectedInventoryId);
                      final qty = int.tryParse(_ingQtyCtrl.text) ?? 1;
                      setState(() {
                        _draftIngredients.add(RecipeIngredient(
                          inventoryId: item.id,
                          name: item.name,
                          quantity: qty,
                        ));
                        _selectedInventoryId = null;
                        _ingQtyCtrl.text = '1';
                      });
                    },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add ingredient'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _recipeNameCtrl.text.trim().isEmpty || _draftIngredients.isEmpty
                  ? null
                  : () {
                      final name = _recipeNameCtrl.text.trim();
                      final prep = int.tryParse(_prepTimeCtrl.text) ?? 30;
                      ref.read(mealsControllerProvider).addRecipe(name, prep, List.from(_draftIngredients));
                      setState(() {
                        _recipeNameCtrl.clear();
                        _draftIngredients.clear();
                        _prepTimeCtrl.text = '30';
                      });
                      FocusScope.of(context).unfocus();
                    },
              child: const Text('Save to Recipe Box'),
            ),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          carouselSection,
          const SizedBox(height: 36),
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: recipeBoxSection),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: recipeForm),
              ],
            ),
          ] else ...[
            recipeBoxSection,
            const SizedBox(height: 32),
            recipeForm,
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}