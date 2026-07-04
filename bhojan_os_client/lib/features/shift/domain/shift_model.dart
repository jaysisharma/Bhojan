class ShiftModel {
  final String id;
  final String restaurantId;
  final String openedById;
  final String? openedByName;
  final String? closedById;
  final String? closedByName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? actualCash;
  final double? cashDiff;
  final String status; // OPEN, CLOSED

  ShiftModel({
    required this.id,
    required this.restaurantId,
    required this.openedById,
    this.openedByName,
    this.closedById,
    this.closedByName,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.actualCash,
    this.cashDiff,
    required this.status,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      openedById: json['openedById'] as String,
      openedByName: json['openedBy']?['name'] as String?,
      closedById: json['closedById'] as String?,
      closedByName: json['closedBy']?['name'] as String?,
      openedAt: DateTime.parse(json['openedAt'] as String),
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt'] as String) : null,
      openingCash: double.parse(json['openingCash'].toString()),
      closingCash: json['closingCash'] != null ? double.parse(json['closingCash'].toString()) : null,
      expectedCash: json['expectedCash'] != null ? double.parse(json['expectedCash'].toString()) : null,
      actualCash: json['actualCash'] != null ? double.parse(json['actualCash'].toString()) : null,
      cashDiff: json['cashDiff'] != null ? double.parse(json['cashDiff'].toString()) : null,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'openedById': openedById,
      'closedById': closedById,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'openingCash': openingCash,
      'closingCash': closingCash,
      'expectedCash': expectedCash,
      'actualCash': actualCash,
      'cashDiff': cashDiff,
      'status': status,
    };
  }
}
