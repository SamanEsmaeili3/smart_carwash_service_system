class OrderHistoryModel {
  final int id;
  final String carwashName;
  final String carwashImage;
  final DateTime scheduledTime;
  final double totalPrice;
  final String status;
  final String servicesText;
  final bool hasRating;
  // New fields for displaying the submitted review
  final int? carwashRating;
  final String? carwashComment;
  final int? driverRating;

  OrderHistoryModel({
    required this.id,
    required this.carwashName,
    required this.carwashImage,
    required this.scheduledTime,
    required this.totalPrice,
    required this.status,
    required this.servicesText,
    required this.hasRating,
    this.carwashRating,
    this.carwashComment,
    this.driverRating,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    // 1. Safe Date Parsing Logic (Your original block preserved)
    DateTime parsedDate;
    try {
      if (json['scheduled_time'] != null) {
        parsedDate = DateTime.parse(json['scheduled_time'].toString());
      } else {
        parsedDate = DateTime.now(); // Fallback if null
      }
    } catch (e) {
      print("Date parsing error for ID ${json['id']}: $e");
      parsedDate = DateTime.now(); // Fallback if format is invalid
    }

    // Extract nested rating details from the backend
    final ratingData = json['rating_details'];

    return OrderHistoryModel(
      id: json['id'],
      carwashName: json['carwash_name'] ?? 'Carwash',
      carwashImage: json['carwash_image'] ?? '',
      scheduledTime: parsedDate, 
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      servicesText: json['services_text'] ?? '',
      hasRating: json['has_rating'] ?? false,
      // Map submitted rating data for display
      carwashRating: ratingData?['carwash_rating'],
      carwashComment: ratingData?['carwash_comment'],
      driverRating: ratingData?['driver_rating'],
    );
  }
}