class LocationModel {
  final String id;
  final String name;
  final double x;
  final double y;

  const LocationModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'LocationModel(id: $id, name: $name, x: $x, y: $y)';
}
