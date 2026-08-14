import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../services/property_service.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() =>
      _LandlordDashboardState();
}

class _LandlordDashboardState
    extends State<LandlordDashboard> {

  final supabase = Supabase.instance.client;

  bool _loading = true;

  List<Map<String, dynamic>> properties = [];
  Map<String, Map<String, int>> _unitStats = {}; // propertyId -> {total, occupied, vacant}

  @override
  void initState() {
    super.initState();
    loadProperties();
  }

  Future<void> loadProperties() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser!;

      final result = await supabase
          .from('properties')
          .select()
          .eq('landlord_id', user.id)
          .order('created_at');

      final props = List<Map<String, dynamic>>.from(result);

      Map<String, Map<String, int>> stats = {};

      if (props.isNotEmpty) {
        final ids = props.map((p) => p['id'] as String).toList();

        final unitRows = await supabase
            .from('property_units')
            .select('property_id, status')
            .filter('property_id', 'in', '(${ids.join(",")})');

        for (final row in List<Map<String, dynamic>>.from(unitRows)) {
          final propId = row['property_id'] as String;
          final occupied = row['status'] == 'occupied';

          final current = stats[propId] ?? {'total': 0, 'occupied': 0, 'vacant': 0};
          current['total'] = (current['total'] ?? 0) + 1;
          if (occupied) {
            current['occupied'] = (current['occupied'] ?? 0) + 1;
          } else {
            current['vacant'] = (current['vacant'] ?? 0) + 1;
          }
          stats[propId] = current;
        }
      }

      if (!mounted) return;

      setState(() {
        properties = props;
        _unitStats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll need to sign in again to access your properties.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _confirmDeleteProperty(
    Map<String, dynamic> property,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete property?'),
        content: Text(
          'This permanently deletes "${property["property_name"] ?? "this property"}" '
          'and all of its blocks and units. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PropertyService.deleteProperty(property['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property deleted.')),
      );
      loadProperties();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete property: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Landlord Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Rental Requests',
            onPressed: () => context.push('/landlord/requests'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Tenant Payments',
            onPressed: () => context.push('/landlord/payments'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.build_outlined),
            tooltip: 'Maintenance Requests',
            onPressed: () => context.push('/landlord/maintenance'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
            onPressed: () => context.push('/messages'),
          ),
         IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ), 
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          context.push("/landlord/add-property");
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Property"),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadProperties,
              child: properties.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            "No properties yet.",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {

                        final property = properties[index];

                        final stats = _unitStats[property['id']] ??
                            {'total': 0, 'occupied': 0, 'vacant': 0};

                        return Dismissible(
                          key: ValueKey(property['id']),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmDeleteProperty(property);
                            return false; // we reload the list ourselves
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            child: ListTile(

                              leading: const CircleAvatar(
                                child: Icon(Icons.home),
                              ),

                              title: Text(
                                property["property_name"] ?? "",
                              ),

                              subtitle: Text(
                                "${property["property_type"] ?? ""} · "
                                "${stats['total']} units · "
                                "${stats['occupied']} occupied · "
                                "${stats['vacant']} vacant · "
                                "${property["status"] ?? "draft"}",
                              ),

                              trailing: const Icon(
                                Icons.chevron_right,
                              ),

                              onTap: () {
                                context.push(
                                  "/landlord/property",
                                  extra: property,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
