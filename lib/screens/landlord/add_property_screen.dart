import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/db.dart';

class AddPropertyScreen extends StatefulWidget {
  final Map<String, dynamic>? property;
  const AddPropertyScreen({super.key, this.property});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  late final _title = TextEditingController(text: widget.property?['title'] ?? '');
  late final _description = TextEditingController(text: widget.property?['description'] ?? '');
  late final _address = TextEditingController(text: widget.property?['address'] ?? '');
  late final _bedrooms = TextEditingController(text: '${widget.property?['bedrooms'] ?? 1}');
  late final _bathrooms = TextEditingController(text: '${widget.property?['bathrooms'] ?? 1}');
  late final _rent = TextEditingController(text: _initialRentText());

  double? _lat;
  double? _lng;
  List<String> _existingImageUrls = [];
  final List<XFile> _newImages = [];
  bool _loading = false;

  bool get _isEditing => widget.property != null;

  String _initialRentText() {
    if (widget.property == null) return '';
    final value = (widget.property!['rent_amount'] as num?)?.toDouble() ?? 0;
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _lat = (widget.property!['latitude'] as num?)?.toDouble();
      _lng = (widget.property!['longitude'] as num?)?.toDouble();
      _existingImageUrls = List<String>.from(widget.property!['images'] ?? []);
    }
  }

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
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location captured: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _newImages.add(picked));
  }

  Future<List<String>> _uploadImages(String propertyId) async {
    final urls = <String>[];
    for (final img in _newImages) {
      final ext = img.path.split('.').last;
      final fileName = '$propertyId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await img.readAsBytes();
      await Db.client.storage.from('property-images').uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
      urls.add(Db.client.storage.from('property-images').getPublicUrl(fileName));
    }
    return urls;
  }

  Future<void> _submit() async {
    if (_title.text.isEmpty || _rent.text.isEmpty || _lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, rent amount, and GPS location are required.')),
      );
      return;
    }
    setState(() => _loading = true);
    final profile = context.read<AuthProvider>().profile!;

    try {
      final fields = {
        'landlord_id': profile['id'],
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'bedrooms': int.tryParse(_bedrooms.text) ?? 1,
        'bathrooms': int.tryParse(_bathrooms.text) ?? 1,
        'rent_amount': double.tryParse(_rent.text) ?? 0,
      };

      late final String propertyId;
      if (_isEditing) {
        propertyId = widget.property!['id'] as String;
        await Db.client.from('properties').update(fields).eq('id', propertyId);
      } else {
        final inserted = await Db.client.from('properties').insert(fields).select().single();
        propertyId = inserted['id'] as String;
      }

      if (_newImages.isNotEmpty) {
        final newUrls = await _uploadImages(propertyId);
        await Db.client
            .from('properties')
            .update({'images': [..._existingImageUrls, ...newUrls]})
            .eq('id', propertyId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Property updated!' : 'Property listed!')),
        );
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit property' : 'List a new property')),
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
              label: Text(_lat != null ? 'Location captured — tap to recapture' : 'Capture GPS location at the house'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text('Add photo (${_existingImageUrls.length + _newImages.length} total)'),
            ),
            if (_existingImageUrls.isNotEmpty || _newImages.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImageUrls.map((url) => Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _existingImageUrls.remove(url)),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    ..._newImages.map((img) => Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(img.path), width: 70, height: 70, fit: BoxFit.cover),
                          ),
                        )),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Publish Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
