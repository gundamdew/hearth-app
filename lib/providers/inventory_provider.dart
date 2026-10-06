import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/inventory_item.dart';

class InventoryNotifier extends Notifier<List<InventoryItem>> {
  @override
  List<InventoryItem> build() {
    return [
      InventoryItem(id: '1', name: 'Pasta', location: 'Pantry', quantity: 3, unit: 'boxes', lowStockThreshold: 1),
      InventoryItem(id: '2', name: 'Rice', location: 'Pantry', quantity: 2, unit: 'kg', lowStockThreshold: 1),
      InventoryItem(id: '3', name: 'Canned tomatoes', location: 'Pantry', quantity: 4, unit: 'cans', lowStockThreshold: 1),
      InventoryItem(id: '5', name: 'Eggs', location: 'Fridge', quantity: 8, unit: 'pcs', lowStockThreshold: 6),
    ];
  }

  void updateQuantity(String id, int delta) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: (item.quantity + delta).clamp(0, 999));
      }
      return item;
    }).toList();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, List<InventoryItem>>(() => InventoryNotifier());