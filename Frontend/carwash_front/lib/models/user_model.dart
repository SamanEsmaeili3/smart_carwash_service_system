enum UserRole { customer, carwash, admin }

class UserModel {
  final String email;
  final UserRole role;

  UserModel({required this.email, required this.role});

factory UserModel.fromToken(Map<String, dynamic> decodedToken) {
    // It sends 'admin', 'carwash', or 'customer' in the 'role' field.
    String roleString = decodedToken['role'] ?? 'customer';

    return UserModel(
      email: decodedToken['email'] ?? '',
      role: _parseRole(roleString),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'carwash':
        return UserRole.carwash;
      default:
        return UserRole.customer;
    }
  }
}
