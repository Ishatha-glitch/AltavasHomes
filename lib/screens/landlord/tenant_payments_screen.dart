import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TenantPaymentsScreen extends StatefulWidget {
  const TenantPaymentsScreen({super.key});

  @override
  State<TenantPaymentsScreen> createState() => _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends State<TenantPaymentsScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _tenantRows = [];
  double _totalExpected = 0;
  double _totalCollected = 0;
  List<double> _last6MonthsTotals = List.filled(6, 0);
  List<String> _last6MonthLabels = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final landlordId = supabase.auth.currentUser!.id;
      final now = DateTime.now();

      // 1. All occupied units belonging to this landlord, with tenant + property info.
      final properties = await supabase
          .from('properties')
          .select('id')
          .eq('landlord_id', landlordId);

      final propertyIds =
          List<Map<String, dynamic>>.from(properties).map((p) => p['id']).toList();

      List<Map<String, dynamic>> leases = [];

      if (propertyIds.isNotEmpty) {
        final unitsResult = await supabase
            .from('property_units')
            .select('id, unit_number, monthly_rent, properties(property_name)')
            .filter('property_id', 'in', '(${propertyIds.join(",")})')
            .eq('status', 'occupied');

        final units = List<Map<String, dynamic>>.from(unitsResult);
        final unitIds = units.map((u) => u['id'] as String).toList();

        if (unitIds.isNotEmpty) {
          final leasesResult = await supabase
              .from('leases')
              .select('id, unit_id, tenant_id, monthly_rent, profiles!leases_tenant_id_fkey(full_name, phone)')
              .filter('unit_id', 'in', '(${unitIds.join(",")})')
              .eq('active', true);

          final leaseRows = List<Map<String, dynamic>>.from(leasesResult);

          for (final lease in leaseRows) {
            final unit = units.firstWhere(
              (u) => u['id'] == lease['unit_id'],
              orElse: () => {},
            );
            leases.add({
              ...lease,
              'unit_number': unit['unit_number'],
              'property_name': unit['properties']?['property_name'],
            });
          }
        }
      }

      // 2. All completed payments for this landlord (used for both the per-tenant
      // "paid this month" figure and the 6-month collection graph).
      final paymentsResult = await supabase
          .from('payments')
          .select('lease_id, amount, status, paid_at')
          .eq('landlord_id', landlordId)
          .eq('status', 'completed');

      final payments = List<Map<String, dynamic>>.from(paymentsResult);

      // Per-tenant this-month totals.
      final tenantRows = leases.map((lease) {
        final rent = (lease['monthly_rent'] as num?)?.toDouble() ?? 0;

        final paidThisMonth = payments.where((p) {
          if (p['lease_id'] != lease['id'] || p['paid_at'] == null) return false;
          final paidAt = DateTime.tryParse(p['paid_at']);
          return paidAt != null && paidAt.year == now.year && paidAt.month == now.month;
        }).fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

        final remaining = (rent - paidThisMonth).clamp(0, rent);

        return {
          ...lease,
          'rent': rent,
          'paid_this_month': paidThisMonth,
          'remaining': remaining,
        };
      }).toList();

      final totalExpected = tenantRows.fold<double>(0, (sum, t) => sum + (t['rent'] as double));
      final totalCollected = tenantRows.fold<double>(0, (sum, t) => sum + (t['paid_this_month'] as double));

      // 3. Last 6 months of collections, for the bar chart.
      final monthlyTotals = List<double>.filled(6, 0);
      final monthLabels = <String>[];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        monthLabels.add('${_monthAbbrev(month.month)}');
      }

      for (final p in payments) {
        if (p['paid_at'] == null) continue;
        final paidAt = DateTime.tryParse(p['paid_at']);
        if (paidAt == null) continue;

        for (int i = 0; i < 6; i++) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          if (paidAt.year == month.year && paidAt.month == month.month) {
            monthlyTotals[i] += (p['amount'] as num).toDouble();
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _tenantRows = tenantRows;
        _totalExpected = totalExpected;
        _totalCollected = totalCollected;
        _last6MonthsTotals = monthlyTotals;
        _last6MonthLabels = monthLabels;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load payment data: $e')),
      );
    }
  }

  String _monthAbbrev(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    final collectionRate = _totalExpected > 0
        ? (_totalCollected / _totalExpected * 100).clamp(0, 100)
        : 0.0;

    final maxMonthly = _last6MonthsTotals.isEmpty
        ? 1.0
        : (_last6MonthsTotals.reduce((a, b) => a > b ? a : b)).clamp(1, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Payments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  // Summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This Month',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Collected', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    'KES ${_totalCollected.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Expected', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    'KES ${_totalExpected.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: collectionRate / 100,
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${collectionRate.toStringAsFixed(0)}% collected',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 6-month bar chart
                  const Text(
                    'Collections — Last 6 Months',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        maxY: maxMonthly * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= _last6MonthLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _last6MonthLabels[index],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: List.generate(_last6MonthsTotals.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _last6MonthsTotals[i],
                                color: const Color(0xFF2563EB),
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Tenants',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),

                  if (_tenantRows.isEmpty)
                    const Text('No occupied units yet.', style: TextStyle(color: Colors.grey))
                  else
                    ..._tenantRows.map((t) {
                      final rent = t['rent'] as double;
                      final paid = t['paid_this_month'] as double;
                      final remaining = t['remaining'] as double;
                      final fullyPaid = remaining <= 0;
                      final tenant = t['profiles'];

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
                                    child: Text(
                                      tenant?['full_name'] ?? 'Unknown Tenant',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: fullyPaid
                                          ? const Color(0xFF16A34A).withOpacity(0.15)
                                          : const Color(0xFFF59E0B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      fullyPaid ? 'PAID' : 'PARTIAL',
                                      style: TextStyle(
                                        color: fullyPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t['property_name'] ?? ''} · Unit ${t['unit_number'] ?? ''}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Paid: KES ${paid.toStringAsFixed(0)}'),
                                  Text('Rent: KES ${rent.toStringAsFixed(0)}'),
                                ],
                              ),
                              if (!fullyPaid) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Remaining: KES ${remaining.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
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
