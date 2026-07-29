import 'package:flutter/material.dart';

import 'block_configuration_step.dart';

class UnitPreviewStep extends StatelessWidget {
  final List<BlockConfiguration> blocks;

  const UnitPreviewStep({
    super.key,
    required this.blocks,
  });

  List<String> _generateUnits() {
    final List<String> units = [];

    for (final block in blocks) {
      final blockName = block.blockName.isEmpty
          ? "A"
          : block.blockName.toUpperCase();

      for (int floor = 1; floor <= block.floors; floor++) {
        for (int unit = 1; unit <= block.unitsPerFloor; unit++) {
          units.add(
            "$blockName${floor.toString()}${unit.toString().padLeft(2, '0')}",
          );
        }
      }
    }

    return units;
  }

  @override
  Widget build(BuildContext context) {
    final units = _generateUnits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Unit Preview",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "These are the units that will be created automatically.",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 20),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.apartment,
              color: Colors.blue,
            ),
            title: Text("${units.length} Units"),
            subtitle: const Text(
              "Every unit will have its own tenant, rent records and maintenance history.",
            ),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: GridView.builder(
            itemCount: units.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                child: Center(
                  child: Text(
                    units[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
