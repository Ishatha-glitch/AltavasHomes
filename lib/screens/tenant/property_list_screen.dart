import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() =>
      _PropertyListScreenState();
}

class _PropertyListScreenState
    extends State<PropertyListScreen> {

  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  bool loading = true;
  bool _showMap = false;

  List<Map<String, dynamic>> _allProperties = [];
  List<Map<String, dynamic>> _filtered = [];

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => loading = true);

    try {
      final result = await supabase
          .from('properties')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false);

      final props = List<Map<String, dynamic>>.from(result);

      Map<String, int> vacantCounts = {};

      if (props.isNotEmpty) {
        final ids = props.map((p) => p['id'] as String).toList();

        final unitRows = await supabase
            .from('property_units')
            .select('property_id, status')
            .filter('property_id', 'in', '(${ids.join(",")})');

        for (final row in List<Map<String, dynamic>>.from(unitRows)) {
          if (row['status'] == 'vacant') {
            final propId = row['property_id'] as String;
            vacantCounts[propId] = (vacantCounts[propId] ?? 0) + 1;
          }
        }
      }

      // Only show properties that actually have a vacant unit right now.
      final available = props.where((p) {
        return (vacantCounts[p['id']] ?? 0) > 0;
      }).map((p) {
        return {
          ...p,
          'vacant_units': vacantCounts[p['id']] ?? 0,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _allProperties = available;
        _filtered = available;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filtered = _allProperties;
      } else {
        _filtered = _allProperties.where((p) {
          final haystack = [
            p['town'],
            p['estate'],
            p['county'],
            p['street'],
            p['property_name'],
          ].where((v) => v != null).join(' ').toLowerCase();

          return haystack.contains(query);
        }).toList();
      }
    });
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final p in _filtered) {
      final lat = (p['latitude'] as num?)?.toDouble();
      final lng = (p['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(p['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: p['property_name'] ?? '',
            snippet: '${p['vacant_units']} vacant · ${p['estate'] ?? p['town'] ?? ''}',
            onTap: () => context.push('/tenant/property', extra: p),
          ),
          onTap: () => _showPropertySheet(p),
        ),
      );
    }

    return markers;
  }

  void _showPropertySheet(Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property['property_name'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${property['estate'] ?? ''}, ${property['town'] ?? ''}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text('${property['vacant_units']} vacant unit(s)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/tenant/property', extra: property);
                  },
                  child: const Text('View Property'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  CameraPosition _initialCamera() {
    final withLocation = _filtered.where((p) =>
        p['latitude'] != null && p['longitude'] != null).toList();

    if (withLocation.isEmpty) {
      // Default: Nairobi, Kenya
      return const CameraPosition(target: LatLng(-1.286389, 36.817223), zoom: 6);
    }

    final first = withLocation.first;
    return CameraPosition(
      target: LatLng(
        (first['latitude'] as num).toDouble(),
        (first['longitude'] as num).toDouble(),
      ),
      zoom: 12,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Browse Properties"),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            tooltip: _showMap ? 'List view' : 'Map view',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by town, estate or county...',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _searchController.text.isEmpty
                                ? "No vacant properties available right now."
                                : "No vacant properties found in \"${_searchController.text}\".",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : _showMap
                        ? GoogleMap(
                            initialCameraPosition: _initialCamera(),
                            markers: _buildMarkers(),
                            myLocationButtonEnabled: false,
                            onMapCreated: (controller) => _mapController = controller,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProperties,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {

                                final property = _filtered[index];

                                final images =
                                    List<String>.from(property["images"] ?? []);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: InkWell(
                                    onTap: () {
                                      context.push("/tenant/property", extra: property);
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        if (images.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                            child: Image.network(
                                              images.first,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),

                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              Text(
                                                property["property_name"] ??
                                                    property["title"] ??
                                                    "",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              Text(
                                                "${property["estate"] ?? ""}, ${property["town"] ?? ""}",
                                              ),

                                              const SizedBox(height: 8),

                                              Row(
                                                children: [
                                                  Text(property["property_type"] ?? ""),
                                                  const Spacer(),
                                                  Text(
                                                    "${property['vacant_units']} vacant",
                                                    style: const TextStyle(
                                                      color: Color(0xFF16A34A),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
