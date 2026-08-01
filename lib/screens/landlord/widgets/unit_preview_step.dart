import 'package:flutter/material.dart';

class UnitPreviewStep extends StatefulWidget {
  final List<Map<String, dynamic>> units;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const UnitPreviewStep({
    super.key,
    required this.units,
    required this.onChanged,
  });

  @override
  State<UnitPreviewStep> createState() => _UnitPreviewStepState();
}

class _UnitPreviewStepState extends State<UnitPreviewStep> {
  late final TextEditingController _rentController;

  @override
  void initState() {
    super.initState();
    final existingRent = widget.units.isNotEmpty
        ? widget.units.first['monthly_rent']
        : null;
    _rentController = TextEditingController(
      text: existingRent != null ? existingRent.toString() : '',
    );
  }

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  void _applyRentToAllUnits(String value) {
    final rent = double.tryParse(value);

    final updated = widget.units.map((unit) {
      return {
        ...unit,
        "monthly_rent": rent,
      };
    }).toList();

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.units.isEmpty) {
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
              "${widget.units.length} Units Generated",
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

        TextFormField(
          controller: _rentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Monthly Rent per Unit (required)",
            helperText: "Applied to all generated units. You can edit individual units later.",
            border: OutlineInputBorder(),
            prefixText: "KES ",
          ),
          onChanged: _applyRentToAllUnits,
        ),

        const SizedBox(height: 12),

        Expanded(
          child: ListView.separated(
            itemCount: widget.units.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final unit = widget.units[index];
              final rent = unit["monthly_rent"];

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
                    "Floor ${unit["floor"]}"
                    "${rent != null ? " · KES $rent/mo" : ""}",
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
