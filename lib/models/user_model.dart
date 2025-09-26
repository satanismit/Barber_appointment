class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin' or 'customer'
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'customer',
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'customer',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
