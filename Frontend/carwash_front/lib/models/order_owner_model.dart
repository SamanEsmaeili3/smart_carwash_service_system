class OrderOwnerModel {
  final int id;
  final String customerName;
  final String customerPhone;
  final DateTime scheduledTime;
  final double totalPrice;
  final String status;
  final List<String> servicesList;
  final DateTime? createdAt;

  OrderOwnerModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.scheduledTime,
    required this.totalPrice,
    required this.status,
    required this.servicesList,
    this.createdAt,
  });

  factory OrderOwnerModel.fromJson(Map<String, dynamic> json) {
    // Safe date parsing
    DateTime parsedScheduledTime;
    try {
      if (json['scheduled_time'] != null) {
        parsedScheduledTime = DateTime.parse(json['scheduled_time'].toString());
      } else {
        parsedScheduledTime = DateTime.now();
      }
    } catch (e) {
      print("Date parsing error for order ID ${json['id']}: $e");
      parsedScheduledTime = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        parsedCreatedAt = null;
      }
    }

    // Parse services list
    List<String> services = [];
    if (json['services_list'] != null) {
      if (json['services_list'] is List) {
        services = List<String>.from(json['services_list']);
      }
    }

    return OrderOwnerModel(
      id: json['id'],
      customerName: json['customer_name'] ?? 'مشتری',
      customerPhone: json['customer_phone'] ?? '',
      scheduledTime: parsedScheduledTime,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      servicesList: services,
      createdAt: parsedCreatedAt,
    );
  }
}

class DriverModel {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String status;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.status,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
    );
  }
}
