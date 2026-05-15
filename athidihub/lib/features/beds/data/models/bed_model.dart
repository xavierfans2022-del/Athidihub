class PaymentModel {
  final String id;
  final String status;
  final double amount;
  final String method;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.method,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      method: json['method']?.toString() ?? 'UNKNOWN',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
    );
  }
}

class InvoiceModel {
  final String id;
  final int month;
  final int year;
  final double baseRent;
  final double utilityCharges;
  final double foodCharges;
  final double lateFee;
  final double discount;
  final double totalAmount;
  final DateTime dueDate;
  final String status;
  final PaymentModel? payment;
  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.month,
    required this.year,
    required this.baseRent,
    required this.utilityCharges,
    required this.foodCharges,
    required this.lateFee,
    required this.discount,
    required this.totalAmount,
    required this.dueDate,
    required this.status,
    this.payment,
    required this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final paymentData = json['payment'];
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2024,
      baseRent: double.tryParse(json['baseRent'].toString()) ?? 0.0,
      utilityCharges: double.tryParse(json['utilityCharges'].toString()) ?? 0.0,
      foodCharges: double.tryParse(json['foodCharges'].toString()) ?? 0.0,
      lateFee: double.tryParse(json['lateFee'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'PENDING',
      payment: paymentData != null ? PaymentModel.fromJson(paymentData) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TenantModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime joiningDate;
  final double depositPaid;
  final List<InvoiceModel> invoices;

  TenantModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.joiningDate,
    required this.depositPaid,
    required this.invoices,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final invoicesData = json['invoices'];
    final invoices = invoicesData is List
        ? invoicesData
            .whereType<Map>()
            .map((item) => InvoiceModel.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <InvoiceModel>[];

    return TenantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      joiningDate: DateTime.tryParse(json['joiningDate']?.toString() ?? '') ?? DateTime.now(),
      depositPaid: double.tryParse(json['depositPaid'].toString()) ?? 0.0,
      invoices: invoices,
    );
  }
}

class BedAssignmentModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final bool isActive;
  final TenantModel? tenantDetails;

  BedAssignmentModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.isActive,
    this.tenantDetails,
  });

  factory BedAssignmentModel.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'];
    final tenantName = tenant is Map ? (tenant['name'] ?? tenant['fullName'] ?? '') : '';
    final tenantDetails = tenant is Map ? TenantModel.fromJson(tenant.cast<String, dynamic>()) : null;

    return BedAssignmentModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      tenantName: tenantName.toString(),
      isActive: json['isActive'] ?? false,
      tenantDetails: tenantDetails,
    );
  }
}

class BedModel {
  final String id;
  final String roomId;
  final String bedNumber;
  final String bedType;
  final String status;
  final DateTime createdAt;
  final List<BedAssignmentModel> assignments;

  BedModel({
    required this.id,
    required this.roomId,
    required this.bedNumber,
    required this.bedType,
    required this.status,
    required this.createdAt,
    required this.assignments,
  });

  factory BedModel.fromJson(Map<String, dynamic> json) {
    final rawAssignments = json['assignments'];
    final assignments = rawAssignments is List
        ? rawAssignments
            .whereType<Map>()
            .map((item) => BedAssignmentModel.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <BedAssignmentModel>[];

    return BedModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      bedNumber: json['bedNumber']?.toString() ?? '',
      bedType: json['bedType']?.toString() ?? 'STANDARD',
      status: json['status']?.toString() ?? 'AVAILABLE',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      assignments: assignments,
    );
  }

  BedAssignmentModel? get activeAssignment {
    for (final assignment in assignments) {
      if (assignment.isActive) {
        return assignment;
      }
    }
    return assignments.isNotEmpty ? assignments.first : null;
  }

  String get occupantLabel => activeAssignment?.tenantName.isNotEmpty == true
      ? activeAssignment!.tenantName
      : 'Unassigned';
}
