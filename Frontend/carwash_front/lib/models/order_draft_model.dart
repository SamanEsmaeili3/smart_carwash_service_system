class OrderDraftResponse {
  final int orderId;
  final double totalPrice;

  OrderDraftResponse({required this.orderId, required this.totalPrice});

  factory OrderDraftResponse.fromJson(Map<String, dynamic> json) {
    return OrderDraftResponse(
      orderId: json['id'],
      // استفاده از پارس ایمن برای جلوگیری از کرش اگر قیمت رشته بود
      totalPrice: _parseDouble(json['total_price']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
