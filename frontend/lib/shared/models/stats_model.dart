class AdminStatsModel {
  final int totalReports;
  final int activeReports;
  final int resolvedReports;
  final int rejectedReports;
  final Map<String, int> statusCounts;
  final double avgResolveHours;
  final double avgRating;
  final int totalRatings;
  final List<Map<String, dynamic>> topBuildings;
  final List<Map<String, dynamic>> categoriesStats;
  final List<Map<String, dynamic>> buildingHeatmap;

  AdminStatsModel({
    required this.totalReports,
    required this.activeReports,
    required this.resolvedReports,
    required this.rejectedReports,
    required this.statusCounts,
    required this.avgResolveHours,
    required this.avgRating,
    required this.totalRatings,
    required this.topBuildings,
    required this.categoriesStats,
    required this.buildingHeatmap,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final countsRaw = s['status_counts'] as Map<String, dynamic>? ?? {};
    final counts = countsRaw.map((k, v) => MapEntry(k, int.tryParse(v.toString()) ?? 0));

    return AdminStatsModel(
      totalReports: int.tryParse(s['total_reports'].toString()) ?? 0,
      activeReports: int.tryParse(s['active_reports'].toString()) ?? 0,
      resolvedReports: int.tryParse(s['resolved_reports'].toString()) ?? 0,
      rejectedReports: int.tryParse(s['rejected_reports'].toString()) ?? 0,
      statusCounts: counts,
      avgResolveHours: double.tryParse(s['avg_resolve_hours'].toString()) ?? 0.0,
      avgRating: double.tryParse(s['avg_rating'].toString()) ?? 0.0,
      totalRatings: int.tryParse(s['total_ratings'].toString()) ?? 0,
      topBuildings: List<Map<String, dynamic>>.from(json['top_buildings'] ?? []),
      categoriesStats: List<Map<String, dynamic>>.from(json['categories_stats'] ?? []),
      buildingHeatmap: List<Map<String, dynamic>>.from(json['building_heatmap'] ?? []),
    );
  }
}
