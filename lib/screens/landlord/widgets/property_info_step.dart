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

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [

        TextFormField(
          controller: propertyNameController,
          decoration: const InputDecoration(
            labelText: "Property Name",
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
          value: propertyType,
          decoration: const InputDecoration(
            labelText: "Property Type",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.apartment),
          ),
          items: const [
            DropdownMenuItem(
              value: "apartment",
              child: Text("Apartment"),
            ),
            DropdownMenuItem(
              value: "flats",
              child: Text("Flats"),
            ),
            DropdownMenuItem(
              value: "house",
              child: Text("Standalone House"),
            ),
            DropdownMenuItem(
              value: "hostel",
              child: Text("Hostel"),
            ),
            DropdownMenuItem(
              value: "commercial",
              child: Text("Commercial Building"),
            ),
          ],
          onChanged: onPropertyTypeChanged,
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: descriptionController,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: "Description",
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 20),

        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Tip:\n\nFor apartments and flats you'll configure blocks and house numbers in the next step.",
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
