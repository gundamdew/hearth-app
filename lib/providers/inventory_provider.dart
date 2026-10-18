import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import 'notifications_provider.dart';

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  return FirebaseFirestore.instance.collection('inventory').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => InventoryItem.fromFirestore(doc.data(), doc.id)).toList(),
  );
});

final inventoryControllerProvider = Provider((ref) => InventoryController(ref));

class InventoryController {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  InventoryController(this._ref);

  Future<void> addItem(String name, String location, int quantity, String unit, int threshold) async {
    final item = InventoryItem(
      id: '',
      name: name,
      location: location,
      quantity: quantity,
      unit: unit,
      lowStockThreshold: threshold,
    );
    await _db.collection('inventory').add(item.toMap());
  }

  Future<void> updateQuantity(
    String id,
    int currentQty,
    int delta, {
    InventoryItem? item,
    String? actorName,
  }) async {
    final newQty = (currentQty + delta).clamp(0, 999);
    await _db.collection('inventory').doc(id).update({'quantity': newQty});

    InventoryItem? target = item;
    if (target == null) {
      final doc = await _db.collection('inventory').doc(id).get();
      final data = doc.data();
      if (data != null) {
        target = InventoryItem.fromFirestore(data, doc.id);
      }
    }

    if (target != null && delta < 0 && newQty <= target.lowStockThreshold) {
      await _ref.read(notificationControllerProvider).dispatchNotification(
        title: 'Running Low: ${target.name}',
        body: 'Only $newQty ${target.unit} left in ${target.location}.',
        category: 'inventory',
        actorName: actorName ?? 'Inventory',
      );
    }
  }

  Future<void> removeItem(String id) async {
    await _db.collection('inventory').doc(id).delete();
  }

  /// Массовый импорт из текстового списка покупок
  Future<int> bulkAddFromText(String rawText, List<InventoryItem> existingItems) async {
    final lines = rawText.split('\n');
    final batch = _db.batch();
    int processedCount = 0;

    // Регулярное выражение ищет: [Начало строки без маркеров] [Название] [- / – / — / :] [Число] [Ед. изм.]
    final regex = RegExp(r'^[\s\*\-\•\d\.]*(.+?)\s*[\–\-\—\:]\s*(\d+)\s*(.*)$');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final rawName = match.group(1)?.trim() ?? '';
        final qty = int.tryParse(match.group(2) ?? '1') ?? 1;
        var rawUnit = match.group(3)?.trim() ?? 'szt.';

        if (rawName.isEmpty) {
          continue;
        }
        if (rawUnit.isEmpty) {
          rawUnit = 'szt.';
        }

        // Проверяем, существует ли уже такой продукт в базе (без учета регистра)
        final existingIndex = existingItems.indexWhere(
          (item) => item.name.toLowerCase() == rawName.toLowerCase(),
        );

        if (existingIndex != -1) {
          // Продукт уже есть — увеличиваем количество
          final existing = existingItems[existingIndex];
          final docRef = _db.collection('inventory').doc(existing.id);
          batch.update(docRef, {
            'quantity': FieldValue.increment(qty),
          });
        } else {
          // Продукта нет — создаем новый документ и определяем категорию хранения
          final docRef = _db.collection('inventory').doc();
          final location = _guessLocation(rawName);
          final newItem = InventoryItem(
            id: docRef.id,
            name: rawName,
            location: location,
            quantity: qty,
            unit: rawUnit,
            lowStockThreshold: 1,
          );
          batch.set(docRef, newItem.toMap());
        }
        processedCount++;
      }
    }

    if (processedCount > 0) {
      await batch.commit();
    }
    return processedCount;
  }

  /// Автоматическая категоризация для польских и английских названий
  String _guessLocation(String name) {
    final lower = name.toLowerCase();
    
    if (lower.contains('płyn') || lower.contains('ręcznik') || lower.contains('folia') || 
        lower.contains('mydło') || lower.contains('papier') || lower.contains('worki')) {
      return 'Household';
    }
    
    if (lower.contains('parówki') || lower.contains('kurczak') || lower.contains('salami') || 
        lower.contains('ser') || lower.contains('masło') || lower.contains('jajka') || 
        lower.contains('śmietana') || lower.contains('mleko') || lower.contains('jogurt') ||
        lower.contains('mięso') || lower.contains('szynka')) {
      return 'Fridge';
    }
    
    return 'Pantry';
  }
}