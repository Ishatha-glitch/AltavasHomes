import 'package:flutter/material.dart';

class UnitPreviewStep extends StatelessWidget {
  final List<Map<String, dynamic>> units;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const UnitPreviewStep({
    super.key,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "No units generated yet.\nGo back to the Blocks step to configure your property.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [

        Card(
          color: Colors.blue.shade50,
          child: ListTile(
            leading: const Icon(Icons.home_work),
            title: Text(
              "${units.length} Units Generated",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              "These are the houses that tenants will rent.",
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: ListView.separated(
            itemCount: units.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final unit = units[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      unit["block"].toString(),
                    ),
                  ),

                  title: Text(
                    "House ${unit["unit_number"]}",
                  ),

                  subtitle: Text(
                    "Floor ${unit["floor"]}",
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Icon(
                        unit["occupied"]
                            ? Icons.person
                            : Icons.home_outlined,
                        color: unit["occupied"]
                            ? Colors.red
                            : Colors.green,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        unit["occupied"]
                            ? "Occupied"
                            : "Vacant",
                        style: TextStyle(
                          color: unit["occupied"]
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
