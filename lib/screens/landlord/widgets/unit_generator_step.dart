import 'package:flutter/material.dart';

class UnitGeneratorStep extends StatefulWidget {
  final String propertyType;

  final TextEditingController blocksController;
  final TextEditingController floorsController;
  final TextEditingController unitsPerFloorController;

  final List<String> generatedUnits;

  final ValueChanged<List<String>> onUnitsGenerated;

  const UnitGeneratorStep({
    super.key,
    required this.propertyType,
    required this.blocksController,
    required this.floorsController,
    required this.unitsPerFloorController,
    required this.generatedUnits,
    required this.onUnitsGenerated,
  });

  @override
  State<UnitGeneratorStep> createState() =>
      _UnitGeneratorStepState();
}

class _UnitGeneratorStepState
    extends State<UnitGeneratorStep> {

  final List<String> numberingStyles = [
    "A101",
    "101",
    "A-001",
  ];

  String numberingStyle = "A101";

  void _generateUnits() {

    final blocks =
        int.tryParse(widget.blocksController.text) ?? 1;

    final floors =
        int.tryParse(widget.floorsController.text) ?? 1;

    final units =
        int.tryParse(widget.unitsPerFloorController.text) ?? 1;

    final List<String> generated = [];

    for (int block = 0; block < blocks; block++) {

      final blockLetter =
          String.fromCharCode(65 + block);

      for (int floor = 1; floor <= floors; floor++) {

        for (int unit = 1; unit <= units; unit++) {

          String unitNumber;

          switch (numberingStyle) {

            case "101":

              unitNumber =
                  "${floor}${unit.toString().padLeft(2, '0')}";

              break;

            case "A-001":

              unitNumber =
                  "$blockLetter-${((floor - 1) * units + unit).toString().padLeft(3, '0')}";

              break;

            default:

              unitNumber =
                  "$blockLetter$floor${unit.toString().padLeft(2, '0')}";
          }

          generated.add(unitNumber);
        }
      }
    }

    widget.onUnitsGenerated(generated);

    setState(() {});
  }

  bool get requiresGenerator {

    return widget.propertyType == "apartment" ||
        widget.propertyType == "flats" ||
        widget.propertyType == "hostel";
  }

  @override
  Widget build(BuildContext context) {

    if (!requiresGenerator) {

      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "This property type does not require automatic unit generation.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          const Text(
            "Smart Unit Generator",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Generate apartment units automatically.",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: [

              Expanded(
                child: TextField(
                  controller:
                      widget.blocksController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: "Blocks",
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller:
                      widget.floorsController,
                  keyboardType:
                     
