class PropertyModel {
  final String id;
  final String organizationId;
  final String name;
  final String address;
  final String city;
  final String state;
  final int totalFloors;
  final List<String> amenities;
  final List<String> imageUrls;
  final String? managerId;
  final bool isActive;
  final DateTime createdAt;
  final List<dynamic>? rooms;

  PropertyModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.totalFloors,
    required this.amenities,
    required this.imageUrls,
    this.managerId,
    required this.isActive,
    required this.createdAt,
    this.rooms,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      totalFloors: (json['totalFloors'] as num).toInt(),
      amenities: List<String>.from(json['amenities'] ?? []),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      managerId: json['managerId'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rooms: json['rooms'] as List?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'organizationId': organizationId, 'name': name,
    'address': address, 'city': city, 'state': state,
    'totalFloors': totalFloors, 'amenities': amenities, 'imageUrls': imageUrls,
    'managerId': managerId, 'isActive': isActive, 'createdAt': createdAt.toIso8601String(),
  };
}
