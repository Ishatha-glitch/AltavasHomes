import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final images = (property['images'] as List?)?.cast<String>() ?? [];
    final lat = property['latitude'] as double;
    final lng = property['longitude'] as double;
    final isVacant = property['status'] == 'vacant';

    return Scaffold(
      appBar: AppBar(title: Text(property['title'] ?? 'Property')),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: images.isEmpty
                ? Container(color: const Color(0xFFF2F2F2), child: const Center(child: Text('No photos yet', style: TextStyle(color: Colors.grey))))
                : PageView(
                    children: images.map((url) => Image.network(url, fit: BoxFit.cover)).toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(property['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text('${property['currency']} ${property['rent_amount']}/month',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('${property['bedrooms']}', 'Bedrooms'),
                    _stat('${property['bathrooms']}', 'Bathrooms'),
                    _stat(isVacant ? 'Vacant' : 'Occupied', 'Status', color: isVacant ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(property['description'] ?? 'No description provided.', style: const TextStyle(height: 1.4)),
                const SizedBox(height: 18),
                const Text('Exact location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 16),
                      markers: {Marker(markerId: const MarkerId('house'), position: LatLng(lat, lng))},
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
