class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? assignedMunicipality;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.assignedMunicipality,
    required this.createdAt,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'assignedMunicipality': assignedMunicipality,
      'createdAt': createdAt,
    };
  }

  // Convert from Map
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      assignedMunicipality: map['assignedMunicipality'],
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }
}