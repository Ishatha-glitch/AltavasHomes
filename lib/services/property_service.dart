import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // Create Property
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
    final response = await _supabase
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
        .select()
        .single();

    return response['id'];
  }

  // Save Amenities
  static Future<void> saveAmenities({
    required String propertyId,
    required List<String> amenities,
  }) async {
    if (amenities.isEmpty) return;

    await _supabase
        .from('properties')
        .update({
          'amenities': amenities,
        })
        .eq('id', propertyId);
  }

  // Save Blocks
  static Future<void> saveBlocks({
    required String propertyId,
    required List<Map<String, dynamic>> blocks,
  }) async {
    if (blocks.isEmpty) return;

    for (final block in blocks) {
      await _supabase
          .from('property_blocks')
          .insert({
            'property_id': propertyId,
            'name': block['name'],
            'floors': block['floors'],
          });
    }
  }

  // Save Units
  static Future<void> saveUnits({
    required String propertyId,
    required List<Map<String, dynamic>> units,
  }) async {
    if (units.isEmpty) return;

    for (final unit in units) {
      await _supabase
          .from('property_units')
          .insert({
            'property_id': propertyId,
            ...unit,
          });
    }
  }

  // Upload Images
  static Future<List<String>> uploadImages({
    required String propertyId,
    required List<Uint8List> images,
  }) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final path =
          '$propertyId/image_$i.jpg';

      await _supabase.storage
          .from('property-images')
          .uploadBinary(
            path,
            images[i],
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      urls.add(
        _supabase.storage
            .from('property-images')
            .getPublicUrl(path),
      );
    }

    return urls;
  }

  // Save Image URLs
  static Future<void> saveImages({
    required String propertyId,
    required List<String> imageUrls,
  }) async {
    await _supabase
        .from('properties')
        .update({
          'images': imageUrls,
        })
        .eq('id', propertyId);
  }

  // Publish Property
  static Future<void> publishProperty(
    String propertyId,
  ) async {
    await _supabase
        .from('properties')
        .update({
          'status': 'published',
        })
        .eq('id', propertyId);
  }
}
