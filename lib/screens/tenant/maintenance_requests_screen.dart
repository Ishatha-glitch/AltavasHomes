import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() => _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  String? _unitId;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final profile = context.read<AuthProvider>().profile!;

      final lease = await supabase
          .from('leases')
          .select('unit_id')
          .eq('tenant_id', profile['id'])
          .eq('active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final requests = await supabase
          .from('maintenance_requests')
          .select()
          .eq('tenant_id', profile['id'])
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _unitId = lease?['unit_id'];
        _requests = List<Map<String, dynamic>>.from(requests);
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

  Future<void> _openNewRequestSheet() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'New Maintenance Request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Issue title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => priority = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text('Enter a title for the issue.')),
                              );
                              return;
                            }

                            setSheetState(() => submitting = true);

                            try {
                              final profile = context.read<AuthProvider>().profile!;

                              await supabase.from('maintenance_requests').insert({
                                'tenant_id': profile['id'],
                                'unit_id': _unitId,
                                'title': titleController.text.trim(),
                                'description': descController.text.trim(),
                                'priority': priority,
                                'status': 'open',
                              });

                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              _load();
                            } catch (e) {
                              setSheetState(() => submitting = false);
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text('Could not submit request: $e')),
                              );
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Request'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'in_progress':
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _unitId == null ? null : _openNewRequestSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No maintenance requests yet.\nTap "New Request" to report an issue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, i) {
                        final r = _requests[i];
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
                                        r['title'] ?? '',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      (r['status'] ?? 'open').toString().replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor(r['status']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((r['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r['description'], style: const TextStyle(color: Colors.grey)),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Priority: ${(r['priority'] ?? 'medium').toString().toUpperCase()}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
