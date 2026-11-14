class UserModel {
  final int id;
  final String role; // 'mahasiswa' | 'admin'
  final String? npm;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.role,
    this.npm,
    required this.name,
    required this.email,
  });

  bool get isAdmin => role == 'admin';
  bool get isMahasiswa => role == 'mahasiswa';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      role: json['role'] ?? 'mahasiswa',
      npm: json['npm'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'npm': npm,
        'name': name,
        'email': email,
      };
}
