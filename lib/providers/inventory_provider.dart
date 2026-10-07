import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  return FirebaseFirestore.instance.collection('inventory').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => InventoryItem.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final inventoryControllerProvider = Provider((ref) => InventoryController());

class InventoryController {
  final _db = FirebaseFirestore.instance;

  Future<void> addItem(String name, String location, int quantity, String unit, int threshold) async {
    final item = InventoryItem(
      id: '', name: name, location: location, quantity: quantity, unit: unit, lowStockThreshold: threshold
    );
    await _db.collection('inventory').add(item.toMap());
  }

  Future<void> updateQuantity(String id, int currentQty, int delta) async {
    final newQty = (currentQty + delta).clamp(0, 999);
    await _db.collection('inventory').doc(id).update({'quantity': newQty});
  }

  Future<void> removeItem(String id) async {
    await _db.collection('inventory').doc(id).delete();
  }
}