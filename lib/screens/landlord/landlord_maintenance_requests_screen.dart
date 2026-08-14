import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LandlordMaintenanceRequestsScreen extends StatefulWidget {
  const LandlordMaintenanceRequestsScreen({super.key});

  @override
  State<LandlordMaintenanceRequestsScreen> createState() => _LandlordMaintenanceRequestsScreenState();
}

class _LandlordMaintenanceRequestsScreenState extends State<LandlordMaintenanceRequestsScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final landlordId = supabase.auth.currentUser!.id;

      final properties = await supabase
          .from('properties')
          .select('id')
          .eq('landlord_id', landlordId);

      final propertyIds = List<Map<String, dynamic>>.from(properties).map((p) => p['id']).toList();

      List<Map<String, dynamic>> requests = [];

      if (propertyIds.isNotEmpty) {
        final unitsResult = await supabase
            .from('property_units')
            .select('id')
            .filter('property_id', 'in', '(${propertyIds.join(",")})');

        final unitIds = List<Map<String, dynamic>>.from(unitsResult).map((u) => u['id']).toList();

        if (unitIds.isNotEmpty) {
          final result = await supabase
              .from('maintenance_requests')
              .select('*, profiles!tenant_id(full_name, phone), property_units(unit_number, properties(property_name))')
              .filter('unit_id', 'in', '(${unitIds.join(",")})')
              .order('created_at', ascending: false);

          requests = List<Map<String, dynamic>>.from(result);
        }
      }

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load maintenance requests: $e')),
      );
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'in_progress':
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No maintenance requests yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, i) {
                        final r = _requests[i];
                        final tenant = r['profiles'];
                        final unit = r['property_units'];
                        final property = unit?['properties'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(r['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      (r['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(color: _statusColor(r['status']), fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${property?['property_name'] ?? ''} · Unit ${unit?['unit_number'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if ((r['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r['description']),
                                ],
                                const SizedBox(height: 6),
                                Text('Tenant: ${tenant?['full_name'] ?? 'Unknown'}'),
                                Text(
                                  'Priority: ${(r['priority'] ?? '').toString().toUpperCase()}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      context.push('/service-providers', extra: r['id']);
                                    },
                                    icon: const Icon(Icons.handyman_outlined),
                                    label: const Text('Find a Service Provider'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
