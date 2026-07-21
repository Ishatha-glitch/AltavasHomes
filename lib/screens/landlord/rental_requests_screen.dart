import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';

const _statusColors = {
  'pending': Color(0xFFF59E0B),
  'approved': Color(0xFF16A34A),
  'declined': Color(0xFFEF4444),
};

class RentalRequestsScreen extends StatefulWidget {
  const RentalRequestsScreen({super.key});

  @override
  State<RentalRequestsScreen> createState() => _RentalRequestsScreenState();
}

class _RentalRequestsScreenState extends State<RentalRequestsScreen> {
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
    final profile = context.read<AuthProvider>().profile!;
    final data = await Db.client
        .from('rental_requests')
        .select('*, properties(title, address, rent_amount, currency), profiles!rental_requests_tenant_id_fkey(full_name, phone)')
        .eq('landlord_id', profile['id'])
        .order('created_at', ascending: false);
    setState(() {
      _requests = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _approve(String id) async {
    setState(() => _actingOnId = id);
    try {
      await Db.client.rpc('approve_rental_request', params: {'request_id': id});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not approve: $e')));
      }
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  Future<void> _decline(String id) async {
    setState(() => _actingOnId = id);
    try {
      await Db.client.rpc('decline_rental_request', params: {'request_id': id});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not decline: $e')));
      }
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
              ? const Center(child: Text('No requests yet.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, i) {
                      final r = _requests[i];
                      final property = r['properties'];
                      final tenant = r['profiles'];
                      final status = r['status'] as String;
                      final busy = _actingOnId == r['id'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(property?['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                  Text(status, style: TextStyle(color: _statusColors[status], fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              Text(property?['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text('From: ${tenant?['full_name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (tenant?['phone'] != null) Text(tenant['phone'], style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text('${property?['currency']} ${property?['rent_amount']}/mo'),
                              Text(DateFormat('EEE, MMM d · h:mm a').format(DateTime.parse(r['created_at'])), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              if (status == 'pending') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: busy ? null : () => _approve(r['id']),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: busy ? null : () => _decline(r['id']),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
