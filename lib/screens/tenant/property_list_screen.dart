import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() =>
      _PropertyListScreenState();
}

class _PropertyListScreenState
    extends State<PropertyListScreen> {

  final supabase = Supabase.instance.client;

  bool loading = true;

  List<Map<String, dynamic>> properties = [];

  @override
  void initState() {
    super.initState();
    loadProperties();
  }

  Future<void> loadProperties() async {
    try {
      final result = await supabase
          .from('properties')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        properties =
            List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Browse Properties"),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadProperties,
              child: properties.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            "No properties available.",
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {

                        final property =
                            properties[index];

                        final images =
                            List<String>.from(
                          property["images"] ?? [],
                        );

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: InkWell(
                            onTap: () {
                              context.push(
                                "/tenant/property",
                                extra: property,
                              );
                            },
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                if (images.isNotEmpty)
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      images.first,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                Padding(
                                  padding:
                                      const EdgeInsets.all(
                                    16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        property["property_name"] ??
                                            property["title"] ??
                                            "",
                                        style:
                                            const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 8),

                                      Text(
                                        property["estate"] ??
                                            "",
                                      ),

                                      const SizedBox(
                                          height: 8),

                                      Text(
                                        property["property_type"] ??
                                            "",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
