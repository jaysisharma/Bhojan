class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final String section;
  final String status; // 'FREE', 'OCCUPIED', 'BILLING', 'DIRTY'

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.section,
    required this.status,
  });

  TableModel copyWith({
    String? id,
    String? tableNumber,
    int? capacity,
    String? section,
    String? status,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      section: section ?? this.section,
      status: status ?? this.status,
    );
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as String,
      capacity: json['capacity'] as int,
      section: json['section'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'section': section,
      'status': status,
    };
  }
}
