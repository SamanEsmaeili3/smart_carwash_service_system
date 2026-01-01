class Driver {
  final int? id;
  final String fullName;
  final String nationalId;
  final String phoneNumber;
  final String? address;
  final String? personnelPhotoUrl;
  final String status; // AVAILABLE, BUSY, INACTIVE
  final DateTime? createdAt;

  Driver({
    this.id,
    required this.fullName,
    required this.nationalId,
    required this.phoneNumber,
    this.address,
    this.personnelPhotoUrl,
    this.status = 'AVAILABLE',
    this.createdAt,
  });

  // Convert from JSON
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      nationalId: json['national_id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'],
      personnelPhotoUrl: json['personnel_photo'],
      status: json['status'] ?? 'AVAILABLE',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  // Convert to JSON for requests
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'national_id': nationalId,
      'phone_number': phoneNumber,
      if (address != null && address!.isNotEmpty) 'address': address,
    };
  }

  // Copy with updated fields
  Driver copyWith({
    int? id,
    String? fullName,
    String? nationalId,
    String? phoneNumber,
    String? address,
    String? personnelPhotoUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      personnelPhotoUrl: personnelPhotoUrl ?? this.personnelPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
