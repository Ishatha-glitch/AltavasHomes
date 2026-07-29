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

  static const List<Map<String, String>> propertyTypes = [
    {
      "value": "apartment",
      "label": "Apartment",
    },
    {
      "value": "flats",
      "label": "Flats",
    },
    {
      "value": "standalone_house",
      "label": "Standalone House",
    },
    {
      "value": "maisonette",
      "label": "Maisonette",
    },
    {
      "value": "townhouse",
      "label": "Townhouse",
    },
    {
      "value": "hostel",
      "label": "Hostel",
    },
    {
      "value": "commercial",
      "label": "Commercial Building",
    },
    {
      "value": "office",
      "label": "Office Building",
    },
    {
      "value": "shop",
      "label": "Shop",
    },
    {
      "value": "warehouse",
      "label": "Warehouse",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Property Information",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Tell us about your property.",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 25),

        TextFormField(
          controller: propertyNameController,
          decoration: const InputDecoration(
            labelText: "Property Name",
            hintText: "Green Heights Apartments",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_work),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Enter the property name";
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
            prefixIcon: Icon(Icons.apartment),
          ),
          items: propertyTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type["value"],
                  child: Text(type["label"]!),
                ),
              )
              .toList(),
          onChanged: onPropertyTypeChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Select a property type";
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
            hintText:
                "Describe your property, nearby amenities, security, parking, and unique features.",
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Use a clear property name and a detailed description to help tenants discover your listing more easily.",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
