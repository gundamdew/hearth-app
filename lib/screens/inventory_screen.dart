import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';
  
  final TextEditingController _newItemNameCtrl = TextEditingController();
  final TextEditingController _newItemQtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _searchController.dispose();
    _newItemNameCtrl.dispose();
    _newItemQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    
    final baseList = _activeFilter == 'Running low' 
        ? inventory.where((item) => item.isRunningLow).toList() 
        : inventory;

    final filteredInventory = baseList.where((item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final shoppingList = inventory.where((item) => item.isRunningLow).toList();

    final Map<String, List<InventoryItem>> groupedInventory = {};
    for (var item in filteredInventory) {
      groupedInventory.putIfAbsent(item.location, () => []).add(item);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Running low', count: shoppingList.length),
                  const Spacer(),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
                          child: Text(location.toUpperCase(), style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                        ),
                        ...items.map((item) => _buildInventoryItemRow(context, ref, item)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddItemCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryItemRow(BuildContext context, WidgetRef ref, InventoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (item.isRunningLow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('LOW', style: TextStyle(color: AppTheme.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text('Restock below ${item.lowStockThreshold}', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () => ref.read(inventoryProvider.notifier).updateQuantity(item.id, -1)),
              SizedBox(width: 60, child: Text('${item.quantity} ${item.unit}', textAlign: TextAlign.center, style: GoogleFonts.dmMono(fontSize: 14))),
              IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () => ref.read(inventoryProvider.notifier).updateQuantity(item.id, 1)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.red),
                onPressed: () => ref.read(inventoryProvider.notifier).removeItem(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {int? count}) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? AppTheme.textDark : Colors.transparent, borderRadius: BorderRadius.circular(20), border: isActive ? null : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2))),
        child: Text(count != null ? '$label  $count' : label, style: TextStyle(color: isActive ? Colors.white : AppTheme.textLight)),
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
            TextField(
              controller: _newItemNameCtrl, 
              decoration: InputDecoration(hintText: 'Item name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newItemQtyCtrl, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(hintText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                onPressed: () {
                  if (_newItemNameCtrl.text.isNotEmpty) {
                    final qty = int.tryParse(_newItemQtyCtrl.text) ?? 1;
                    ref.read(inventoryProvider.notifier).addItem(_newItemNameCtrl.text, 'Pantry', qty, 'pcs', 1);
                    _newItemNameCtrl.clear();
                    FocusScope.of(context).unfocus();
                  }
                }, 
                child: const Text('Add to inventory')
              )
            ),
          ],
        ),
      ),
    );
  }
}