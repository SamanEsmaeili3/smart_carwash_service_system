class OrderDraftResponse {
  final int orderId;
  final double totalPrice;

  OrderDraftResponse({required this.orderId, required this.totalPrice});

  factory OrderDraftResponse.fromJson(Map<String, dynamic> json) {
    return OrderDraftResponse(
      orderId: json['id'],
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}
