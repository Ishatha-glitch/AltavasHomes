import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final double? distanceKm;

  const PropertyCard({super.key, required this.property, required this.onTap, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final images = (property['images'] as List?)?.cast<String>() ?? [];
    final cover = images.isNotEmpty ? images.first : null;
    final isVacant = property['status'] == 'vacant';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: cover != null
                  ? Image.network(cover, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFF2F2F2), child: const Center(child: Text('No photo', style: TextStyle(color: Colors.grey)))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${property['bedrooms']} bed · ${property['bathrooms']} bath', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('${property['currency']} ${property['rent_amount']}/mo', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (distanceKm != null) Text('${distanceKm!.toStringAsFixed(1)} km away', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                    Text(isVacant ? 'Vacant' : 'Occupied', style: TextStyle(color: isVacant ? const Color(0xFF16A34A) : const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
