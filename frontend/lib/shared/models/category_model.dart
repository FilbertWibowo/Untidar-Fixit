class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final int severityWeight;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.severityWeight,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'build',
      severityWeight: json['severity_weight'] is int
          ? json['severity_weight']
          : int.tryParse(json['severity_weight'].toString()) ?? 1,
    );
  }
}
