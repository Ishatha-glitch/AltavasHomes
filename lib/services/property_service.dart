import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/landlord/widgets/block_configuration_step.dart';

class PropertyService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> createProperty({
    required Map<String, dynamic> propertyData,
    required List<BlockConfiguration> blocks,
  }) async {
    // Create the property
    final property = await _client
        .from('properties')
        .insert(propertyData)
        .select()
        .single();

    final String propertyId = property['id'];

    // Create apartment blocks
    for (final block in blocks) {
      final blockRow = await _client
          .from('property_blocks')
          .insert({
            'property_id': propertyId,
            'name': block.blockName,
            'floors': block.floors,
            'units_per_floor': block.unitsPerFloor,
          })
          .select()
          .single();

      final String blockId = blockRow['id'];

      // Generate every unit automatically
      for (int floor = 1; floor <= block.floors; floor++) {
        for (int unit = 1; unit <= block.unitsPerFloor; unit++) {
          final unitNumber =
              "${block.blockName.toUpperCase()}${floor}${unit.toString().padLeft(2, '0')}";

          await _client.from('property_units').insert({
            'property_id': propertyId,
            'block_id': blockId,
            'floor': floor,
            'unit_number': unitNumber,
            'status': 'vacant',
          });
        }
      }
    }
  }
}
