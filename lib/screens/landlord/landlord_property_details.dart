import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LandlordPropertyDetails extends StatefulWidget {
  final Map<String, dynamic> property;

  const LandlordPropertyDetails({
    super.key,
    required this.property,
  });

  @override
  State<LandlordPropertyDetails> createState() =>
      _LandlordPropertyDetailsState();
}

class _LandlordPropertyDetailsState
    extends State<LandlordPropertyDetails> {

  final _client = Supabase.instance.client;

  bool _loading = true;

  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final data = await _client
        .from("property_units")
        .select()
        .eq("property_id", widget.property["id"])
        .order("block_name")
        .order("floor")
        .order("unit_number");

    setState(() {
      _units = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Color statusColor(bool occupied) {
    return occupied ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.property["name"]),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(

              padding: const EdgeInsets.all(16),

              children: [

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.home_work),
                    title: Text(widget.property["name"]),
                    subtitle: Text(
                      widget.property["property_type"],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Units (${_units.length})",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ..._units.map(
                  (unit) => Card(
                    child: ListTile(

                      leading: CircleAvatar(
                        child: Text(unit["block_name"]),
                      ),

                      title: Text(
                        "House ${unit["unit_number"]}",
                      ),

                      subtitle: Text(
                        "Floor ${unit["floor"]}",
                      ),

                      trailing: Chip(
                        backgroundColor: statusColor(
                          unit["occupied"],
                        ),
                        label: Text(
                          unit["occupied"]
                              ? "Occupied"
                              : "Vacant",
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),

                      onTap: () {
                        // Next step:
                        // Open Unit Details Screen
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
