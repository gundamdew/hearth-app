// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../widgets/hearth_ui.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _searchQuery = '';

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _minCtrl = TextEditingController(text: '1');
  String _selectedLoc = 'Pantry';
  String _selectedUnit = 'szt.';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  String _locLabel(String loc) {
    switch (loc) {
      case 'Fridge':
        return 'LODÓWKA';
      case 'Pantry':
        return 'SPIŻARNIA';
      case 'Household':
        return 'CHEMIA DOMOWA';
      default:
        return loc.toUpperCase();
    }
  }

  String _locDisplay(String loc) {
    switch (loc) {
      case 'Fridge':
        return 'Lodówka';
      case 'Pantry':
        return 'Spiżarnia';
      case 'Household':
        return 'Chemia domowa';
      default:
        return loc;
    }
  }

  void _showBulkImportModal(BuildContext context, List<InventoryItem> existingItems) {
    final textCtrl = TextEditingController(
      text: '* Kurczak – 2 szt.\n* Masło – 6 szt.\n- Passata pomidorowa - 3 op.\n• Szpinak – 1 op.',
    );

    showHearthModal(
      context: context,
      title: 'Wklej listę zakupów',
      sub: 'Import zbiorczy',
      child: StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final rawText = textCtrl.text;
          final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
          final regex = RegExp(r'^[\s\*\-\•\d\.]*(.+?)\s*[\–\-\—\:]\s*(\d+)\s*(.*)$');

          final parsedRows = lines.map((line) {
            final match = regex.firstMatch(line);
            if (match != null) {
              final name = match.group(1)?.trim() ?? '';
              final qty = int.tryParse(match.group(2) ?? '1') ?? 1;
              var unit = match.group(3)?.trim() ?? 'szt.';
              if (unit.isEmpty) unit = 'szt.';
              final isExisting = existingItems.any((i) => i.name.toLowerCase() == name.toLowerCase());
              return (isValid: true, line: line, name: name, qty: qty, unit: unit, isExisting: isExisting);
            }
            return (isValid: false, line: line, name: '', qty: 0, unit: '', isExisting: false);
          }).toList();

          final validCount = parsedRows.where((r) => r.isValid).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wklej wiadomość z czatu lub listy. Jedna pozycja w wierszu — Nazwa – ilość jednostka.',
                style: GoogleFonts.instrumentSans(fontSize: 14, color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 6,
                style: GoogleFonts.dmMono(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '* Kurczak – 2 szt.\n* Masło – 6 szt.',
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              Text('PODGLĄD · ROZPOZNANO: $validCount', style: AppTheme.microStyle),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.line),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: parsedRows.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
                  itemBuilder: (context, index) {
                    final row = parsedRows[index];
                    if (row.isValid) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.name,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: row.isExisting
                                    ? AppTheme.sage.withValues(alpha: 0.4)
                                    : AppTheme.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                row.isExisting ? 'AKTUALIZACJA' : 'NOWY',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: row.isExisting ? AppTheme.moss : AppTheme.amber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${row.qty} ${row.unit}',
                              style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.ink),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              row.line,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.muted,
                                decoration: TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: validCount == 0
                      ? null
                      : () async {
                          Navigator.pop(modalCtx);
                          final count = await ref
                              .read(inventoryControllerProvider)
                              .bulkAddFromText(textCtrl.text.trim(), existingItems);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$count pozycji zaktualizowano w spiżarni'),
                                backgroundColor: AppTheme.moss,
                              ),
                            );
                          }
                        },
                  child: const Text('Zaktualizuj spiżarnię'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    final inventoryAsync = ref.watch(inventoryProvider);

    if (inventoryAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.moss));
    }

    final inventory = inventoryAsync.value ?? [];
    final lowCount = inventory.where((i) => i.isRunningLow).length;

    final filtered = inventory.where((item) {
      final matchesFilter = _filter == 'All' || item.isRunningLow;
      final matchesQuery = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    const locations = ['Fridge', 'Pantry', 'Household'];

    final leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter bar & Search
        Wrap(
          spacing: 8,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // All Pill
            GestureDetector(
              onTap: () => setState(() => _filter = 'All'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _filter == 'All' ? AppTheme.moss : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: _filter == 'All' ? null : Border.all(color: AppTheme.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Wszystko',
                  style: TextStyle(
                    color: _filter == 'All' ? Colors.white : AppTheme.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Running low Pill
            GestureDetector(
              onTap: () => setState(() => _filter = 'Running low'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _filter == 'Running low' ? AppTheme.moss : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: _filter == 'Running low' ? null : Border.all(color: AppTheme.line),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kończące się',
                      style: TextStyle(
                        color: _filter == 'Running low' ? Colors.white : AppTheme.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _filter == 'Running low'
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$lowCount',
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          color: _filter == 'Running low' ? Colors.white : AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Paste list Button
            OutlinedButton.icon(
              onPressed: () => _showBulkImportModal(context, inventory),
              icon: const Icon(Icons.paste, size: 16, color: AppTheme.moss),
              label: const Text('Wklej listę', style: TextStyle(color: AppTheme.moss, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.moss.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),

            // Search Bar
            SizedBox(
              width: 220,
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Szukaj produktów...',
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.muted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppTheme.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppTheme.line)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Grouped Items by Location
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64.0),
            child: Center(
              child: Text(
                'Brak pasujących pozycji.',
                style: AppTheme.titleStyle(fontSize: 22, color: AppTheme.muted, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ...locations.map((loc) {
            final locItems = filtered.where((i) => i.location == loc).toList();
            if (locItems.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                    child: Row(
                      children: [
                        Text(_locLabel(loc), style: AppTheme.microStyle),
                        const SizedBox(width: 6),
                        Text('${locItems.length}', style: GoogleFonts.dmMono(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: AppTheme.cardDecoration,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: locItems.length,
                      separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
                      itemBuilder: (context, index) {
                        final item = locItems[index];
                        final isLow = item.isRunningLow;

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: AppTheme.danger,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Usuń', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            ref.read(inventoryControllerProvider).removeItem(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Usunięto ${item.name}'),
                                backgroundColor: AppTheme.ink,
                                action: SnackBarAction(
                                  label: 'COFNIJ',
                                  textColor: AppTheme.sage,
                                  onPressed: () {
                                    ref.read(inventoryControllerProvider).addItem(
                                      item.name,
                                      item.location,
                                      item.quantity,
                                      item.unit,
                                      item.lowStockThreshold,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isLow) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.danger.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'NISKI STAN',
                                                style: GoogleFonts.instrumentSans(
                                                  color: AppTheme.danger,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Uzupełnij poniżej ${item.lowStockThreshold}',
                                        style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.canvas,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppTheme.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 14),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        onPressed: () {
                                          ref.read(inventoryControllerProvider).updateQuantity(item.id, item.quantity, -1);
                                        },
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '${item.quantity} ${item.unit}',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.dmMono(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isLow ? AppTheme.danger : AppTheme.ink,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 14),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        onPressed: () {
                                          ref.read(inventoryControllerProvider).updateQuantity(item.id, item.quantity, 1);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );

    final rightPanel = FormCard(
      sub: 'Zapasy',
      title: 'Dodaj produkt',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nazwa produktu', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'np. Pomidory koktajlowe'),
          ),
          const SizedBox(height: 16),
          Text('Miejsce przechowywania', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
          const SizedBox(height: 6),
          HearthSelect<String>(
            value: _selectedLoc,
            items: locations,
            onChanged: (val) {
              if (val != null) setState(() => _selectedLoc = val);
            },
            labelBuilder: _locDisplay,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ilość', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.dmMono(fontSize: 14),
                      decoration: const InputDecoration(hintText: '1'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jednostka', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    HearthSelect<String>(
                      value: _selectedUnit,
                      items: const ['szt.', 'op.', 'porcja', 'kg', 'l'],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                      labelBuilder: (u) => u,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Min. stan', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.dmMono(fontSize: 14),
                      decoration: const InputDecoration(hintText: '1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final qty = int.tryParse(_qtyCtrl.text) ?? 1;
                  final min = int.tryParse(_minCtrl.text) ?? 1;
                  ref.read(inventoryControllerProvider).addItem(
                    name,
                    _selectedLoc,
                    qty,
                    _selectedUnit,
                    min,
                  );
                  _nameCtrl.clear();
                  _qtyCtrl.text = '1';
                  _minCtrl.text = '1';
                  FocusScope.of(context).unfocus();
                }
              },
              child: const Text('Dodaj do spiżarni'),
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
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: leftPanel),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: rightPanel),
              ],
            ),
          ] else ...[
            leftPanel,
            const SizedBox(height: 32),
            rightPanel,
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}