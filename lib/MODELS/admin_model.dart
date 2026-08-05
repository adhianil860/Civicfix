class AdminModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String department;
  final DateTime createdAt;

  AdminModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'admin',
    this.department = 'Municipality Administration',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'createdAt': createdAt,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map, String uid) {
    return AdminModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'admin',
      department: map['department'] ?? 'Municipality Administration',
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }
}