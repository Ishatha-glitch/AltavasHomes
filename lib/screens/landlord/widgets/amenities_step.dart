import 'package:flutter/material.dart';

class AmenitiesStep extends StatefulWidget {
  final List<String> selectedAmenities;
  final ValueChanged<List<String>> onChanged;

  const AmenitiesStep({
    super.key,
    required this.selectedAmenities,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> amenities = [
    {
      "name": "Parking",
      "icon": Icons.local_parking,
    },
    {
      "name": "WiFi",
      "icon": Icons.wifi,
    },
    {
      "name": "CCTV",
      "icon": Icons.videocam,
    },
    {
      "name": "Security Guard",
      "icon": Icons.security,
    },
    {
      "name": "Swimming Pool",
      "icon": Icons.pool,
    },
    {
      "name": "Gym",
      "icon": Icons.fitness_center,
    },
    {
      "name": "Lift",
      "icon": Icons.elevator,
    },
    {
      "name": "Borehole",
      "icon": Icons.water_drop,
    },
    {
      "name": "Backup Generator",
      "icon": Icons.electrical_services,
    },
    {
      "name": "Solar Water Heating",
      "icon": Icons.solar_power,
    },
    {
      "name": "Children Playground",
      "icon": Icons.sports_soccer,
    },
    {
      "name": "Garden",
      "icon": Icons.park,
    },
    {
      "name": "Balcony",
      "icon": Icons.balcony,
    },
    {
      "name": "Air Conditioning",
      "icon": Icons.ac_unit,
    },
    {
      "name": "Garbage Collection",
      "icon": Icons.delete_outline,
    },
  ];

  @override
  State<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends State<AmenitiesStep> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = List<String>.from(widget.selectedAmenities);
  }

  void toggleAmenity(String amenity) {
    setState(() {
      if (selected.contains(amenity)) {
        selected.remove(amenity);
      } else {
        selected.add(amenity);
      }
    });

    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amenities",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Select every amenity available in this property.",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: GridView.builder(
              itemCount: AmenitiesStep.amenities.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final amenity = AmenitiesStep.amenities[index];

                final isSelected =
                    selected.contains(amenity["name"]);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      toggleAmenity(amenity["name"]),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          amenity["icon"],
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Flexible
