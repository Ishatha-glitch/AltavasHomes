import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _requesting = false;
  bool _requested = false;

  Future<void> _requestToRent() async {
    setState(() => _requesting = true);

    try {
      final profile = context.read<AuthProvider>().profile;
      if (profile == null) {
        throw Exception('No profile loaded');
      }

      final propertyRow = await Db.client
          .from('properties')
          .select('landlord_id')
          .eq('id', widget.property['id'])
          .single();

      await Db.client.from('leases').insert({
        'property_id': widget.property['id'],
        'tenant_id': profile['id'],
        'landlord_id': propertyRow['landlord_id'],
        'monthly_rent': widget.property['rent_amount'],
        'active': false,
      });

      if (!mounted) return;
      setState(() {
        _requesting = false;
        _requested = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent — waiting for landlord approval.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send request. Check your connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
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
                if (isVacant) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_requesting || _requested) ? null : _requestToRent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _requesting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _requested ? 'Request sent' : 'Request to rent',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
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
