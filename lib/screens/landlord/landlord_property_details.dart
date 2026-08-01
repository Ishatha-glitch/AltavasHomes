import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/property_service.dart';

class LandlordPropertyDetails extends StatefulWidget {
  final Map<String, dynamic> property;

  const LandlordPropertyDetails({
    super.key,
    required this.property,
  });

  @override
  State<LandlordPropertyDetails> createState() =>
      _LandlordPropertyDetailsState();
}

class _LandlordPropertyDetailsState
    extends State<LandlordPropertyDetails> {

  final supabase = Supabase.instance.client;
  int _totalUnits = 0;
  bool _loadingUnits = true;

  @override
  void initState() {
    super.initState();
    _loadUnitCount();
  }

  Future<void> _loadUnitCount() async {
    try {
      final result = await supabase
          .from('property_unit_counts')
          .select()
          .eq('property_id', widget.property['id'])
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _totalUnits = (result?['total_units'] as num?)?.toInt() ?? 0;
        _loadingUnits = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete property?'),
        content: Text(
          'This permanently deletes "${widget.property["property_name"] ?? "this property"}" '
          'and all of its blocks and units. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PropertyService.deleteProperty(widget.property['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property deleted.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete property: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final images =
        List<String>.from(property['images'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          property['property_name'] ??
              property['title'] ??
              'Property',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Property',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        children: [

          if (images.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            )
          else
            Container(
              height: 250,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.home,
                  size: 80,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  property['property_name'] ??
                      property['title'] ??
                      '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  property['property_type'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  property['description'] ?? '',
                ),

                const SizedBox(height: 30),

                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    property['estate'] ??
                        property['town'] ??
                        '',
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.apartment),
                  title: Text(
                    _loadingUnits
                        ? "Loading units..."
                        : "$_totalUnits Units",
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: Text(
                    property['status'] ??
                        'Draft',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
