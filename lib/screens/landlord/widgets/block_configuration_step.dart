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
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Apartment / Block Configuration",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Configure all apartment blocks and the number of units in each block.",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          ...List.generate(
            blocks.length,
            (index) => _buildBlockCard(
              blocks[index],
              index,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addBlock,
              icon: const Icon(Icons.add),
              label: const Text(
                "Add Another Block",
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.apartment,
                    size: 50,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "$totalUnits Total Units",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "${blocks.length} Block(s)",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),
              title: Text("Example"),
              subtitle: Text(
                "Block A\n"
                "• 4 Floors\n"
                "• 8 Units per Floor\n\n"
                "Creates 32 apartments automatically.\n\n"
                "Apartment numbers:\n"
                "A101, A102
