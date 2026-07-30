import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/property_service.dart';

import '../widgets/amenities_step.dart';
import '../widgets/block_configuration_step.dart';
import '../widgets/location_step.dart';
import '../widgets/property_info_step.dart';
import '../widgets/unit_preview_step.dart';

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

  // Property Information
  final _propertyNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _propertyType = 'apartment';

  // Location
  final _countryController = TextEditingController();
  final _countyController = TextEditingController();
  final _townController = TextEditingController();
  final _estateController = TextEditingController();
  final _streetController = TextEditingController();

  double? _latitude;
  double? _longitude;

  // Amenities
  List<String> _selectedAmenities = [];

  // Blocks
  List<BlockConfiguration> _blocks = [
    BlockConfiguration(
      name: 'A',
      floors: 1,
      unitsPerFloor: 1,
    ),
  ];

  // Generated Units
  List<Map<String, dynamic>> _generatedUnits = [];

  // Images
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
      final propertyId =
          await PropertyService.createProperty(
        landlordId: landlord['id'],
        propertyName:
            _propertyNameController.text.trim(),
        propertyType: _propertyType,
        description:
            _descriptionController.text.trim(),
        country: _countryController.text.trim(),
        county: _countyController.text.trim(),
        town: _townController.text.trim(),
        estate: _estateController.text.trim(),
        street: _streetController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
      );

      if (_selectedAmenities.isNotEmpty) {
        await PropertyService.saveAmenities(
          propertyId: propertyId,
          amenities: _selectedAmenities,
        );
      }

      if (_blocks.isNotEmpty) {
        final blockRows = _blocks
            .map(
              (block) => {
                "name": block.blockName,
                "floors": block.floors,
              },
            )
            .toList();

        await PropertyService.saveBlocks(
          propertyId: propertyId,
          blocks: blockRows,
        );
      }

      if (_generatedUnits.isNotEmpty) {
        await PropertyService.saveUnits(
          propertyId: propertyId,
          units: _generatedUnits,
        );
      }

      if (_images.isNotEmpty) {
        final urls =
            await PropertyService.uploadImages(
          propertyId: propertyId,
          images: _images,
        );

        await PropertyService.saveImages(
          propertyId: propertyId,
          imageUrls: urls,
        );
      }

      await PropertyService.publishProperty(
        propertyId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Property published successfully.",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to publish property.\n$e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  List<Step> _steps() {
    return [
      Step(
        title: const Text("Information"),
        isActive: _currentStep >= 0,
        content: SizedBox(
          height: 520,
          child: PropertyInfoStep(
            propertyNameController:
                _propertyNameController,
            descriptionController:
                _descriptionController,
            propertyType: _propertyType,
            onPropertyTypeChanged: (value) {
              setState(() {
                _propertyType = value ?? '';
              });
            },
          ),
        ),
      ),

      Step(
        title: const Text("Location"),
        isActive: _currentStep >= 1,
        content: SizedBox(
          height: 560,
          child: LocationStep(
            countryController:
                _countryController,
            countyController:
                _countyController,
            townController:
                _townController,
            estateController:
                _estateController,
            streetController:
                _streetController,
            latitude: _latitude,
            longitude: _longitude,
            onLocationCaptured:
                (lat, lng) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
              });
            },
          ),
        ),
      ),

      Step(
        title: const Text("Amenities"),
        isActive: _currentStep >= 2,
        content: SizedBox(
          height: 520,
          child: AmenitiesStep(
            selectedAmenities:
                _selectedAmenities,
            onChanged: (items) {
              _selectedAmenities = items;
            },
          ),
        ),
      ),
      Step(
        title: const Text("Blocks"),
        isActive: _currentStep >= 3,
        content: SizedBox(
          height: 520,
          child: BlockConfigurationStep(
            blocks: _blocks,
            onChanged: (blocks) {
              setState(() {
                _blocks = blocks;
              });

              _generateUnits();
            },
          ),
        ),
      ),

      Step(
        title: const Text("Units"),
        isActive: _currentStep >= 4,
        content: SizedBox(
          height: 520,
          child: UnitPreviewStep(
            units: _generatedUnits,
            onChanged: (units) {
              setState(() {
                _generatedUnits = units;
              });
            },
          ),
        ),
      ),

      Step(
        title: const Text("Images"),
        isActive: _currentStep >= 5,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text(
                "Select Property Images",
              ),
            ),

            const SizedBox(height: 20),

            if (_images.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "No images selected.",
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        right: 12,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                                12),
                        child: Image.memory(
                          _images[index],
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Property",
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          type: StepperType.vertical,
          physics:
              const ClampingScrollPhysics(),
          steps: _steps(),

          onStepContinue: () {
            if (_currentStep == 5) {
              _publishProperty();
            } else {
              _nextStep();
            }
          },

          onStepCancel: _previousStep,

          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (
            BuildContext context,
            ControlsDetails details,
          ) {
            return Padding(
              padding: const EdgeInsets.only(
                top: 24,
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : details.onStepCancel,
                      child: const Text(
                        "Previous",
                      ),
                    ),

                  if (_currentStep > 0)
                    const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : details.onStepContinue,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 5
                                  ? "Publish Property"
                                  : "Next",
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
