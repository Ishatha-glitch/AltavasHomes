import 'package:flutter/material.dart';
import '../../../models/property_block.dart';

class BlockConfigurationStep extends StatelessWidget {
  final List<BlockConfiguration> blocks;
  final ValueChanged<List<BlockConfiguration>> onChanged;

  const BlockConfigurationStep({
    super.key,
    required this.blocks,
    required this.onChanged,
  });

  void _addBlock() {
    blocks.add(
      BlockConfiguration(
        name: String.fromCharCode(65 + blocks.length),
        floors: 1,
        unitsPerFloor: 1,
      ),
    );

    onChanged(List.from(blocks));
  }

  void _removeBlock(int index) {
    blocks[index].dispose();
    blocks.removeAt(index);

    onChanged(List.from(blocks));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _addBlock,
            icon: const Icon(Icons.add),
            label: const Text("Add Block"),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final block = blocks[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      Row(
                        children: [

                          Expanded(
                            child: TextFormField(
                              controller: block.nameController,
                              decoration: const InputDecoration(
                                labelText: "Block Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          if (blocks.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeBlock(index),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: block.floorsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Number of Floors",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: block.unitsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Units Per Floor",
                          border: OutlineInputBorder(),
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
