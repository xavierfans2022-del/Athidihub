class RoomModel {
  final String id;
  final String propertyId;
  final int floorNumber;
  final String roomNumber;
  final String roomType;
  final bool isAC;
  final double monthlyRent;
  final double securityDeposit;
  final int capacity;
  final DateTime createdAt;
  final List<RoomBedModel> beds;

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.floorNumber,
    required this.roomNumber,
    required this.roomType,
    required this.isAC,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.capacity,
    required this.createdAt,
    this.beds = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final rawBeds = json['beds'] as List? ?? [];
    return RoomModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      floorNumber: (json['floorNumber'] as num).toInt(),
      roomNumber: json['roomNumber'] as String,
      roomType: json['roomType'] as String,
      isAC: json['isAC'] as bool,
      monthlyRent: double.parse(json['monthlyRent'].toString()),
      securityDeposit: double.parse(json['securityDeposit'].toString()),
      capacity: (json['capacity'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      beds: rawBeds.map((b) => RoomBedModel.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}

class RoomBedModel {
  final String id;
  final String bedNumber;
  final String status;

  const RoomBedModel({required this.id, required this.bedNumber, required this.status});

  factory RoomBedModel.fromJson(Map<String, dynamic> json) {
    return RoomBedModel(
      id: json['id'] as String,
      bedNumber: json['bedNumber'] as String,
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }
}
