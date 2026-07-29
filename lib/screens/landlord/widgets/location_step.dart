import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationStep extends StatefulWidget {
  final TextEditingController countryController;
  final TextEditingController countyController;
  final TextEditingController townController;
  final TextEditingController estateController;
  final TextEditingController streetController;

  final double? latitude;
  final double? longitude;

  final Function(double latitude, double longitude) onLocationCaptured;

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

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _loadingLocation = false;

  Future<void> _captureLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        throw Exception("Location permission denied.");
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      widget.onLocationCaptured(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Property Location",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Enter the property's address and capture its GPS location.",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller: widget.countryController,
            decoration: const InputDecoration(
              labelText: "Country",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty
                    ? "Country is required"
                    : null,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: widget.countyController,
            decoration: const InputDecoration(
              labelText: "County / State",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty
                    ? "County is required"
                    : null,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: widget.townController,
            decoration: const InputDecoration(
              labelText: "Town / City",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty
                    ? "Town is required"
                    : null,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: widget.estateController,
            decoration: const InputDecoration(
              labelText: "Estate / Neighborhood",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: widget.streetController,
            decoration: const InputDecoration(
              labelText: "Street / Road",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _loadingLocation ? null : _captureLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                _loadingLocation
                    ? "Capturing..."
                    : "Capture GPS Location",
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (widget.latitude != null &&
              widget.longitude != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                ),
                title: const Text(
                  "GPS Location Captured",
                ),
                subtitle: Text(
                  "Latitude: ${widget.latitude}\nLongitude: ${widget.longitude}",
                ),
              ),
            ),
        ],
      ),
    );
  }
}
