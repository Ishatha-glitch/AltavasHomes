import 'package:flutter/material.dart';

class BlockConfiguration {
  final TextEditingController nameController;
  final TextEditingController floorsController;
  final TextEditingController unitsPerFloorController;

  BlockConfiguration({
    String name = '',
    int floors = 1,
    int unitsPerFloor = 1,
  })  : nameController = TextEditingController(text: name),
        floorsController = TextEditingController(text: floors.toString()),
        unitsPerFloorController =
            TextEditingController(text: unitsPerFloor.toString());

  String get blockName => nameController.text.trim();

  int get floors =>
      int.tryParse(floorsController.text.trim()) ?? 1;

  int get unitsPerFloor =>
      int.tryParse(unitsPerFloorController.text.trim()) ?? 1;

  void dispose() {
    nameController.dispose();
    floorsController.dispose();
    unitsPerFloorController.dispose();
  }
}

class BlockConfigurationStep extends StatefulWidget {
  final List<BlockConfiguration> blocks;
  final ValueChanged<List<BlockConfiguration>> onChanged;

  const BlockConfigurationStep({
    super.key,
    required this.blocks,
    required this.onChanged,
  });

  @override
  State<BlockConfigurationStep> createState() =>
      _BlockConfigurationStepState();
}

class _BlockConfigurationStepState
    extends State<BlockConfigurationStep> {

  late List<BlockConfiguration> blocks;

  @override
  void initState() {
    super.initState();

    blocks = widget.blocks.isEmpty
        ? [
            BlockConfiguration(
              name: "A",
              floors: 1,
              unitsPerFloor: 1,
            )
          ]
        : widget.blocks;
  }

  void _notify() {
    widget.onChanged(blocks);
  }

  void _addBlock() {
    setState(() {
      blocks.add(
        BlockConfiguration(
          name: String.fromCharCode(65 + blocks.length),
          floors: 1,
          unitsPerFloor: 1,
        ),
      );
    });

    _notify();
  }

  void _removeBlock(int index) {
    if (blocks.length == 1) return;

    blocks[index].dispose();

    setState(() {
      blocks.removeAt(index);
    });

    _notify();
  }

  int get totalUnits {
    int total = 0;

    for (final block in blocks) {
      total +=
          block.floors * block.unitsPerFloor;
    }

    return total;
  }

  Widget _buildBlockCard(
      BlockConfiguration block,
      int index,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              children: [

                Expanded(
                  child: Text(
                    "Block ${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                if (blocks.length > 1)
                  IconButton(
                    onPressed: () =>
                        _removeBlock(index),
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: block.nameController,
              decoration: const InputDecoration(
                labelText: "Block Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _notify(),
            ),

            const SizedBox(height: 16),

            Row(
              children: [

                Expanded(
                  child: TextField(
                    controller:
                        block.floorsController,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText: "Floors",
                      border:
                          OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _notify();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: block
                        .unitsPerFloorController,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Units/Floor",
                      border:
                          OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _notify();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Units: ${block.floors * block.unitsPerFloor}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
