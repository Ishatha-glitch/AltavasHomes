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
            '*, properties(id, title, address, currency, rent_amount), profiles!leases_tenant_id_fkey(full_name)',
          )
          .eq('landlord_id', profile['id'])
          .eq('active', false)
          .isFilter('ended_at', null)
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
        const SnackBar(content: Text('Could not load requests. Check your connection.')),
      );
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    try {
      await Db.client.from('leases').update({'active': true}).eq('id', request['id']);
      await Db.client
          .from('properties')
          .update({'status': 'occupied'})
          .eq('id', request['properties']['id']);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not approve. Check your connection.')),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    try {
      await Db.client.from('leases').delete().eq('id', request['id']);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reject. Check your connection.')),
      );
    }
  }

  String _formatAmount(dynamic amount) {
    final value = (amount as num?)?.toDouble() ?? 0;
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
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
                      final property = r['properties'];
                      final tenantName = r['profiles']?['full_name'] ?? 'Unknown';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(property?['title'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text(property?['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text('Requested by: $tenantName', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Proposed rent: ${property?['currency'] ?? ''} ${_formatAmount(r['monthly_rent'])}'),
                              const SizedBox(height: 12),
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
