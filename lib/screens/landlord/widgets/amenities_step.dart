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

  static const List<String> _allAmenities = [
    "Wi-Fi",
    "Parking",
    "CCTV",
    "Security Guard",
    "Electric Fence",
    "Borehole",
    "Water Tank",
    "Swimming Pool",
    "Gym",
    "Lift",
    "Backup Generator",
    "Children Playground",
    "Garden",
    "Balcony",
    "Laundry Area",
    "Garbage Collection",
    "Furnished",
    "Air Conditioning",
    "Hot Shower",
    "Pet Friendly",
    "Electricity Included",
    "Water Included",
    "Internet Included",
    "Wheelchair Accessible",
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedAmenities);
  }

  void _toggleAmenity(String amenity) {
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
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _allAmenities.map((amenity) {
          final selected = _selected.contains(amenity);

          return FilterChip(
            label: Text(amenity),
            selected: selected,
            showCheckmark: true,
            selectedColor: Colors.blue.shade100,
            onSelected: (_) => _toggleAmenity(amenity),
          );
        }).toList(),
      ),
    );
  }
}
