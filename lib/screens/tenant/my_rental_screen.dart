import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../services/mpesa_service.dart';
import '../../widgets/rent_progress_bar.dart';

class MyRentalScreen extends StatefulWidget {
  const MyRentalScreen({super.key});

  @override
  State<MyRentalScreen> createState() => _MyRentalScreenState();
}

class _MyRentalScreenState extends State<MyRentalScreen> {
  final supabase = Supabase.instance.client;
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  bool _loading = true;
  Map<String, dynamic>? _lease;
  List<Map<String, dynamic>> _payments = [];
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _phoneController.text = profile?['phone'] ?? '';
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _balanceOwed(Map<String, dynamic> lease, List<Map<String, dynamic>> payments) {
    final rent = (lease['monthly_rent'] as num).toDouble();
    final now = DateTime.now();

    final paidThisMonth = payments
        .where((p) {
          if (p['status'] != 'completed' || p['paid_at'] == null) return false;
          final paidAt = DateTime.tryParse(p['paid_at']);
          return paidAt != null && paidAt.year == now.year && paidAt.month == now.month;
        })
        .fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

    return (rent - paidThisMonth).clamp(0, rent);
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final profile = context.read<AuthProvider>().profile!;

      final leaseResult = await supabase
          .from('leases')
          .select(
            '*, property_units(unit_number, floor, properties(property_name, estate, town))',
          )
          .eq('tenant_id', profile['id'])
          .eq('active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      List<Map<String, dynamic>> payments = [];

      if (leaseResult != null) {
        final paymentsResult = await supabase
            .from('payments')
            .select()
            .eq('lease_id', leaseResult['id'])
            .order('created_at', ascending: false);

        payments = List<Map<String, dynamic>>.from(paymentsResult);
      }

      if (!mounted) return;
      setState(() {
        _lease = leaseResult;
        _payments = payments;
        _loading = false;
      });

      if (leaseResult != null) {
        final balance = _balanceOwed(leaseResult, payments);
        _amountController.text = balance > 0 ? balance.toStringAsFixed(0) : '';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load your rental: $e')),
      );
    }
  }

  Future<void> _payRent() async {
    if (_lease == null) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('254') || phone.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number in 254XXXXXXXXX format.'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount to pay.')),
      );
      return;
    }

    setState(() => _paying = true);

    final profile = context.read<AuthProvider>().profile!;

    final result = await MpesaService.initiatePayment(
      phoneNumber: phone,
      amount: amount,
      leaseId: _lease!['id'],
      tenantId: profile['id'],
      landlordId: _lease!['landlord_id'],
    );

    if (!mounted) return;
    setState(() => _paying = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check Your Phone'),
          content: const Text(
            'An M-Pesa prompt has been sent to your phone. '
            'Enter your PIN to complete the payment, then come back and refresh.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _load();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment request failed: ${result['error']}')),
      );
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Rental')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lease == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "You don't have an active rental yet.\nBrowse properties and request a unit to get started.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Builder(builder: (context) {
                        final unit = _lease!['property_units'];
                        final property = unit?['properties'];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property?['property_name'] ?? '',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unit ${unit?['unit_number'] ?? ''} · Floor ${unit?['floor'] ?? '-'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  property?['estate'] ?? '',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const Divider(height: 24),
                                Text(
                                  'KES ${_lease!['monthly_rent']}/month',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      Builder(builder: (context) {
                        final rent = (_lease!['monthly_rent'] as num).toDouble();
                        final balance = _balanceOwed(_lease!, _payments);
                        final paidThisMonth = rent - balance;
                        final percent = rent > 0 ? (paidThisMonth / rent * 100) : 0.0;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: RentProgressBar(
                              percent: percent,
                              amountPaid: paidThisMonth,
                              totalRent: rent,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      const Text(
                        'Pay Rent',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        decoration: const InputDecoration(
                          labelText: 'Amount to Pay (KES)',
                          helperText: 'You can pay in part or in full',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'M-Pesa Phone Number',
                          helperText: 'Format: 254XXXXXXXXX',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _paying ? null : _payRent,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
                          child: _paying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Pay with M-Pesa'),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Payment History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),

                      if (_payments.isEmpty)
                        const Text('No payments yet.', style: TextStyle(color: Colors.grey))
                      else
                        ..._payments.map((p) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text('KES ${p['amount']}'),
                              subtitle: Text(
                                p['receipt_number'] != null
                                    ? 'Receipt: ${p['receipt_number']}'
                                    : (p['created_at'] ?? '').toString().split('T').first,
                              ),
                              trailing: Text(
                                (p['status'] ?? 'pending').toString().toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(p['status']),
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
    );
  }
}
