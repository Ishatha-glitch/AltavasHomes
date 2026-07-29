import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'services/property_service.dart';
import 'widgets/amenities_step.dart';
import 'widgets/block_configuration_step.dart';
import 'widgets/location_step.dart';
import 'widgets/property_info_step.dart';
import 'widgets/unit_preview_step.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() =>
      _AddPropertyScreenState();
}

class _AddPropertyScreenState
    extends State<AddPropertyScreen> {

  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;

  /// Step 1
  final _propertyNameController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  String _propertyType = '';

  /// Step 2
  final _countryController =
      TextEditingController();

  final _countyController =
      TextEditingController();

  final _townController =
      TextEditingController();

  final _estateController =
      TextEditingController();

  final _streetController =
      TextEditingController();

  double? _latitude;
  double? _longitude;

  /// Step 3
  List<String> _selectedAmenities = [];

  /// Step 4
  List<BlockConfiguration> _blocks = [];

  /// Step 5
  List<Map<String, dynamic>> _generatedUnits = [];

  /// Images
  final List<Uint8List> _images = [];

  bool _saving = false;

  @override
  void dispose() {
    _propertyNameController.dispose();
    _descriptionController.dispose();

    _countryController.dispose();
    _countyController.dispose();
    _townController.dispose();
    _estateController.dispose();
    _streetController.dispose();

    for (final block in _blocks) {
      block.dispose();
    }

    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();

    final files = await picker.pickMultiImage(
      imageQuality: 80,
    );

    if (files.isEmpty) return;

    final List<Uint8List> picked = [];

    for (final file in files) {
      picked.add(await file.readAsBytes());
    }

    setState(() {
      _images.addAll(picked);
    });
  }

  void _generateUnits() {
    final List<Map<String, dynamic>> units = [];

    for (final block in _blocks) {
      final blockName = block.blockName;

      for (int floor = 1;
          floor <= block.floors;
          floor++) {

        for (int unit = 1;
            unit <= block.unitsPerFloor;
            unit++) {

          units.add({
            "block": blockName,
            "floor": floor,
            "unit_number":
                "$blockName${floor.toString()}${unit.toString().padLeft(2, '0')}",
            "occupied": false,
          });
        }
      }
    }

    setState(() {
      _generatedUnits = units;
    });
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _publishProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Capture the property GPS location.",
          ),
        ),
      );
      return;
    }

    if (_generatedUnits.isEmpty &&
        (_propertyType == "apartment" ||
            _propertyType == "flats" ||
            _propertyType == "hostel")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Generate units before publishing.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final landlord = context
          .read<AuthProvider>()
          .profile!;

      // Publishing continues in Part 2...
