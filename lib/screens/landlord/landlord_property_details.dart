import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/property_service.dart';
import 'edit_property_screen.dart';

class LandlordPropertyDetails extends StatefulWidget {
  final Map<String, dynamic> property;

  const LandlordPropertyDetails({
    super.key,
    required this.property,
  });

  @override
  State<LandlordPropertyDetails> createState() =>
      _LandlordPropertyDetailsState();
}

class _LandlordPropertyDetailsState
    extends State<LandlordPropertyDetails> {

  final supabase = Supabase.instance.client;

  late Map<String, dynamic> _property;

  bool _loadingUnits = true;
  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _loadingUnits = true);

    try {
      final unitsResult = await supabase
          .from('property_units')
          .select()
          .eq('property_id', _property['id'])
          .order('unit_number');

      final units = List<Map<String, dynamic>>.from(unitsResult);

      final occupiedIds = units
          .where((u) => u['status'] == 'occupied')
          .map((u) => u['id'] as String)
          .toList();

      Map<String, Map<String, dynamic>> tenantsByUnit = {};

      if (occupiedIds.isNotEmpty) {
        final leases = await supabase
            .from('leases')
            .select('unit_id, profiles!leases_tenant_id_fkey(full_name, phone)')
            .eq('active', true)
            .filter('unit_id', 'in', '(${occupiedIds.join(",")})');

        for (final lease in List<Map<String, dynamic>>.from(leases)) {
          tenantsByUnit[lease['unit_id']] = lease['profiles'] ?? {};
        }
      }

      final unitsWithTenants = units.map((u) {
        return {
          ...u,
          'tenant': tenantsByUnit[u['id']],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _units = unitsWithTenants;
        _loadingUnits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load units: $e')),
      );
    }
  }

  Future<void> _editProperty() async {
    final updated = await context.push<Map<String, dynamic>>(
      '/landlord/edit-property',
      extra: _property,
    );

    if (updated != null && mounted) {
      setState(() => _property = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete property?'),
        content: Text(
          'This permanently deletes "${_property["property_name"] ?? "this property"}" '
          'and all of its blocks and units. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PropertyService.deleteProperty(_property['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property deleted.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete property: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;
    final images = List<String>.from(property['images'] ?? []);

    final occupiedCount = _units.where((u) => u['status'] == 'occupied').length;
    final vacantCount = _units.length - occupiedCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          property['property_name'] ??
              property['title'] ??
              'Property',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Property',
            onPressed: _editProperty,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Property',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUnits,
        child: ListView(
          children: [

            if (images.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(
                    Icons.home,
                    size: 80,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    property['property_name'] ??
                        property['title'] ??
                        '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    property['property_type'] ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 20),

                  Text(property['description'] ?? ''),

                  const SizedBox(height: 30),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on),
                    title: Text(
                      property['estate'] ??
                          property['town'] ??
                          '',
                    ),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment),
                    title: Text(
                      _loadingUnits
                          ? "Loading units..."
                          : "${_units.length} Units",
                    ),
                    subtitle: _loadingUnits
                        ? null
                        : Text(
                            "$occupiedCount occupied · $vacantCount vacant",
                          ),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle),
                    title: Text(property['status'] ?? 'Draft'),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Units',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 12),

                  if (_loadingUnits)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_units.isEmpty)
                    const Text(
                      'No units added yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._units.map((unit) {
                      final occupied = unit['status'] == 'occupied';
                      final tenant = unit['tenant'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            Icons.door_front_door,
                            color: occupied ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                          ),
                          title: Text('Unit ${unit['unit_number']}'),
                          subtitle: Text(
                            occupied && tenant != null
                                ? 'Floor ${unit['floor'] ?? '-'} · Tenant: ${tenant['full_name'] ?? 'Unknown'}'
                                : 'Floor ${unit['floor'] ?? '-'} · KES ${unit['monthly_rent']}/mo',
                          ),
                          trailing: Text(
                            occupied ? 'OCCUPIED' : 'VACANT',
                            style: TextStyle(
                              color: occupied ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
