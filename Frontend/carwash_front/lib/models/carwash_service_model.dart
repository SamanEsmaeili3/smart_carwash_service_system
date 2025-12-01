class CarwashServiceModel {
  final int? id;
  final String serviceName;
  final String description;
  final int price;

  CarwashServiceModel({
    this.id,
    required this.serviceName,
    required this.description,
    required this.price,
  });

  factory CarwashServiceModel.fromJson(Map<String, dynamic> json) {
    return CarwashServiceModel(
      id: json['id'],
      serviceName: json['service_name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "service_name": serviceName,
      "description": description,
      "price": price,
    };
  }
}
