class AnnouncementModel {
  final String id;
  final String text;
  final String adminId;
  final String adminName;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.text,
    required this.adminId,
    required this.adminName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'adminId': adminId,
      'adminName': adminName,
      'createdAt': createdAt,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      text: map['text'] ?? '',
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? 'Admin',
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}