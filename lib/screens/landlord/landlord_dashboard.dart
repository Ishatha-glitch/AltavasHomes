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
  Map<String, int> _unitCounts = {};

  @override
  void initState() {
    super.initState();
    loadProperties();
  }

  Future<void> loadProperties() async {
    try {
      final user = supabase.auth.currentUser!;

      final result = await supabase
          .from('properties')
          .select()
          .eq('landlord_id', user.id)
          .order('created_at');

      final props = List<Map<String, dynamic>>.from(result);

      Map<String, int> counts = {};

      if (props.isNotEmpty) {
        final ids = props.map((p) => p['id'] as String).toList();

        final countRows = await supabase
            .from('property_unit_counts')
            .select()
            .filter('property_id', 'in', '(${ids.join(",")})');

        for (final row in List<Map<String, dynamic>>.from(countRows)) {
          counts[row['property_id'] as String] =
              (row['total_units'] as num?)?.toInt() ?? 0;
        }
      }

      if (!mounted) return;

      setState(() {
        properties = props;
        _unitCounts = counts;
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
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _confirmSignOut,
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
                      padding:
                          const EdgeInsets.all(16),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {

                        final property =
                            properties[index];

                        final units =
                            _unitCounts[property['id']] ?? 0;

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
                                property["property_name"] ??
                                    "",
                              ),

                              subtitle: Text(
                                "${property["property_type"] ?? ""} · $units units · ${property["status"] ?? "draft"}",
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
