class CarwashServiceModel {
  final int? id;
  final String serviceName;
  final String description;
  final double price; // <-- تغییر به double

  CarwashServiceModel({
    this.id,
    required this.serviceName,
    required this.description,
    required this.price,
  });

  factory CarwashServiceModel.fromJson(Map<String, dynamic> json) {
    return CarwashServiceModel(
      id: json['id'],
      serviceName: json['service_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',

      price: _parseDouble(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "service_name": serviceName,
      "description": description,
      "price": price,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      String clean = value.replaceAll(',', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}
