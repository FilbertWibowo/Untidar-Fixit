class ReportPhoto {
  final int id;
  final String filePath;
  final String type; // 'before' | 'after'
  final String uploadedAt;

  ReportPhoto({
    required this.id,
    required this.filePath,
    required this.type,
    required this.uploadedAt,
  });

  factory ReportPhoto.fromJson(Map<String, dynamic> json) {
    return ReportPhoto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      filePath: json['file_path'] ?? '',
      type: json['type'] ?? 'before',
      uploadedAt: json['uploaded_at'] ?? '',
    );
  }
}

class TimelineEvent {
  final int id;
  final String status;
  final String? note;
  final String? photoPath;
  final String changedByName;
  final String changedByRole;
  final String createdAt;

  TimelineEvent({
    required this.id,
    required this.status,
    this.note,
    this.photoPath,
    required this.changedByName,
    required this.changedByRole,
    required this.createdAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      status: json['status'] ?? '',
      note: json['note'],
      photoPath: json['photo_path'],
      changedByName: json['changed_by_name'] ?? 'Petugas',
      changedByRole: json['changed_by_role'] ?? 'admin',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ReportModel {
  final int id;
  final String ticketNumber;
  final int userId;
  final String? reporterName;
  final String? reporterEmail;
  final String? reporterNpm;
  final String building;
  final String floor;
  final String room;
  final String? locationCode;
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String title;
  final String description;
  final String urgencyLevel; // 'rendah' | 'sedang' | 'tinggi'
  final String status; // 'terkirim' | 'diverifikasi' | 'ditugaskan' | 'selesai' | 'ditolak'
  final String? rejectionReason;
  int priorityScore;
  int upvoteCount;
  bool userHasUpvoted;
  final String createdAt;
  final String? resolvedAt;
  final String? thumbnailPath;
  final List<ReportPhoto> photos;
  final List<TimelineEvent> timeline;
  final Map<String, dynamic>? assignment;
  final Map<String, dynamic>? rating;

  ReportModel({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    this.reporterName,
    this.reporterEmail,
    this.reporterNpm,
    required this.building,
    required this.floor,
    required this.room,
    this.locationCode,
    this.categoryId = 1,
    required this.categoryName,
    this.categoryIcon,
    required this.title,
    required this.description,
    required this.urgencyLevel,
    required this.status,
    this.rejectionReason,
    required this.priorityScore,
    required this.upvoteCount,
    required this.userHasUpvoted,
    required this.createdAt,
    this.resolvedAt,
    this.thumbnailPath,
    this.photos = const [],
    this.timeline = const [],
    this.assignment,
    this.rating,
  });

  String get fullLocation => '$building - $floor, $room';

  String get priorityLabel {
    if (priorityScore >= 15) return 'Kritis';
    if (priorityScore >= 10) return 'Tinggi';
    if (priorityScore >= 5) return 'Sedang';
    return 'Rendah';
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      reporterName: json['reporter_name'],
      reporterEmail: json['reporter_email'],
      reporterNpm: json['reporter_npm'],
      building: json['building'] ?? '',
      floor: json['floor'] ?? '',
      room: json['room'] ?? '',
      locationCode: json['location_code'],
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '') ?? 1,
      categoryName: json['category_name'] ?? 'Fasilitas',
      categoryIcon: json['category_icon'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      urgencyLevel: json['urgency_level'] ?? 'rendah',
      status: json['status'] ?? 'terkirim',
      rejectionReason: json['rejection_reason'],
      priorityScore: json['priority_score'] is int
          ? json['priority_score']
          : int.tryParse(json['priority_score'].toString()) ?? 0,
      upvoteCount: json['upvote_count'] is int
          ? json['upvote_count']
          : int.tryParse(json['upvote_count'].toString()) ?? 0,
      userHasUpvoted: json['user_has_upvoted'] == true || json['user_has_upvoted'] == 1,
      createdAt: json['created_at'] ?? '',
      resolvedAt: json['resolved_at'],
      thumbnailPath: json['thumbnail_path'],
      photos: json['photos'] is List
          ? (json['photos'] as List).map((p) => ReportPhoto.fromJson(p)).toList()
          : [],
      timeline: json['timeline'] is List
          ? (json['timeline'] as List).map((t) => TimelineEvent.fromJson(t)).toList()
          : [],
      assignment: json['assignment'],
      rating: json['rating'],
    );
  }
}
