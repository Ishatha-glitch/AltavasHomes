import 'package:flutter/material.dart';

class AmenitiesStep extends StatefulWidget {
  final List<String> selectedAmenities;
  final ValueChanged<List<String>> onChanged;

  const AmenitiesStep({
    super.key,
    required this.selectedAmenities,
    required this.onChanged,
  });

  @override
  State<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends State<AmenitiesStep> {
  late List<String> _selected;

  static const List<Map<String, dynamic>> _amenities = [
    {"name": "Parking", "icon": Icons.local_parking},
    {"name": "Wi-Fi", "icon": Icons.wifi},
    {"name": "CCTV", "icon": Icons.videocam},
    {"name": "Security Guard", "icon": Icons.security},
    {"name": "Electric Fence", "icon": Icons.electric_bolt},
    {"name": "Swimming Pool", "icon": Icons.pool},
    {"name": "Gym", "icon": Icons.fitness_center},
    {"name": "Lift", "icon": Icons.elevator},
    {"name": "Borehole", "icon": Icons.water_drop},
    {"name": "Backup Generator", "icon": Icons.power},
    {"name": "Children Playground", "icon": Icons.child_care},
    {"name": "Garden", "icon": Icons.yard},
    {"name": "Laundry Area", "icon": Icons.local_laundry_service},
    {"name": "Garbage Collection", "icon": Icons.delete_outline},
    {"name": "Pet Friendly", "icon": Icons.pets},
    {"name": "Balcony", "icon": Icons.balcony},
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedAmenities);
  }

  void _toggle(String amenity) {
    setState(() {
      if (_selected.contains(amenity)) {
        _selected.remove(amenity);
      } else {
        _selected.add(amenity);
      }
    });

    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Property Amenities",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Select all amenities available in your property.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

         
