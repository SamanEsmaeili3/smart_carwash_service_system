class OrderHistoryModel {
  final int id;
  final String carwashName;
  final String carwashImage;
  final DateTime scheduledTime;
  final double totalPrice;
  final String status;
  final String servicesText;

  OrderHistoryModel({
    required this.id,
    required this.carwashName,
    required this.carwashImage,
    required this.scheduledTime,
    required this.totalPrice,
    required this.status,
    required this.servicesText,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel(
      id: json['id'],
      carwashName: json['carwash_name'] ?? 'Carwash',
      carwashImage: json['carwash_image'] ?? '',
      scheduledTime: DateTime.parse(json['scheduled_time']),
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'],
      servicesText: json['services_text'] ?? '',
    );
  }
}