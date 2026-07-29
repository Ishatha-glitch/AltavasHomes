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
  bool _capturing = false;

  Future<void> _captureLocation() async {
    setState(() {
      _capturing = true;
    });

    try {
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Location permission is required.",
              ),
            ),
          );
        }

        setState(() {
          _capturing = false;
        });

        return;
      }

      final position =
          await Geolocator.getCurrentPosition();

      widget.onLocationCaptured(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "GPS location captured successfully.",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to capture location: $e",
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _capturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Property Location",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Enter the physical location of the property.",
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
            prefixIcon: Icon(Icons.public),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Country is required";
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: widget.countyController,
          decoration: const InputDecoration(
            labelText: "County / State",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "County is required";
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: widget.townController,
          decoration: const InputDecoration(
            labelText: "Town / City",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Town is required";
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: widget.estateController,
          decoration: const InputDecoration(
            labelText: "Estate / Neighborhood",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: widget.streetController,
          decoration: const InputDecoration(
            labelText: "Street",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.route),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _capturing ? null : _captureLocation,
          icon: const Icon(Icons.my_location),
          label: Text(
            _capturing
                ? "Capturing..."
                : "Capture GPS Location",
          ),
        ),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: widget.latitude == null
                ? const Text(
                    "No GPS location captured yet.",
                  )
                : Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "GPS Coordinates",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Latitude: ${widget.latitude!.toStringAsFixed(6)}",
                      ),
                      Text(
                        "Longitude: ${widget.longitude!.toStringAsFixed(6)}",
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
