class ReviewModel {
  final int id;
  final String customerName;
  final List<String> services;
  final double rating;
  final String comment;
  final String date;

  ReviewModel({
    required this.id, required this.customerName, required this.services,
    required this.rating, required this.comment, required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      customerName: json['customer_name'] ?? 'ناشناس',
      services: List<String>.from(json['service_names'] ?? []),
      rating: (json['carwash_rating'] ?? 0).toDouble(),
      comment: json['carwash_comment'] ?? '',
      date: json['date'] ?? '',
    );
  }
}