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
  final TextEditingController _newItemUnitCtrl = TextEditingController(text: 'szt.');
  final TextEditingController _newItemThresholdCtrl = TextEditingController(text: '1');
  String _selectedLocation = 'Pantry';

  @override
  void dispose() {
    _searchController.dispose();
    _newItemNameCtrl.dispose();
    _newItemQtyCtrl.dispose();
    _newItemUnitCtrl.dispose();
    _newItemThresholdCtrl.dispose();
    super.dispose();
  }

  void _showBulkImportDialog(BuildContext context, List<InventoryItem> existingItems) {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Import Shopping List',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste your message below (format: "* Product – 2 szt."):',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: ' * Płyn uniwersalny – 1 szt.\n * Kurczak – 2 szt.\n * Masło – 6 szt.',
                    hintStyle: TextStyle(color: AppTheme.textLight.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.playlist_add_check, size: 18),
              label: const Text('Import Items'),
              onPressed: () async {
                final rawText = textCtrl.text.trim();
                if (rawText.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);
                final count = await ref
                    .read(inventoryControllerProvider)
                    .bulkAddFromText(rawText, existingItems);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'Successfully imported/updated $count items!'
                            : 'No matching items found. Check the format.',
                      ),
                      backgroundColor: count > 0 ? AppTheme.mossGreen : AppTheme.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final inventoryAsync = ref.watch(inventoryProvider);

    if (inventoryAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.mossGreen));
    }

    final inventory = inventoryAsync.value ?? [];
    
    final baseList = _activeFilter == 'Running low' 
        ? inventory.where((item) => item.isRunningLow).toList() 
        : inventory;

    final filteredInventory = baseList.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final shoppingList = inventory.where((item) => item.isRunningLow).toList();

    final Map<String, List<InventoryItem>> groupedInventory = {};
    for (var item in filteredInventory) {
      groupedInventory.putIfAbsent(item.location, () => []).add(item);
    }

    Widget filterAndSearch = isMobile
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Running low', count: shoppingList.length),
                  _buildPasteListButton(context, inventory),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ],
        )
      : Row(
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Running low', count: shoppingList.length),
            const SizedBox(width: 8),
            _buildPasteListButton(context, inventory),
            const Spacer(),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
          ],
        );

    Widget inventoryList = ListView.builder(
      shrinkWrap: isMobile,
      physics: isMobile ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
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
                style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight),
              ),
            ),
            ...items.map((item) => _buildInventoryItemRow(context, ref, item)),
          ],
        );
      },
    );

    Widget leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filterAndSearch,
        const SizedBox(height: 32),
        isMobile ? inventoryList : Expanded(child: inventoryList),
      ],
    );

    Widget rightPanel = Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add an item', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            TextField(
              controller: _newItemNameCtrl,
              decoration: InputDecoration(
                hintText: 'Item name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLocation,
                  items: ['Pantry', 'Fridge', 'Household']
                      .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLocation = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _newItemUnitCtrl,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _newItemThresholdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_newItemNameCtrl.text.isNotEmpty) {
                  final qty = int.tryParse(_newItemQtyCtrl.text) ?? 1;
                  final threshold = int.tryParse(_newItemThresholdCtrl.text) ?? 1;
                  final unit = _newItemUnitCtrl.text.trim().isEmpty ? 'szt.' : _newItemUnitCtrl.text.trim();
                  ref.read(inventoryControllerProvider).addItem(
                    _newItemNameCtrl.text.trim(),
                    _selectedLocation,
                    qty,
                    unit,
                    threshold,
                  );
                  setState(() {
                    _newItemNameCtrl.clear();
                    _newItemQtyCtrl.text = '1';
                    _newItemUnitCtrl.text = 'szt.';
                    _newItemThresholdCtrl.text = '1';
                  });
                  FocusScope.of(context).unfocus();
                }
              }, 
              child: const Text('Add to inventory'),
            ),
          ],
        ),
      ),
    );

    return isMobile 
      ? SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftPanel, const SizedBox(height: 48), rightPanel]))
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: leftPanel), const SizedBox(width: 48), Expanded(flex: 3, child: rightPanel)]);
  }

  Widget _buildPasteListButton(BuildContext context, List<InventoryItem> inventory) {
    return OutlinedButton.icon(
      onPressed: () => _showBulkImportDialog(context, inventory),
      icon: const Icon(Icons.content_paste_go, size: 16, color: AppTheme.mossGreen),
      label: const Text('Paste list', style: TextStyle(color: AppTheme.mossGreen, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.mossGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildInventoryItemRow(BuildContext context, WidgetRef ref, InventoryItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: AppTheme.red),
      ),
      onDismissed: (direction) {
        ref.read(inventoryControllerProvider).removeItem(item.id);
      },
      child: Container(
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
                      Flexible(child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
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
                IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () => ref.read(inventoryControllerProvider).updateQuantity(item.id, item.quantity, -1)),
                SizedBox(width: 75, child: Text('${item.quantity} ${item.unit}', textAlign: TextAlign.center, style: GoogleFonts.dmMono(fontSize: 14))),
                IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () => ref.read(inventoryControllerProvider).updateQuantity(item.id, item.quantity, 1)),
              ],
            ),
          ],
        ),
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
        decoration: BoxDecoration(
          color: isActive ? AppTheme.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
        ),
        child: Text(count != null ? '$label  $count' : label, style: TextStyle(color: isActive ? Colors.white : AppTheme.textLight)),
      ),
    );
  }
}