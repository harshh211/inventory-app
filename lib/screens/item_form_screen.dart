import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

/// Reused for both Add and Edit. If [existing] is null we add, otherwise update.
class ItemFormScreen extends StatefulWidget {
  final Item? existing;
  const ItemFormScreen({super.key, this.existing});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _service = FirestoreService();

  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _qtyController = TextEditingController(
        text: widget.existing?.quantity.toString() ?? '');
    _priceController = TextEditingController(
        text: widget.existing?.price.toString() ?? '');
  }

  @override
  void dispose() {
    // Always dispose controllers to prevent leaks.
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateQty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Quantity is required';
    final n = int.tryParse(v);
    if (n == null) return 'Must be a whole number';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  String? _validatePrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    final n = double.tryParse(v);
    if (n == null) return 'Must be a valid number';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = Item(
      name: _nameController.text.trim(),
      quantity: int.parse(_qtyController.text),
      price: double.parse(_priceController.text),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.existing == null) {
        await _service.addItem(item);
      } else {
        await _service.updateItem(widget.existing!.id!, item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Item' : 'Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateQty,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: _validatePrice,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEdit ? 'Update Item' : 'Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}