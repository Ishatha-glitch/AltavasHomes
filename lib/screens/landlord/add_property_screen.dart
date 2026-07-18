66import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _bedrooms = TextEditingController(text: '1');
  final _bathrooms = TextEditingController(text: '1');
  final _rent = TextEditingController();

  Position? _coords;
  final List<XFile> _images = [];
  bool _loading = false;

  Future<void> _captureLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to pin the exact house location.')),
        );
      }
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _coords = pos);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location captured: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _images.add(picked));
  }

  Future<List<String>> _uploadImages(String propertyId) async {
    final urls = <String>[];
    for (final img in _images) {
      final ext = img.path.split('.').last;
      final fileName = '$propertyId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await img.readAsBytes();
      await Db.client.storage.from('property-images').uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
      urls.add(Db.client.storage.from('property-images').getPublicUrl(fileName));
    }
    return urls;
  }

  Future<void> _submit() async {
    if (_title.text.isEmpty || _rent.text.isEmpty || _coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, rent amount, and GPS location are required.')),
      );
      return;
    }
    setState(() => _loading = true);
    final profile = context.read<AuthProvider>().profile!;

    try {
      final inserted = await Db.client
          .from('properties')
          .insert({
            'landlord_id': profile['id'],
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'address': _address.text.trim(),
            'latitude': _coords!.latitude,
            'longitude': _coords!.longitude,
            'bedrooms': int.tryParse(_bedrooms.text) ?? 1,
            'bathrooms': int.tryParse(_bathrooms.text) ?? 1,
            'rent_amount': double.tryParse(_rent.text) ?? 0,
          })
          .select()
          .single();

      if (_images.isNotEmpty) {
        final urls = await _uploadImages(inserted['id']);
        await Db.client.from('properties').update({'images': urls}).eq('id', inserted['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property listed!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save property: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List a new property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title (e.g. 2BR Apartment in Kilimani)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address / area', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _bedrooms, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _bathrooms, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bathrooms', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _rent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly rent amount', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _captureLocation,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(_coords != null ? 'Location captured — tap to recapture' : 'Capture GPS location at the house'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text('Add photo (${_images.length} added)'),
            ),
            if (_images.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _images
                      .map((img) => Padding(
                            padding: const EdgeInsets.only(right: 8, top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(img.path), width: 70, height: 70, fit: BoxFit.cover),
                            ),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Publish Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
