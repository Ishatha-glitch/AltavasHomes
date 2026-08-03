import 'package:flutter/material.dart';

class UnitEditorStep extends StatefulWidget {
  final List<Map<String, dynamic>> units;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const UnitEditorStep({
    super.key,
    required this.units,
    required this.onChanged,
  });

  @override
  State<UnitEditorStep> createState() => _UnitEditorStepState();
}

class _UnitEditorStepState extends State<UnitEditorStep> {
  Future<void> _openUnitForm({Map<String, dynamic>? existing, int? index}) async {
    final unitNumberController =
        TextEditingController(text: existing?['unit_number']?.toString() ?? '');
    final floorController =
        TextEditingController(text: existing?['floor']?.toString() ?? '');
    final bedroomsController =
        TextEditingController(text: existing?['bedrooms']?.toString() ?? '1');
    final bathroomsController =
        TextEditingController(text: existing?['bathrooms']?.toString() ?? '1');
    final rentController =
        TextEditingController(text: existing?['monthly_rent']?.toString() ?? '');
    final depositController =
        TextEditingController(text: existing?['deposit']?.toString() ?? '0');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Unit' : 'Edit Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: unitNumberController,
                decoration: const InputDecoration(labelText: 'Unit Number (e.g. A101)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: floorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Floor (optional)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bedrooms'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bathrooms'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: rentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monthly Rent (KES)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: depositController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Deposit (KES)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (unitNumberController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a unit number.')),
                );
                return;
              }
              final rent = double.tryParse(rentController.text.trim());
              if (rent == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid monthly rent.')),
                );
                return;
              }

              Navigator.pop(context, {
                'unit_number': unitNumberController.text.trim(),
                'floor': int.tryParse(floorController.text.trim()),
                'bedrooms': int.tryParse(bedroomsController.text.trim()) ?? 1,
                'bathrooms': int.tryParse(bathroomsController.text.trim()) ?? 1,
                'monthly_rent': rent,
                'deposit': double.tryParse(depositController.text.trim()) ?? 0,
                'occupied': existing?['occupied'] ?? false,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final updated = List<Map<String, dynamic>>.from(widget.units);
    if (index != null) {
      updated[index] = result;
    } else {
      updated.add(result);
    }
    widget.onChanged(updated);
  }

  void _deleteUnit(int index) {
    final updated = List<Map<String, dynamic>>.from(widget.units)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _openUnitForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add Unit'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.units.isEmpty
              ? const Center(
                  child: Text(
                    'No units added yet.\nTap "Add Unit" to add your first house.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: widget.units.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final unit = widget.units[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.door_front_door)),
                      title: Text('Unit ${unit['unit_number']}'),
                      subtitle: Text(
                        '${unit['floor'] != null ? "Floor ${unit['floor']} · " : ""}'
                        '${unit['bedrooms']} bed · ${unit['bathrooms']} bath · '
                        'KES ${unit['monthly_rent']}/mo',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _openUnitForm(existing: unit, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteUnit(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
