enum UserRole { customer, carwash, admin }

class UserModel {
  final String email;
  final UserRole role;

  UserModel({required this.email, required this.role});

  factory UserModel.fromToken(Map<String, dynamic> decodedToken) {
    // Note: We assume there is a field called role or user_type in the token.
    // If not, alternative logic (e.g. based on email) is used.
    String roleString = decodedToken['role'] ?? 'customer';

    // Temporary logic to identify admin by email (as explained previously)
    if (decodedToken['email'] != null &&
        decodedToken['email'].toString().contains('admin')) {
      roleString = 'admin';
    }

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
