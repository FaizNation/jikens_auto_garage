class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
    };
  }
}
