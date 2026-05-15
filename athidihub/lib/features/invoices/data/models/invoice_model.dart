class InvoiceModel {
  final String id;
  final String tenantId;
  final String organizationId;
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
  final String? pdfUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? tenant;

  InvoiceModel({
    required this.id,
    required this.tenantId,
    required this.organizationId,
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
    this.pdfUrl,
    required this.createdAt,
    this.tenant,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      tenantId: json['tenantId'],
      organizationId: json['organizationId'],
      month: json['month'],
      year: json['year'],
      baseRent: double.parse(json['baseRent'].toString()),
      utilityCharges: double.parse(json['utilityCharges'].toString()),
      foodCharges: double.parse(json['foodCharges'].toString()),
      lateFee: double.parse(json['lateFee'].toString()),
      discount: double.parse(json['discount'].toString()),
      totalAmount: double.parse(json['totalAmount'].toString()),
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'],
      pdfUrl: json['pdfUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      tenant: json['tenant'],
    );
  }
}
