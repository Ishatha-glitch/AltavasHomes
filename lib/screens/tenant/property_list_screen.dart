import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/db.dart';
import '../../widgets/property_card.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  List<Map<String, dynamic>> _properties = [];
  Position? _userLocation;
  bool _mapView = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested != LocationPermission.denied && requested != LocationPermission.deniedForever) {
          _userLocation = await Geolocator.getCurrentPosition();
        }
      } else if (permission != LocationPermission.deniedForever) {
        _userLocation = await Geolocator.getCurrentPosition();
      }
    } catch (_) {
      // location optional — listing still works without it
    }

    final data = await Db.client.from('properties').select().eq('status', 'vacant').order('created_at', ascending: false);
    setState(() {
      _properties = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Home')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('List')),
                      ButtonSegment(value: true, label: Text('Map')),
                    ],
                    selected: {_mapView},
                    onSelectionChanged: (s) => setState(() => _mapView = s.first),
                  ),
                ),
                Expanded(
                  child: _mapView ? _buildMap() : _buildList(),
                ),
              ],
            ),
    );
  }

  Widget _buildList() {
    if (_properties.isEmpty) {
      return const Center(child: Text('No vacant properties yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _properties.length,
      itemBuilder: (context, i) {
        final p = _properties[i];
        double? dist;
        if (_userLocation != null) {
          dist = _distanceKm(_userLocation!.latitude, _userLocation!.longitude, p['latitude'], p['longitude']);
        }
        return PropertyCard(
          property: p,
          distanceKm: dist,
          onTap: () => context.push('/tenant/property', extra: p),
        );
      },
    );
  }

  Widget _buildMap() {
    final markers = _properties.map((p) {
      return Marker(
        markerId: MarkerId(p['id']),
        position: LatLng(p['latitude'], p['longitude']),
        infoWindow: InfoWindow(
          title: p['title'],
          snippet: '${p['currency']} ${p['rent_amount']}/mo',
          onTap: () => context.push('/tenant/property', extra: p),
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_userLocation?.latitude ?? -1.286389, _userLocation?.longitude ?? 36.817223),
        zoom: 12,
      ),
      myLocationEnabled: _userLocation != null,
      markers: markers,
    );
  }
}
