import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';
import '../../widgets/rent_progress_bar.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  List<Map<String, dynamic>> _properties = [];
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
          .from('properties')
          .select('*, leases(id, tenant_id, monthly_rent, active, profiles!leases_tenant_id_fkey(full_name))')
          .eq('landlord_id', profile['id'])
          .order('created_at', ascending: false);

      final properties = List<Map<String, dynamic>>.from(data);

      // Collect active-lease IDs first, then fetch all their payment
      // progress rows in a single query instead of one query per
      // property (was N+1 sequential round trips).
      final activeLeaseIds = <String>[];
      for (final p in properties) {
        final leases = List<Map<String, dynamic>>.from(p['leases'] ?? []);
        final activeLease = leases.where((l) => l['active'] == true).firstOrNull;
        p['activeLease'] = activeLease;
        if (activeLease != null) {
          activeLeaseIds.add(activeLease['id'] as String);
        }
      }

      if (activeLeaseIds.isNotEmpty) {
        final progressRows = await Db.client
            .from('lease_payment_progress')
            .select()
            .inFilter('lease_id', activeLeaseIds);

        final progressByLeaseId = <String, Map<String, dynamic>>{
          for (final row in List<Map<String, dynamic>>.from(progressRows))
            row['lease_id'] as String: row,
        };

        for (final p in properties) {
          final activeLease = p['activeLease'];
          if (activeLease != null) {
            p['progress'] = progressByLeaseId[activeLease['id']];
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _properties = properties;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load properties. Check your connection.')),
      );
    }
  }

  Future<void> _toggleVacancy(Map<String, dynamic> property) async {
    final newStatus = property['status'] == 'vacant' ? 'occupied' : 'vacant';
    try {
      await Db.client.from('properties').update({'status': newStatus}).eq('id', property['id']);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update status. Check your connection.')),
      );
    }
  }

  // properties.rent_amount, leases.monthly_rent, and progress.paid_amount
  // are all numeric columns, so they come back as doubles (e.g. 100000.0).
  // This strips the trailing .0 for whole numbers, keeps 2 decimals otherwise.
  String _formatAmount(dynamic amount) {
    final value = (amount as num?)?.toDouble() ?? 0;
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.push('/landlord/add-property');
              _load();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.inbox_outlined, color: Colors.white),
            tooltip: 'Rental requests',
            onPressed: () async {
              await context.push('/landlord/requests');
              _load();
            },
          ),
          IconButton(
  icon: const Icon(Icons.person_outline, color: Colors.white),
  tooltip: 'My profile',
  onPressed: () => context.push('/profile'),
),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.signOut),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? const Center(child: Text('No properties listed yet.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties.length,
                    itemBuilder: (context, i) {
                      final p = _properties[i];
                      final isVacant = p['status'] == 'vacant';
                      final activeLease = p['activeLease'];
                      final progress = p['progress'];
                      final percentPaid = (progress?['percent_paid'] as num?)?.toDouble() ?? 0;

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
                                  Expanded(child: Text(p['title'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                                  Row(
                                    children: [
                                      Text(isVacant ? 'Vacant' : 'Occupied', style: TextStyle(color: isVacant ? const Color(0xFF16A34A) : const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                                      Switch(value: !isVacant, onChanged: (_) => _toggleVacancy(p)),
                                    ],
                                  ),
                                ],
                              ),
                              Text(p['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text('Rent: ${p['currency']} ${_formatAmount(p['rent_amount'])}/mo', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const Divider(height: 24),
                              if (activeLease != null) ...[
                                Text('Tenant: ${activeLease['profiles']?['full_name'] ?? 'Unnamed'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Paid this month: ${_formatAmount(progress?['paid_amount'] ?? 0)} / ${_formatAmount(activeLease['monthly_rent'])}'),
                                const SizedBox(height: 8),
                                RentProgressBar(percent: percentPaid.toDouble()),
                              ] else
                                const Text('No tenant assigned yet', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
