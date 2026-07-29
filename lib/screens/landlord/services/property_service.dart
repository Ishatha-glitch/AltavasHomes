import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/db.dart';

class PropertyService {
  PropertyService._();

  static final SupabaseClient _client = Db.client;

  static Future<String> createProperty({
    required String landlordId,
    required String propertyName,
    required String propertyType,
    required String description,
    required String country,
    required String county,
    required String town,
    required String estate,
    required String street,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client
        .from('properties')
        .insert({
          'landlord_id': landlordId,
          'property_name': propertyName,
          'property_type': propertyType,
          'description': description,
          'country': country,
          'county': county,
          'town': town,
          'estate': estate,
          'street': street,
          'latitude': latitude,
          'longitude': longitude,
          'status': 'draft',
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  static Future<void> saveAmenities({
    required String propertyId,
    required List<String> amenities,
  }) async {
    if (amenities.isEmpty) return;

    final rows = amenities
        .map(
          (amenity) => {
            'property_id': propertyId,
            'amenity_name': amenity,
          },
        )
        .toList();

    await _client.from('property_amenities').insert(rows);
  }

  static Future<void> saveBlocks({
    required String propertyId,
    required List<Map<String, dynamic>> blocks,
  }) async {
    for (final block in blocks) {
      await _client.from('property_blocks').insert({
        'property_id': propertyId,
        'block_name': block['name'],
        'floors': block['floors'],
      });
    }
  }

  static Future<void> saveUnits({
    required String propertyId,
    required List<Map<String, dynamic>> units,
  }) async {
    if (units.isEmpty) return;

    final rows = units
        .map(
          (unit) => {
            'property_id': propertyId,
            'block_name': unit['block'],
            'floor_number': unit['floor'],
            'unit_number': unit['unit_number'],
            'status': 'vacant',
          },
        )
        .toList();

    await _client.from('property_units').insert(rows);
  }

  static Future<List<String>> uploadImages({
    required String propertyId,
    required List<Uint8List> images,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < images.length; i++) {
      final path =
          "$propertyId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

      await _client.storage
          .from("property-images")
          .uploadBinary(path, images[i]);

      urls.add(
        _client.storage
            .from("property-images")
            .getPublicUrl(path),
      );
    }

    return urls;
  }

  static Future<void> saveImages({
    required String propertyId,
    required List<String> imageUrls,
  }) async {
    if (imageUrls.isEmpty) return;

    await _client.from('properties').update({
      'property_images': imageUrls,
    }).eq('id', propertyId);
  }

  static Future<void> publishProperty(
    String propertyId,
  ) async {
    await _client.from('properties').update({
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', propertyId);
  }
}
