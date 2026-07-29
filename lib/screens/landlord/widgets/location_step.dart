import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationStep extends StatelessWidget {
  final TextEditingController countryController;
  final TextEditingController countyController;
  final TextEditingController townController;
  final TextEditingController estateController;
  final TextEditingController streetController;

  final double? latitude;
  final double? longitude;

  final Function(double, double) onLocationCaptured;

  const LocationStep({
    super.key,
    required this.countryController,
    required this.countyController,
    required this.townController,
    required this.estateController,
    required this.streetController,
    required this.latitude,
    required this.longitude,
    required this.onLocationCaptured,
  });

  Future<void> _captureLocation(BuildContext context) async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permission denied.",
          ),
        ),
      );
      return;
    }

    final position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    onLocationCaptured(
      position.latitude,
      position.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [

        TextFormField(
          controller: countryController,
          decoration: const InputDecoration(
            labelText: "Country",
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.isEmpty
                  ? "Required"
                  : null,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: countyController,
          decoration: const InputDecoration(
            labelText: "County",
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.isEmpty
                  ? "Required"
                  : null,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: townController,
          decoration: const InputDecoration(
            labelText: "Town / City",
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.isEmpty
                  ? "Required"
                  : null,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: estateController,
          decoration: const InputDecoration(
            labelText: "Estate / Neighborhood",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: "Street",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: () => _captureLocation(context),
          icon: const Icon(Icons.location_on),
          label: Text(
            latitude == null
                ? "Capture GPS Location"
                : "Recapture GPS Location",
          ),
        ),

        const SizedBox(height: 20),

        if (latitude != null && longitude != null)
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Latitude: ${latitude!.toStringAsFixed(6)}",
                  ),
                  Text(
                    "Longitude: ${longitude!.toStringAsFixed(6)}",
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
