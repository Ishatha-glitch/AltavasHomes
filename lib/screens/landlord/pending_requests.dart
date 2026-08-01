import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _actingOnId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final profile = context.read<AuthProvider>().profile;
      if (profile == null) {
        throw Exception('No profile loaded');
      }

      final data = await Db.client
          .from('leases')
          .select(
            '*, property_units(unit_number, floor, monthly_rent, properties(property_name, estate)), '
            'profiles!leases_tenant_id_fkey(full_name, phone)',
          )
          .eq('landlord_id', profile['id'])
          .eq('active', false)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load requests: $e')),
      );
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    setState(() => _actingOnId = request['id']);
    try {
      await Db.client
          .from('leases')
          .update({'active': true})
          .eq('id', request['id']);

      await Db.client
          .from('property_units')
          .update({
            'status': 'occupied',
            'tenant_id': request['tenant_id'],
          })
          .eq('id', request['unit_id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not approve: $e')),
      );
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    setState(() => _actingOnId = request['id']);
    try {
      await Db.client.from('leases').delete().eq('id', request['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not decline: $e')),
      );
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No pending requests.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, i) {
                      final r = _requests[i];
                      final unit = r['property_units'];
                      final property = unit?['properties'];
                      final tenant = r['profiles'];
                      final busy = _actingOnId == r['id'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property?['property_name'] ?? '',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Unit ${unit?['unit_number'] ?? ''} · Floor ${unit?['floor'] ?? '-'}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text('Requested by: ${tenant?['full_name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (tenant?['phone'] != null)
                                Text(tenant['phone'], style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Proposed rent: KES ${r['monthly_rent']}'),
                              const SizedBox(height: 12),
                              if (busy)
                                const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _reject(r),
                                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _approve(r),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                                        child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
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
