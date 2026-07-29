import 'package:flutter/material.dart';

class BlockConfiguration {
  final TextEditingController nameController;
  final TextEditingController floorsController;
  final TextEditingController unitsController;

  BlockConfiguration({
    String name = '',
    int floors = 1,
    int units = 1,
  })  : nameController = TextEditingController(text: name),
        floorsController =
            TextEditingController(text: floors.toString()),
        unitsController =
            TextEditingController(text: units.toString());

  int get floors =>
      int.tryParse(floorsController.text) ?? 1;

  int get unitsPerFloor =>
      int.tryParse(unitsController.text) ?? 1;

  int get totalUnits => floors * unitsPerFloor;

  String get blockName {
    if (nameController.text.trim().isEmpty) {
      return "Unnamed Block";
    }
    return nameController.text.trim();
  }

  void dispose() {
    nameController.dispose();
    floorsController.dispose();
    unitsController.dispose();
  }
}

class BlockConfigurationStep extends StatefulWidget {
  final List<BlockConfiguration> blocks;

  final ValueChanged<List<BlockConfiguration>>
      onChanged;

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

    if (widget.blocks.isEmpty) {
      blocks = [
        BlockConfiguration(
          name: "Block A",
        )
      ];
    } else {
      blocks = widget.blocks;
    }
  }

  @override
  void dispose() {
    for (final block in blocks) {
      block.dispose();
    }
    super.dispose();
  }

  void _notifyParent() {
    widget.onChanged(blocks);
  }

  void _addBlock() {
    setState(() {
      final letter =
          String.fromCharCode(65 + blocks.length);

      blocks.add(
        BlockConfiguration(
          name: "Block $letter",
        ),
      );
    });

    _notifyParent();
  }

  void _removeBlock(int index) {
    if (blocks.length == 1) return;

    setState(() {
      blocks[index].dispose();
      blocks.removeAt(index);
    });

    _notifyParent();
  }

  int get totalUnits {
    int total = 0;

    for (final block in blocks) {
      total += block.totalUnits;
    }

    return total;
  }

  Widget _buildBlockCard(
      BlockConfiguration block,
      int index,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
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
                IconButton(
                  onPressed: () =>
                      _removeBlock(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  block.nameController,
              decoration:
                  const InputDecoration(
                labelText: "Block Name",
                border:
                    OutlineInputBorder(),
              ),
              onChanged: (_) =>
                  _notifyParent(),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: block
                        .floorsController,
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
                      _notifyParent();
                    },
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: TextField(
                    controller:
                        block.unitsController,
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
                      _notifyParent();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    Colors.blue.shade50,
                borderRadius:
                    BorderRadius.circular(
                        10),
              ),
              child: Text(
                "Total Units: ${block.totalUnits}",
                style:
                    const TextStyle(
                  fontWeight:
                     
