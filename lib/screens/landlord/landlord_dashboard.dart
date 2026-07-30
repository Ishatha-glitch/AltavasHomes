import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {

  final _client = Supabase.instance.client;

  bool _loading = true;

  List<Map<String, dynamic>> _properties = [];

  int _totalUnits = 0;
  int _occupiedUnits = 0;
  int _vacantUnits = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final user = _client.auth.currentUser!;

      final properties = await _client
          .from('properties')
          .select()
          .eq('landlord_id', user.id)
          .order('created_at');

      final units = await _client
          .from('property_units')
          .select()
          .inFilter(
            'property_id',
            properties.map((e) => e['id']).toList(),
          );

      _totalUnits = units.length;
      _occupiedUnits =
          units.where((u) => u['occupied'] == true).length;
      _vacantUnits =
          units.where((u) => u['occupied'] == false).length;

      setState(() {
        _properties =
            List<Map<String, dynamic>>.from(properties);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [

              Icon(
                icon,
                color: color,
                size: 32,
              ),

              const SizedBox(height: 10),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Landlord Dashboard"),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/landlord/add-property');
        },
        icon: const Icon(Icons.add),
        label: const Text("Property"),
      ),

      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(

        onRefresh: _loadDashboard,

        child: ListView(

          padding: const EdgeInsets.all(16),

          children: [

            Row(
              children: [

                statCard(
                  "Properties",
                  _properties.length.toString(),
                  Icons.home_work,
                  Colors.blue,
                ),

                const SizedBox(width: 12),

                statCard(
                  "Units",
                  _totalUnits.toString(),
                  Icons.apartment,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                statCard(
                  "Occupied",
                  _occupiedUnits.toString(),
                  Icons.people,
                  Colors.green,
                ),

                const SizedBox(width: 12),

                statCard(
                  "Vacant",
                  _vacantUnits.toString(),
                  Icons.home,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              "My Properties",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (_properties.isEmpty)

              const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      "No properties added yet.",
                    ),
                  ),
                ),
              )

            else

              ..._properties.map(
                    (property) => Card(
                  child: ListTile(

                    leading: const CircleAvatar(
                      child: Icon(Icons.home_work),
                    ),

                    title: Text(
                      property["name"] ?? "",
                    ),

                    subtitle: Text(
                      property["property_type"] ?? "",
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                    ),

                    onTap: () {
                      context.push(
                        "/landlord/property",
                        extra: property,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
