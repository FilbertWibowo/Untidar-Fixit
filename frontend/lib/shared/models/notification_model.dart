class NotificationModel {
  final int id;
  final int? reportId;
  final String title;
  final String message;
  bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.reportId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      reportId: json['report_id'] != null ? int.tryParse(json['report_id'].toString()) : null,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}
