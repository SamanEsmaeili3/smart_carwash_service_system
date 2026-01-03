class OrderOwnerModel {
  final int id;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? vehiclePlate;
  final String? vehicleInfo;
  final DateTime scheduledTime;
  final double totalPrice;
  final String status;
  final List<String> servicesList;
  final DateTime createdAt;
  final String? details;

  OrderOwnerModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.vehiclePlate,
    this.vehicleInfo,
    required this.scheduledTime,
    required this.totalPrice,
    required this.status,
    required this.servicesList,
    required this.createdAt,
    this.details,
  });

  factory OrderOwnerModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse date strings
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) {
        return DateTime.now(); // Fallback to current time
      }
      return DateTime.tryParse(dateStr) ?? DateTime.now(); // Fallback
    }

    // Safely parse the list of services
    List<String> parseServices(dynamic serviceData) {
      if (serviceData is List) {
        // Use whereType to filter out any non-string elements just in case
        return serviceData.whereType<String>().toList();
      }
      return []; // Return an empty list if it's not a list
    }

    return OrderOwnerModel(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? 'مشتری',
      customerPhone: json['customer_phone'] ?? 'نامشخص',
      customerEmail: json['customer_email'],
      vehiclePlate: json['vehicle_plate'],
      vehicleInfo: json['vehicle_info'],
      scheduledTime: parseDate(json['scheduled_time']),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      servicesList: parseServices(json['services_list']),
      createdAt: parseDate(json['created_at']),
      details: json['details'],
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
