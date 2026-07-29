class PropertyUnit {
  final String block;
  final int floor;
  final String unitNumber;

  double rent;

  bool occupied;

  PropertyUnit({
    required this.block,
    required this.floor,
    required this.unitNumber,
    this.rent = 0,
    this.occupied = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "block": block,
      "floor": floor,
      "unit_number": unitNumber,
      "rent": rent,
      "occupied": occupied,
    };
  }
}
