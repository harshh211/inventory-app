import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';
import 'item_form_screen.dart';

/// Sort options for the enhanced sort feature.
enum SortMode { newest, nameAsc, quantityAsc, priceDesc }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortMode _sortMode = SortMode.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Apply search filter and sort to the live list from Firestore.
  List<Item> _applyFilters(List<Item> items) {
    var filtered = items;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    switch (_sortMode) {
      case SortMode.newest:
        break; // already sorted by createdAt desc from Firestore
      case SortMode.nameAsc:
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortMode.quantityAsc:
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortMode.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return filtered;
  }

  Future<void> _confirmDelete(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      await _service.deleteItem(item.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      }
    }
  }

  void _openForm({Item? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        actions: [
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (_) => const [
              PopupMenuItem(value: SortMode.newest, child: Text('Newest')),
              PopupMenuItem(value: SortMode.nameAsc, child: Text('Name A–Z')),
              PopupMenuItem(
                  value: SortMode.quantityAsc, child: Text('Quantity ↑')),
              PopupMenuItem(
                  value: SortMode.priceDesc, child: Text('Price ↓')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced feature 1: live search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _service.streamItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allItems = snapshot.data ?? [];
                final items = _applyFilters(allItems);

                if (allItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No items yet.\nTap + to add your first item.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No matches for your search.'),
                  );
                }

                // Total inventory value summary in the header.
                final totalValue =
                    allItems.fold<double>(0, (sum, i) => sum + i.totalValue);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.indigo.shade50,
                      child: Text(
                        '${allItems.length} items  •  '
                        'Total value: \$${totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  // Enhanced feature 2: low-stock badge
                                  if (item.isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'LOW',
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Qty: ${item.quantity}  •  '
                                '\$${item.price.toStringAsFixed(2)} each',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openForm(existing: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}