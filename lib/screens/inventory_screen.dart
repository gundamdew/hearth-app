import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final shoppingList = inventory.where((item) => item.isRunningLow).toList();

    // Группировка по локациям
    final Map<String, List<InventoryItem>> groupedInventory = {};
    for (var item in inventory) {
      groupedInventory.putIfAbsent(item.location, () => []).add(item);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Левая колонка: Фильтры и Список запасов
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Панель фильтров
              Row(
                children: [
                  _buildFilterChip('All', isActive: true),
                  _buildFilterChip('Food'),
                  _buildFilterChip('Household'),
                  _buildFilterChip('Running low', count: shoppingList.length),
                  const Spacer(),
                  // Заглушка поиска
                  Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 16, color: AppTheme.textLight),
                        const SizedBox(width: 8),
                        Text('Search items...', style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Список продуктов по категориям
              Expanded(
                child: ListView.builder(
                  itemCount: groupedInventory.keys.length,
                  itemBuilder: (context, index) {
                    final location = groupedInventory.keys.elementAt(index);
                    final items = groupedInventory[location]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 16),
                          child: Text(
                            location.toUpperCase(),
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                        ...items.map((item) => _buildInventoryItemRow(context, ref, item)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        
        // Правая колонка: Сайдбар (Добавление и Список покупок)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddItemCard(context),
              const SizedBox(height: 24),
              _buildShoppingListCard(context, shoppingList),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {bool isActive = false, int? count}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.textDark : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
      ),
      child: Text(
        count != null ? '$label  $count' : label,
        style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textLight,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildInventoryItemRow(BuildContext context, WidgetRef ref, InventoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Название и статус
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (item.isRunningLow) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LOW',
                        style: TextStyle(
                          color: AppTheme.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Restock below ${item.lowStockThreshold}${item.expirationInfo != null ? '  ·  ${item.expirationInfo}' : ''}',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
            ],
          ),
          
          // Степер количества
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => ref.read(inventoryProvider.notifier).updateQuantity(item.id, -1),
                color: AppTheme.textLight,
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${item.quantity} ${item.unit}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmMono(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => ref.read(inventoryProvider.notifier).updateQuantity(item.id, 1),
                color: AppTheme.textLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add an item', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            _buildSimpleTextField('Item name'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSimpleTextField('Food', isDropdown: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildSimpleTextField('Pantry', isDropdown: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 1, child: _buildSimpleTextField('1')),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildSimpleTextField('pcs', isDropdown: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSimpleTextField('Restock at 1')),
                const SizedBox(width: 12),
                Expanded(child: _buildSimpleTextField('dd.mm.yy', icon: Icons.calendar_today)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Add to inventory'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTextField(String hint, {bool isDropdown = false, IconData? icon}) {
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
          if (isDropdown) Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textLight),
          if (icon != null) Icon(icon, size: 16, color: AppTheme.textLight),
        ],
      ),
    );
  }

  Widget _buildShoppingListCard(BuildContext context, List<InventoryItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shopping list', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Auto-generated from items below their restock threshold.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    'mark bought',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 12, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}