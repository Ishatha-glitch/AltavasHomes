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
  State<UnitPreviewStep> createState() =>
      _UnitPreviewStepState();
}

class _UnitPreviewStepState
    extends State<UnitPreviewStep> {

  late List<Map<String, dynamic>> units;

  @override
  void initState() {
    super.initState();
    units = List.from(widget.units);
  }

  void _renameUnit(
      int index,
      String value,
      ) {

    units[index]["unit_number"] = value;

    widget.onChanged(units);

    setState(() {});
  }

  bool _isOccupied(Map<String, dynamic> unit) {

    return unit["occupied"] == true;
  }

  @override
  Widget build(BuildContext context) {

    if (units.isEmpty) {

      return const Center(
        child: Text(
          "Generate units first.",
        ),
      );
    }

    return Column(
      children: [

        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [

              const Icon(Icons.home_work),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  "${units.length} Units Generated",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(

            itemCount: units.length,

            itemBuilder: (context, index) {

              final unit = units[index];

              return Card(

                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                child: Padding(

                  padding: const EdgeInsets.all(12),

                  child: Column(

                    children: [

                      TextField(

                        controller: TextEditingController(
                          text: unit["unit_number"],
                        ),

                        decoration: const InputDecoration(
                          labelText: "Unit Number",
                          border: OutlineInputBorder(),
                        ),

                        onChanged: (value) =>
                            _renameUnit(index, value),
                      ),

                      const SizedBox(height: 12),

                      Row(

                        children: [

                          Expanded(
                            child: Text(
                              "Block: ${unit["block"]}",
                            ),
                          ),

                          Expanded(
                            child: Text(
                              "Floor: ${unit["floor"]}",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(

                        children: [

                          Expanded(

                            child: Text(
                              _isOccupied(unit)
                                  ? "Occupied"
                                  : "Vacant",

                              style: TextStyle(
                                color: _isOccupied(unit)
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right,
                          ),
                        ],
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
