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
          .select('*, leases(id, tenant_id, monthly_rent, active, profiles(full_name))')
          .eq('landlord_id', profile['id'])
          .order('created_at', ascending: false);

      final properties = List<Map<String, dynamic>>.from(data);

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
        try {
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
        } catch (_) {
          // Progress is optional — don't fail the whole screen
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
