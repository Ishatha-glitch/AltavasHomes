import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final supabase = Supabase.instance.client;

  bool _loadingUnits = true;
  List<Map<String, dynamic>> _vacantUnits = [];
  String? _requestingUnitId;

  @override
  void initState() {
    super.initState();
    _loadVacantUnits();
  }

  Future<void> _loadVacantUnits() async {
    try {
      final result = await supabase
          .from('property_units')
          .select()
          .eq('property_id', widget.property['id'])
          .eq('status', 'vacant')
          .order('unit_number');

      if (!mounted) return;
      setState(() {
        _vacantUnits = List<Map<String, dynamic>>.from(result);
        _loadingUnits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
    }
  }

  Future<void> _requestUnit(Map<String, dynamic> unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Unit ${unit["unit_number"]}?'),
        content: Text(
          'This sends a rental request to the landlord for '
          'Unit ${unit["unit_number"]} at KES ${unit["monthly_rent"]}/mo. '
          "They'll need to approve it before it's confirmed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _requestingUnitId = unit['id']);

    try {
      final tenant = context.read<AuthProvider>().profile!;

      await supabase.from('leases').insert({
        'unit_id': unit['id'],
        'landlord_id': widget.property['landlord_id'],
        'tenant_id': tenant['id'],
        'start_date': DateTime.now().toIso8601String().split('T').first,
        'monthly_rent': unit['monthly_rent'],
        'deposit': unit['deposit'],
        'active': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent. Waiting for landlord approval.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send request: $e')),
      );
    } finally {
      if (mounted) setState(() => _requestingUnitId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final List<String> images =
        List<String>.from(property['images'] ?? []);

    final List<String> amenities =
        List<String>.from(property['amenities'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          property['property_name'] ??
              property['title'] ??
              'Property',
        ),
      ),
      body: ListView(
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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

                const SizedBox(height: 12),

                Text(
                  property['property_type'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  property['description'] ??
                      'No description available.',
                ),

                const SizedBox(height: 25),

                const Text(
                  "Location",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "${property['estate'] ?? ''}, "
                  "${property['town'] ?? ''}, "
                  "${property['county'] ?? ''}",
                ),

                const SizedBox(height: 25),

                const Text(
                  "Amenities",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities.isEmpty
                      ? [
                          const Text(
                            "No amenities listed.",
                          ),
                        ]
                      : amenities
                          .map(
                            (item) => Chip(
                              label: Text(item),
                            ),
                          )
                          .toList(),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Available Units",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                if (_loadingUnits)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_vacantUnits.isEmpty)
                  const Text(
                    "No vacant units right now. Check back later.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ..._vacantUnits.map((unit) {
                    final busy = _requestingUnitId == unit['id'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.door_front_door),
                        title: Text("Unit ${unit['unit_number']}"),
                        subtitle: Text(
                          "Floor ${unit['floor'] ?? '-'} · "
                          "${unit['bedrooms'] ?? '-'} bed · "
                          "${unit['bathrooms'] ?? '-'} bath\n"
                          "KES ${unit['monthly_rent']}/mo",
                        ),
                        isThreeLine: true,
                        trailing: busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : FilledButton(
                                onPressed: () => _requestUnit(unit),
                                child: const Text('Request'),
                              ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
