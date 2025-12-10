class CarwashServiceModel {
  final int? id;
  final String serviceName;
  final String description;
  final double price;

  CarwashServiceModel({
    this.id,
    required this.serviceName,
    required this.description,
    required this.price,
  });

  // ------------------------------------------------------------------
  //  FIXED: The main issue is here. Your server sends 'service_name' 
  //  but your original code was potentially checking for 'name' first 
  //  and more importantly, the price conversion was flawed.
  // ------------------------------------------------------------------
  factory CarwashServiceModel.fromJson(Map<String, dynamic> json) {
    // 1. Service Name FIX: Ensure we use the correct field name from the server.
    // The server is sending 'service_name', so we must prioritize it.
    final String serviceName = json['service_name'] ?? json['name'] ?? '';
    
    // 2. Price FIX: Ensure price is safely converted to double, 
    // especially since your server sends it as a string ("1234.00").
    final double priceValue = _parseDouble(json['price']);
    
    // 3. Description: Safe retrieval
    final String description = json['description'] ?? '';

    // If the data is missing critical fields, it's safer to return null, 
    // but we will proceed with the safe parsing:
    return CarwashServiceModel(
      id: json['id'],
      serviceName: serviceName,
      description: description,
      price: priceValue,
    );
  }
  // ------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      "service_name": serviceName,
      "description": description,
      "price": price,
    };
  }

  // Helper function to safely convert dynamic value (String, Int, or Double) to Double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    // If it's already a double, return it.
    if (value is double) return value;
    
    // If it's an int, convert it to a double.
    if (value is int) return value.toDouble();
    
    // If it's a string (e.g., "1234.00" from the server), try to parse it.
    if (value is String) {
      // Remove any commas that might interfere with parsing
      String clean = value.replaceAll(',', '').trim(); 
      return double.tryParse(clean) ?? 0.0; // Return 0.0 if parsing fails
    }
    
    // Fallback for any other type
    return 0.0;
  }
}