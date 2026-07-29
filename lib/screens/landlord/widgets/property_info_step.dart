import 'package:flutter/material.dart';

class PropertyInfoStep extends StatelessWidget {
  final TextEditingController propertyNameController;
  final TextEditingController descriptionController;
  final String propertyType;
  final ValueChanged<String?> onPropertyTypeChanged;

  const PropertyInfoStep({
    super.key,
    required this.propertyNameController,
    required this.descriptionController,
    required this.propertyType,
    required this.onPropertyTypeChanged,
  });

  static const List<DropdownMenuItem<String>> _propertyTypes = [
    DropdownMenuItem(
      value: 'apartment',
      child: Text('Apartment'),
    ),
    DropdownMenuItem(
      value: 'flats',
      child: Text('Flats'),
    ),
    DropdownMenuItem(
      value: 'house',
      child: Text('House'),
    ),
    DropdownMenuItem(
      value: 'villa',
      child: Text('Villa'),
    ),
    DropdownMenuItem(
      value: 'hostel',
      child: Text('Hostel'),
    ),
    DropdownMenuItem(
      value: 'bedsitter',
      child: Text('Bedsitter'),
    ),
    DropdownMenuItem(
      value: 'studio',
      child: Text('Studio'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Property Information",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Enter the basic information about your property.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: propertyNameController,
              decoration: const InputDecoration(
                labelText: "Property Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Property name is required";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: propertyType.isEmpty ? null : propertyType,
              decoration: const InputDecoration(
                labelText: "Property Type",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_work),
              ),
              items: _propertyTypes,
              onChanged: onPropertyTypeChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please select a property type";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a description";
                }
                if (value.trim().length < 20) {
                  return "Description should be at least 20 characters";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
