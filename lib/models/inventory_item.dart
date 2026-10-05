class InventoryItem {
  final String id;
  final String name;
  final String location;
  final int quantity;
  final String unit;
  final int lowStockThreshold;
  final String? expirationInfo; // Опциональное поле для "expires in 2w"

  InventoryItem({
    required this.id,
    required this.name,
    required this.location,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    this.expirationInfo,
  });

  bool get isRunningLow => quantity <= lowStockThreshold;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? location,
    int? quantity,
    String? unit,
    int? lowStockThreshold,
    String? expirationInfo,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expirationInfo: expirationInfo ?? this.expirationInfo,
    );
  }
}