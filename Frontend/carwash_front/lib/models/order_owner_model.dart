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

    String? cleanText(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return null;
      return text;
    }

    // Prefer nested `customer` object when available (added in backend)
    String name = 'مشتری';
    String phone = 'نامشخص';
    String? email;

    final customerObj = json['customer'];
    if (customerObj is Map<String, dynamic>) {
      name = (customerObj['full_name'] ?? name).toString();
      phone = (customerObj['phone_number'] ?? phone).toString();
      email = (customerObj['email'] ?? json['customer_email'])?.toString();
    } else {
      name = (json['customer_name'] ?? name).toString();
      phone = (json['customer_phone'] ?? phone).toString();
      email = (json['customer_email'])?.toString();
    }

    Map<String, dynamic>? vehicleObj;
    final rawVehicle = json['vehicle'];
    if (rawVehicle is Map) {
      vehicleObj = Map<String, dynamic>.from(rawVehicle);
    }

    final vehiclePlate =
        cleanText(json['vehicle_plate']) ??
        cleanText(vehicleObj?['license_plate']) ??
        cleanText(json['license_plate']);

    String? vehicleInfo = cleanText(json['vehicle_info']);
    if (vehicleInfo == null) {
      final vehicleMake =
          cleanText(json['vehicle_make']) ??
          cleanText(vehicleObj?['make']) ??
          cleanText(json['make']);
      final vehicleModel =
          cleanText(json['vehicle_model']) ??
          cleanText(vehicleObj?['model']) ??
          cleanText(json['model']);
      final vehicleColor =
          cleanText(json['vehicle_color']) ??
          cleanText(vehicleObj?['color']) ??
          cleanText(json['color']);

      final nameParts =
          [vehicleMake, vehicleModel].whereType<String>().toList();
      final vehicleName = nameParts.join(' ').trim();
      if (vehicleName.isNotEmpty && vehicleColor != null) {
        vehicleInfo = '$vehicleName ($vehicleColor)';
      } else if (vehicleName.isNotEmpty) {
        vehicleInfo = vehicleName;
      } else {
        vehicleInfo = vehicleColor;
      }
    }

    return OrderOwnerModel(
      id: json['id'] ?? 0,
      customerName: name,
      customerPhone: phone,
      customerEmail: email,
      vehiclePlate: vehiclePlate,
      vehicleInfo: vehicleInfo,
      scheduledTime: parseDate(json['scheduled_time']),
      // اصلاح این خط برای تبدیل رشته به عدد:
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
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
