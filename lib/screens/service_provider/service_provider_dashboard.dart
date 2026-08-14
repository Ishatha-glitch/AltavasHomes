import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = context.read<AuthProvider>().profile!;

      final data = await Db.client
          .from('service_bookings')
          .select(
            '*, maintenance_requests('
            'id, title, description, priority, status, '
            'profiles!tenant_id(full_name, phone), '
            'property_units(unit_number, properties(property_name, estate, town))'
            ')',
          )
          .eq('provider_id', profile['id'])
          .order('scheduled_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _advance(Map<String, dynamic> booking) async {
    final current = booking['status'];
    final next = current == 'booked' ? 'in_progress' : current == 'in_progress' ? 'completed' : current;
    if (next == current) return;
    try {
      await Db.client.from('service_bookings').update({'status': next}).eq('id', booking['id']);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile!;
    final firstName = (profile['full_name'] as String? ?? 'there').split(' ').first;

    final upcomingCount = _bookings
        .where((b) => b['status'] != 'completed' && b['status'] != 'cancelled')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi $firstName 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: 'Messages',
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'My profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text('Could not load bookings.\n$_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
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
                            const Text('Upcoming jobs', style: TextStyle(color: Color(0xFF1E40AF))),
                            const SizedBox(height: 4),
                            Text('$upcomingCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_bookings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Center(child: Text('No bookings yet.', style: TextStyle(color: Colors.grey))),
                        ),
                      ..._bookings.map((b) {
                        final request = b['maintenance_requests'] ?? {};
                        final tenant = request['profiles'];
                        final unit = request['property_units'];
                        final property = unit?['properties'];

                        final location = [
                          if (unit?['unit_number'] != null) 'Unit ${unit['unit_number']}',
                          if (property?['property_name'] != null) property['property_name'],
                          if (property?['estate'] != null) property['estate'],
                        ].join(', ');

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
                                    Expanded(child: Text(request['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                    Text(
                                      (b['status'] as String? ?? '').replaceAll('_', ' '),
                                      style: TextStyle(color: _statusColors[b['status']], fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if ((request['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(request['description'], style: const TextStyle(color: Colors.grey)),
                                ],
                                const SizedBox(height: 6),
                                Text('Client: ${tenant?['full_name'] ?? 'Unknown'}'),
                                if (b['scheduled_at'] != null)
                                  Text(
                                    DateFormat('EEE, MMM d · h:mm a').format(DateTime.parse(b['scheduled_at'])),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                if (location.isNotEmpty)
                                  Text(location, style: const TextStyle(color: Colors.grey)),
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
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
