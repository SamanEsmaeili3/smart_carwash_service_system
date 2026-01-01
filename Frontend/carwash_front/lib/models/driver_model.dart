class DriverModel {
  final int? id;
  final String fullName;
  final String nationalId;
  final String phoneNumber;
  final String? address;
  final String? personnelPhoto; // URL of the photo from server
  final String status;

  DriverModel({
    this.id,
    required this.fullName,
    required this.nationalId,
    required this.phoneNumber,
    this.address,
    this.personnelPhoto,
    this.status = 'AVAILABLE',
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      nationalId: json['national_id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'],
      personnelPhoto: json['personnel_photo'],
      status: json['status'] ?? 'AVAILABLE',
    );
  }

  // We don't use toJson for creation because we send FormData, 
  // but it's useful for debugging.
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'national_id': nationalId,
      'phone_number': phoneNumber,
      'address': address,
    };
  }
}