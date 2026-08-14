import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/messaging_service.dart';

class ServiceProvidersListScreen extends StatefulWidget {
  final String? maintenanceRequestId;

  const ServiceProvidersListScreen({super.key, this.maintenanceRequestId});

  @override
  State<ServiceProvidersListScreen> createState() => _ServiceProvidersListScreenState();
}

class _ServiceProvidersListScreenState extends State<ServiceProvidersListScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _providers = [];
  String? _categoryFilter;

  static const categories = ['Plumber', 'Electrician', 'Mover', 'Cleaner', 'Painter', 'Other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      var query = supabase
          .from('profiles')
          .select('id, full_name, phone, service_category')
          .eq('role', 'service_provider');

      if (_categoryFilter != null) {
        query = query.eq('service_category', _categoryFilter!);
      }

      final result = await query.order('full_name');

      if (!mounted) return;
      setState(() {
        _providers = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load service providers: $e')),
      );
    }
  }

  Future<void> _messageProvider(Map<String, dynamic> provider) async {
    try {
      final conversationId = await MessagingService.getOrCreateConversation(
        otherUserId: provider['id'],
        maintenanceRequestId: widget.maintenanceRequestId,
      );

      if (!mounted) return;
      context.push('/chat', extra: {
        'conversationId': conversationId,
        'otherPartyName': provider['full_name'] ?? 'Service Provider',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Providers')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _categoryFilter == null,
                    onSelected: (_) {
                      setState(() => _categoryFilter = null);
                      _load();
                    },
                  ),
                ),
                ...categories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _categoryFilter == c,
                      onSelected: (_) {
                        setState(() => _categoryFilter = c);
                        _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _providers.isEmpty
                    ? const Center(
                        child: Text('No service providers found.', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _providers.length,
                        itemBuilder: (context, i) {
                          final provider = _providers[i];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.handyman)),
                              title: Text(provider['full_name'] ?? ''),
                              subtitle: Text(provider['service_category'] ?? ''),
                              trailing: FilledButton.icon(
                                onPressed: () => _messageProvider(provider),
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: const Text('Message'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
