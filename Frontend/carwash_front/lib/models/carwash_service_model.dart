class CarwashServiceModel {
  final int? id;
  final String serviceName;
  final String description;
  final double price;

  CarwashServiceModel({
    this.id,
    required this.serviceName,
    required this.description,
    required this.price,
  });

  factory CarwashServiceModel.fromJson(Map<String, dynamic> json) {
    return CarwashServiceModel(
      id: json['id'],
      // 1. SAFE NAME: Checks both 'service_name' (server) and 'name' (backup)
      serviceName: json['service_name'] ?? json['name'] ?? '',
      
      // 2. SAFE DESCRIPTION: Handles nulls
      description: json['description'] ?? '',

      // 3. SAFE PRICE: The most important fix. 
      // It converts the String "1234.00" to the Double 1234.0
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
      // Remove commas and parse string to number
      return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
    }
    return 0.0;
  }
}