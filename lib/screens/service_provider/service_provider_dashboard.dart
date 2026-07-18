import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';

const _statusColors = {
  'booked': Color(0xFFF59E0B),
  'in_progress': Color(0xFF2563EB),
  'completed': Color(0xFF16A34A),
  'cancelled': Color(0xFFEF4444),
};

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = context.read<AuthProvider>().profile!;
    final data = await Db.client
        .from('service_bookings')
        .select('*, profiles!service_bookings_client_id_fkey(full_name, phone)')
        .eq('service_provider_id', profile['id'])
        .order('scheduled_time', ascending: true);
    setState(() {
      _bookings = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _advance(Map<String, dynamic> booking) async {
    final current = booking['status'];
    final next = current == 'booked' ? 'in_progress' : current == 'in_progress' ? 'completed' : current;
    if (next == current) return;
    await Db.client.from('service_bookings').update({'status': next}).eq('id', booking['id']);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile!;
    final firstName = (profile['full_name'] as String? ?? 'there').split(' ').first;

    final upcomingTotal = _bookings
        .where((b) => b['status'] != 'completed' && b['status'] != 'cancelled')
        .fold<double>(0, (sum, b) => sum + ((b['expected_amount'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi $firstName 👋'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: auth.signOut)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(profile['service_category'] ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expected earnings (upcoming jobs)', style: TextStyle(color: Color(0xFF1E40AF))),
                        const SizedBox(height: 4),
                        Text(upcomingTotal.toStringAsFixed(0), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_bookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(child: Text('No bookings yet.', style: TextStyle(color: Colors.grey))),
                    ),
                  ..._bookings.map((b) => Card(
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
                                  Expanded(child: Text(b['task_description'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                  Text(
                                    (b['status'] as String).replaceAll('_', ' '),
                                    style: TextStyle(color: _statusColors[b['status']], fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Client: ${b['profiles']?['full_name'] ?? ''}'),
                              Text(DateFormat('EEE, MMM d · h:mm a').format(DateTime.parse(b['scheduled_time'])), style: const TextStyle(color: Colors.grey)),
                              Text(b['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('Expected: ${b['expected_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (b['status'] != 'completed' && b['status'] != 'cancelled') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => _advance(b),
                                    child: Text(b['status'] == 'booked' ? 'Mark as In Progress' : 'Mark as Completed'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
