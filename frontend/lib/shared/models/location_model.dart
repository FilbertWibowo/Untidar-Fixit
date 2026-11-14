class LocationModel {
  final int id;
  final String building;
  final String floor;
  final String room;
  final String code;
  final String qrSignature;
  final bool isActive;

  LocationModel({
    required this.id,
    required this.building,
    required this.floor,
    required this.room,
    required this.code,
    required this.qrSignature,
    required this.isActive,
  });

  String get displayName => '$building - $floor ($room)';

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      building: json['building'] ?? '',
      floor: json['floor'] ?? '',
      room: json['room'] ?? '',
      code: json['code'] ?? '',
      qrSignature: json['qr_signature'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
