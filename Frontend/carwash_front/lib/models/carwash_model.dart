class CarwashModel {
  final int? id;
  final String businessName;
  final String address;
  final String phoneNumber;
  final String contactEmail;
  final Map<String, String> workingHours;
  final String licensePhotoUrl;
  final String? status;
  final double latitude;
  final double longitude;

  CarwashModel({
    this.id,
    required this.businessName,
    required this.address,
    required this.phoneNumber,
    required this.contactEmail,
    required this.workingHours,
    required this.licensePhotoUrl,
    this.status,
    this.latitude = 35.759432,
    this.longitude = 51.410376,
  });

  // To receive from API (admin)
  factory CarwashModel.fromJson(Map<String, dynamic> json) {
    return CarwashModel(
      id: json['id'],
      businessName: json['business_name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      workingHours: json['working_hours'] ?? '',
      licensePhotoUrl: json['license_photo_url'] ?? '',
      status: json['status'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // To send to API (registration)
  Map<String, dynamic> toJson() {
    return {
      "business_name": businessName,
      "address": address,
      "phone_number": phoneNumber,
      "contact_email": contactEmail,
      "working_hours": workingHours,
      "license_photo_url": licensePhotoUrl,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}
