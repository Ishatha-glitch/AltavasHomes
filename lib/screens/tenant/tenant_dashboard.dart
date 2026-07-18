import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db.dart';
import '../../widgets/rent_progress_bar.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  Map<String, dynamic>? _lease;
  Map<String, dynamic>? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = context.read<AuthProvider>().profile!;

    final lease = await Db.client
        .from('leases')
        .select('*, properties(title, address)')
        .eq('tenant_id', profile['id'])
        .eq('active', true)
        .maybeSingle();

    Map<String, dynamic>? progress;
    if (lease != null) {
      progress = await Db.client.from('lease_payment_progress').select().eq('lease_id', lease['id']).maybeSingle();
    }

    setState(() {
      _lease = lease;
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _payRent(String method) async {
    if (_lease == null) return;
    final profile = context.read<AuthProvider>().profile!;
    final paid = (_progress?['paid_amount'] as num?)?.toDouble() ?? 0;
    final monthlyRent = (_lease!['monthly_rent'] as num).toDouble();
    final remaining = monthlyRent - paid;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All paid up for this month.")));
      return;
    }

    // NOTE: this inserts a "pending" payment row. In production this button
    // triggers a Supabase Edge Function that calls the real mobile-money
    // (e.g. M-Pesa STK push) or bank API, then a webhook flips the row to
    // "completed". See supabase/edge-functions/payment-webhook.
    final now = DateTime.now();
    final periodMonth = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);

    try {
      await Db.client.from('payments').insert({
        'lease_id': _lease!['id'],
        'tenant_id': profile['id'],
        'landlord_id': _lease!['landlord_id'],
        'amount': remaining,
        'method': method,
        'status': 'pending',
        'period_month': periodMonth,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiated. Follow the ${method == 'mobile_money' ? 'mobile money' : 'bank'} prompt to complete.')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed to start: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile!;
    final firstName = (profile['full_name'] as String? ?? 'there').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi $firstName 👋'),
        actions: [
          IconButton(icon: const Icon(Icons.home_work_outlined), tooltip: 'Browse homes', onPressed: () => context.push('/tenant/browse')),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.signOut),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (_lease == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No active lease yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text('Browse properties and contact a landlord to get set up with a lease.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_lease!['properties']['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_lease!['properties']['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 10),
                            Text('Rent: ${_lease!['monthly_rent']}/month', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            RentProgressBar(percent: (_progress?['percent_paid'] as num?)?.toDouble() ?? 0),
                            const SizedBox(height: 8),
                            Text('Remaining this month: ${((_lease!['monthly_rent'] as num) - ((_progress?['paid_amount'] as num?) ?? 0)).clamp(0, double.infinity)}'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _payRent('mobile_money'),
                                    child: const Text('Pay with Mobile Money'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _payRent('bank'),
                                    child: const Text('Pay from Bank'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
