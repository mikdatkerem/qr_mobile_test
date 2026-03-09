class ZoneModel {
  final String id;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;

  const ZoneModel({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as String,
      label: json['label'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 80.0,
      height: (json['height'] as num?)?.toDouble() ?? 60.0,
    );
  }

  /// Zone'un merkez noktası (pointer için)
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;

  @override
  String toString() => 'ZoneModel(id: $id, label: $label)';
}
