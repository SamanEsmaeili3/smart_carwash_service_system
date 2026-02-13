class FinancialSummary {
  final double totalEarnings;
  final List<Transaction> transactions;

  FinancialSummary({
    required this.totalEarnings,
    required this.transactions,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    var transactionsList = json['transactions'] as List;
    List<Transaction> transactions = transactionsList
        .map((i) => Transaction.fromJson(i))
        .toList();

    return FinancialSummary(
      totalEarnings: double.tryParse(json['total_earnings'].toString()) ?? 0.0,
      transactions: transactions,
    );
  }
}

class Transaction {
  final int id;
  final String customerName;
  final double totalPrice;
  final String completedAt;

  Transaction({
    required this.id,
    required this.customerName,
    required this.totalPrice,
    required this.completedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      customerName: json['customer_name'] ?? 'Unknown Customer',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      completedAt: json['completed_at'] ?? '',
    );
  }
}
