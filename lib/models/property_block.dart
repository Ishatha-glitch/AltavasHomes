import 'package:flutter/material.dart';

class BlockConfiguration {
  final TextEditingController nameController;
  final TextEditingController floorsController;
  final TextEditingController unitsController;

  BlockConfiguration({
    String name = 'A',
    int floors = 1,
    int unitsPerFloor = 1,
  })  : nameController = TextEditingController(text: name),
        floorsController = TextEditingController(
          text: floors.toString(),
        ),
        unitsController = TextEditingController(
          text: unitsPerFloor.toString(),
        );

  String get blockName =>
      nameController.text.trim().toUpperCase();

  int get floors =>
      int.tryParse(floorsController.text) ?? 1;

  int get unitsPerFloor =>
      int.tryParse(unitsController.text) ?? 1;

  void dispose() {
    nameController.dispose();
    floorsController.dispose();
    unitsController.dispose();
  }
}
