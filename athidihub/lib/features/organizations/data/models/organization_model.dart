import 'dart:convert';

class OrganizationModel {
  final String id;
  final String name;
  final String businessType;
  final String? gstNumber;
  final String ownerId;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.businessType,
    this.gstNumber,
    required this.ownerId,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      businessType: json['businessType'] as String,
      gstNumber: json['gstNumber'] as String?,
      ownerId: json['ownerId'] as String,
      logoUrl: json['logoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'businessType': businessType,
      'gstNumber': gstNumber,
      'ownerId': ownerId,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? businessType,
    String? gstNumber,
    String? ownerId,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      gstNumber: gstNumber ?? this.gstNumber,
      ownerId: ownerId ?? this.ownerId,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'OrganizationModel(id: $id, name: $name, businessType: $businessType)';
}
