import 'package:flutter/material.dart';

class LandlordPropertyDetails extends StatelessWidget {
  final Map<String, dynamic> property;

  const LandlordPropertyDetails({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final images =
        List<String>.from(property['images'] ?? []);

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
                    "${property['total_units'] ?? 0} Units",
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
