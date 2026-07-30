import 'package:flutter/material.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(property['images'] ?? []);

    final List<String> amenities =
        List<String>.from(property['amenities'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          property['property_name'] ??
              property['title'] ??
              'Property',
        ),
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

                const SizedBox(height: 12),

                Text(
                  property['property_type'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  property['description'] ??
                      'No description available.',
                ),

                const SizedBox(height: 25),

                const Text(
                  "Location",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "${property['estate'] ?? ''}, "
                  "${property['town'] ?? ''}, "
                  "${property['county'] ?? ''}",
                ),

                const SizedBox(height: 25),

                const Text(
                  "Amenities",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities.isEmpty
                      ? [
                          const Text(
                            "No amenities listed.",
                          ),
                        ]
                      : amenities
                          .map(
                            (item) => Chip(
                              label: Text(item),
                            ),
                          )
                          .toList(),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.home_work),
                    label: const Text(
                      "Request to Rent",
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Rental request feature coming next.",
                          ),
                        ),
                      );
                    },
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
