import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/property_service.dart';
import 'widgets/amenities_step.dart';

class EditPropertyScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _countyController;
  late final TextEditingController _townController;
  late final TextEditingController _estateController;
  late final TextEditingController _streetController;

  late String _propertyType;
  late List<String> _amenities;

  bool _saving = false;

  static const List<String> _propertyTypes = [
    'apartment',
    'bungalow',
    'maisonette',
    'hostel',
    'studio',
    'commercial',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.property;

    _nameController = TextEditingController(text: p['property_name'] ?? '');
    _descriptionController = TextEditingController(text: p['description'] ?? '');
    _countyController = TextEditingController(text: p['county'] ?? '');
    _townController = TextEditingController(text: p['town'] ?? '');
    _estateController = TextEditingController(text: p['estate'] ?? '');
    _streetController = TextEditingController(text: p['street'] ?? '');

    _propertyType = _propertyTypes.contains(p['property_type'])
        ? p['property_type']
        : 'apartment';

    _amenities = List<String>.from(p['amenities'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countyController.dispose();
    _townController.dispose();
    _estateController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await PropertyService.updateProperty(
        propertyId: widget.property['id'],
        propertyName: _nameController.text.trim(),
        propertyType: _propertyType,
        description: _descriptionController.text.trim(),
        county: _countyController.text.trim(),
        town: _townController.text.trim(),
        estate: _estateController.text.trim(),
        street: _streetController.text.trim(),
        amenities: _amenities,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated.')),
      );

      // Return the updated fields so the details screen can refresh without a re-fetch.
      context.pop({
        ...widget.property,
        'property_name': _nameController.text.trim(),
        'property_type': _propertyType,
        'description': _descriptionController.text.trim(),
        'county': _countyController.text.trim(),
        'town': _townController.text.trim(),
        'estate': _estateController.text.trim(),
        'street': _streetController.text.trim(),
        'amenities': _amenities,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update property: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a property name' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: const InputDecoration(
                labelText: 'Property Type',
                border: OutlineInputBorder(),
              ),
              items: _propertyTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _propertyType = v);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _countyController,
              decoration: const InputDecoration(
                labelText: 'County',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _townController,
              decoration: const InputDecoration(
                labelText: 'Town',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _estateController,
              decoration: const InputDecoration(
                labelText: 'Estate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            AmenitiesStep(
              selectedAmenities: _amenities,
              onChanged: (list) => _amenities = list,
            ),
            const SizedBox(height: 30),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Save Changes'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
