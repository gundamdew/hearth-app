import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/inventory_item.dart';

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  @override
  List<InventoryItem> build() {
    // Тестовые данные, в точности повторяющие макет
    return [
      InventoryItem(id: '1', name: 'Pasta', location: 'Pantry', quantity: 3, unit: 'boxes', lowStockThreshold: 1),
      InventoryItem(id: '2', name: 'Rice', location: 'Pantry', quantity: 2, unit: 'kg', lowStockThreshold: 1),
      InventoryItem(id: '3', name: 'Canned tomatoes', location: 'Pantry', quantity: 4, unit: 'cans', lowStockThreshold: 1),
      InventoryItem(id: '4', name: 'Chickpeas', location: 'Pantry', quantity: 1, unit: 'cans', lowStockThreshold: 1), // LOW
      InventoryItem(id: '5', name: 'Eggs', location: 'Fridge', quantity: 8, unit: 'pcs', lowStockThreshold: 6, expirationInfo: 'expires in 1w'),
      InventoryItem(id: '6', name: 'Spinach', location: 'Fridge', quantity: 1, unit: 'bags', lowStockThreshold: 1, expirationInfo: 'expires in 2d'), // LOW
      InventoryItem(id: '7', name: 'Parmesan', location: 'Fridge', quantity: 1, unit: 'blocks', lowStockThreshold: 1, expirationInfo: 'expires in 2w'), // LOW
      InventoryItem(id: '8', name: 'Chicken thighs', location: 'Freezer', quantity: 2, unit: 'packs', lowStockThreshold: 1),
      InventoryItem(id: '9', name: 'Onions', location: 'Produce', quantity: 5, unit: 'pcs', lowStockThreshold: 2),
      InventoryItem(id: '10', name: 'Garlic', location: 'Produce', quantity: 1, unit: 'heads', lowStockThreshold: 1), // LOW
      InventoryItem(id: '11', name: 'Paper towels', location: 'Paper', quantity: 2, unit: 'rolls', lowStockThreshold: 2), // LOW
      InventoryItem(id: '12', name: 'Laundry detergent', location: 'Laundry', quantity: 1, unit: 'bottles', lowStockThreshold: 1), // LOW
    ];
  }

  void updateQuantity(String id, int delta) {
    state = state.map((item) {
      if (item.id == id) {
        final newQuantity = (item.quantity + delta).clamp(0, 999);
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, List<InventoryItem>>(() {
  return InventoryNotifier();
});