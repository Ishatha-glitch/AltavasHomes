import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      if (!mounted) return;

      setState(() {
        properties =
            List<Map<String, dynamic>>.from(result);
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Landlord Dashboard"),
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

                        return Card(
                          child: ListTile(

                            leading: const CircleAvatar(
                              child: Icon(Icons.home),
                            ),

                            title: Text(
                              property["property_name"] ??
                                  "",
                            ),

                            subtitle: Text(
                              property["property_type"] ??
                                  "",
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
                        );
                      },
                    ),
            ),
    );
  }
}
