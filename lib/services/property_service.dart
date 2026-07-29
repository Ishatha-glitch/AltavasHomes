import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  static final _db = Supabase.instance.client;

  // Create a property
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
    final response = await _db
        .from('properties')
        .insert({
          'landlord_id': landlordId,
          'name': propertyName,
          'property_type': propertyType,
          'description': description,
          'country': country,
          'county': county,
          'town': town,
          'estate': estate,
          'street': street,
          'latitude': latitude,
          'longitude': longitude,
          'published': false,
        })
        .select()
        .single();

    return response['id'] as String;
  }

  // Save amenities
  static Future<void> saveAmenities({
    required String propertyId,
    required List<String> amenities,
  }) async {
    if (amenities.isEmpty) return;

    final rows = amenities
        .map((item) => {
              'property_id': propertyId,
              'amenity': item,
            })
        .toList();

    await _db.from('property_amenities').insert(rows);
  }

  // Save apartment blocks
  static Future<void> saveBlocks({
    required String propertyId,
    required List<Map<String, dynamic>> blocks,
  }) async {
    if (blocks.isEmpty) return;

    final rows = blocks
        .map((block) => {
              'property_id': propertyId,
              'block_name': block['name'],
              'floors': block['floors'],
            })
        .toList();

    await _db.from('property_blocks').insert(rows);
  }

  // Save generated units
  static Future<void> saveUnits({
    required String propertyId,
    required List<Map<String, dynamic>> units,
  }) async {
    if (units.isEmpty) return;

    final rows = units
        .map((unit) => {
              'property_id': propertyId,
              'block_name': unit['block'],
              'floor': unit['floor'],
              'unit_number': unit['unit_number'],
              'occupied': unit['occupied'],
            })
        .toList();

    await _db.from('property_units').insert(rows);
  }

  // Upload property images
  static Future<List<String>> uploadImages({
    required String propertyId,
    required List<Uint8List> images,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < images.length; i++) {
      final path = '$propertyId/image_$i.jpg';

      await _db.storage
          .from('property-images')
          .uploadBinary(path, images[i]);

      urls.add(
        _db.storage
            .from('property-images')
            .getPublicUrl(path),
      );
    }

    return urls;
  }

  // Save image URLs
  static Future<void> saveImages({
    required String propertyId,
    required List<String> imageUrls,
  }) async {
    if (imageUrls.isEmpty) return;

    final rows = imageUrls
        .map((url) => {
              'property_id': propertyId,
              'image_url': url,
            })
        .toList();

    await _db.from('property_images').insert(rows);
  }

  // Publish property
  static Future<void> publishProperty(
    String propertyId,
  ) async {
    await _db
        .from('properties')
        .update({
          'published': true,
        })
        .eq('id', propertyId);
  }
}
