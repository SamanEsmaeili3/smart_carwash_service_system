import 'package:carwash_front/models/carwash_service_model.dart';

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
  final String? password;
  final double? rating;
  final List<CarwashServiceModel> services;

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
    this.password,
    this.services = const [],
    this.rating,
  });

  // helper method to parse double
  static double _parseDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? fallback;
    }
    return fallback;
  }

  // To receive from API (admin)
  factory CarwashModel.fromJson(Map<String, dynamic> json) {
    final rawWorking = json['working_hours'];
    Map<String, String> workingHoursParsed = {};

    if (rawWorking is Map) {
      rawWorking.forEach((k, v) {
        final key = k?.toString() ?? '';
        if (key.isNotEmpty) {
          workingHoursParsed[key] = v?.toString() ?? '';
        }
      });
    }

    // --- Logic to parse services list ---
    var servicesList = <CarwashServiceModel>[];
    if (json['services'] != null) {
      servicesList =
          (json['services'] as List)
              .map((e) => CarwashServiceModel.fromJson(e))
              .toList();
    }

    return CarwashModel(
      id:
          json['id'] is int
              ? json['id'] as int
              : (json['id'] is String ? int.tryParse(json['id']) : null),
      businessName: (json['business_name'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      phoneNumber: (json['phone_number'] ?? '') as String,
      contactEmail: (json['contact_email'] ?? '') as String,
      workingHours: workingHoursParsed,
      licensePhotoUrl: (json['license_photo_url'] ?? '') as String,
      status: json['status']?.toString(),
      latitude: _parseDouble(json['latitude'], fallback: 35.759432),
      longitude: _parseDouble(json['longitude'], fallback: 51.410376),
      services: servicesList,
      rating: (json['rating'] as num?)?.toDouble(),
      // We don't read password from API for security
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
      "password": password,
    };
  }
}
