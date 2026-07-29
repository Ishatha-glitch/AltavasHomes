
class PropertyModel {
  final String name;

  final String type;

  final String description;

  final String country;

  final String county;

  final String town;

  final String estate;

  final String street;

  final double latitude;

  final double longitude;

  PropertyModel({
    required this.name,
    required this.type,
    required this.description,
    required this.country,
    required this.county,
    required this.town,
    required this.estate,
    required this.street,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "type": type,
      "description": description,
      "country": country,
      "county": county,
      "town": town,
      "estate": estate,
      "street": street,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}
