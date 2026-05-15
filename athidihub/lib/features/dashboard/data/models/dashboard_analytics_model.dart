class DashboardAnalyticsModel {
  final String? organizationId;
  final String? organizationName;
  final int propertyCount;
  final int roomCount;
  final int bedCount;
  final int occupiedBedCount;
  final int availableBedCount;
  final int tenantCount;
  final int activeTenantCount;
  final int activeAssignmentCount;
  final int openMaintenanceCount;
  final double occupancyRate;
  final double monthlyRevenue;
  final int paidCount;
  final double pendingAmount;
  final int pendingCount;
  final double overdueAmount;
  final int overdueCount;
  final double totalCollected;
  final double totalBilled;
  final double collectionRate;
  final List<DashboardMonthPoint> monthlySeries;
  final List<DashboardPaymentActivity> recentPayments;
  final List<DashboardInvoiceActivity> recentInvoices;
  final List<DashboardMaintenanceActivity> recentMaintenance;

  DashboardAnalyticsModel({
    this.organizationId,
    this.organizationName,
    required this.propertyCount,
    required this.roomCount,
    required this.bedCount,
    required this.occupiedBedCount,
    required this.availableBedCount,
    required this.tenantCount,
    required this.activeTenantCount,
    required this.activeAssignmentCount,
    required this.openMaintenanceCount,
    required this.occupancyRate,
    required this.monthlyRevenue,
    required this.paidCount,
    required this.pendingAmount,
    required this.pendingCount,
    required this.overdueAmount,
    required this.overdueCount,
    required this.totalCollected,
    required this.totalBilled,
    required this.collectionRate,
    required this.monthlySeries,
    required this.recentPayments,
    required this.recentInvoices,
    required this.recentMaintenance,
  });

  factory DashboardAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final overview = Map<String, dynamic>.from(json['overview'] ?? const {});
    final finance = Map<String, dynamic>.from(json['finance'] ?? const {});
    return DashboardAnalyticsModel(
      organizationId: json['organization']?['id']?.toString(),
      organizationName: json['organization']?['name']?.toString(),
      propertyCount: overview['propertyCount'] ?? 0,
      roomCount: overview['roomCount'] ?? 0,
      bedCount: overview['bedCount'] ?? 0,
      occupiedBedCount: overview['occupiedBedCount'] ?? 0,
      availableBedCount: overview['availableBedCount'] ?? 0,
      tenantCount: overview['tenantCount'] ?? 0,
      activeTenantCount: overview['activeTenantCount'] ?? 0,
      activeAssignmentCount: overview['activeAssignmentCount'] ?? 0,
      openMaintenanceCount: overview['openMaintenanceCount'] ?? 0,
      occupancyRate: (overview['occupancyRate'] ?? 0).toDouble(),
      monthlyRevenue: (finance['monthlyRevenue'] ?? 0).toDouble(),
      paidCount: finance['paidCount'] ?? 0,
      pendingAmount: (finance['pendingAmount'] ?? 0).toDouble(),
      pendingCount: finance['pendingCount'] ?? 0,
      overdueAmount: (finance['overdueAmount'] ?? 0).toDouble(),
      overdueCount: finance['overdueCount'] ?? 0,
      totalCollected: (finance['totalCollected'] ?? 0).toDouble(),
      totalBilled: (finance['totalBilled'] ?? 0).toDouble(),
      collectionRate: (finance['collectionRate'] ?? 0).toDouble(),
      monthlySeries: (json['monthlySeries'] as List? ?? const [])
          .map((item) => DashboardMonthPoint.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      recentPayments: (json['recentPayments'] as List? ?? const [])
          .map((item) => DashboardPaymentActivity.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      recentInvoices: (json['recentInvoices'] as List? ?? const [])
          .map((item) => DashboardInvoiceActivity.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      recentMaintenance: (json['recentMaintenance'] as List? ?? const [])
          .map((item) => DashboardMaintenanceActivity.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  factory DashboardAnalyticsModel.empty() {
    return DashboardAnalyticsModel(
      organizationId: null,
      organizationName: null,
      propertyCount: 0,
      roomCount: 0,
      bedCount: 0,
      occupiedBedCount: 0,
      availableBedCount: 0,
      tenantCount: 0,
      activeTenantCount: 0,
      activeAssignmentCount: 0,
      openMaintenanceCount: 0,
      occupancyRate: 0,
      monthlyRevenue: 0,
      paidCount: 0,
      pendingAmount: 0,
      pendingCount: 0,
      overdueAmount: 0,
      overdueCount: 0,
      totalCollected: 0,
      totalBilled: 0,
      collectionRate: 0,
      monthlySeries: const [],
      recentPayments: const [],
      recentInvoices: const [],
      recentMaintenance: const [],
    );
  }
}

class DashboardMonthPoint {
  final int month;
  final int year;
  final String label;
  final double revenue;
  final int paidCount;

  const DashboardMonthPoint({
    required this.month,
    required this.year,
    required this.label,
    required this.revenue,
    required this.paidCount,
  });

  factory DashboardMonthPoint.fromJson(Map<String, dynamic> json) {
    return DashboardMonthPoint(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      paidCount: json['paidCount'] ?? 0,
    );
  }
}

class DashboardPaymentActivity {
  final String id;
  final String invoiceId;
  final String tenantName;
  final double amount;
  final String method;
  final String status;
  final String? paidAt;
  final String createdAt;

  const DashboardPaymentActivity({
    required this.id,
    required this.invoiceId,
    required this.tenantName,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });

  factory DashboardPaymentActivity.fromJson(Map<String, dynamic> json) {
    return DashboardPaymentActivity(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paidAt: json['paidAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class DashboardInvoiceActivity {
  final String id;
  final String tenantName;
  final double totalAmount;
  final String status;
  final String dueDate;
  final String createdAt;

  const DashboardInvoiceActivity({
    required this.id,
    required this.tenantName,
    required this.totalAmount,
    required this.status,
    required this.dueDate,
    required this.createdAt,
  });

  factory DashboardInvoiceActivity.fromJson(Map<String, dynamic> json) {
    return DashboardInvoiceActivity(
      id: json['id']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class DashboardMaintenanceActivity {
  final String id;
  final String category;
  final String status;
  final String propertyId;
  final String createdAt;

  const DashboardMaintenanceActivity({
    required this.id,
    required this.category,
    required this.status,
    required this.propertyId,
    required this.createdAt,
  });

  factory DashboardMaintenanceActivity.fromJson(Map<String, dynamic> json) {
    return DashboardMaintenanceActivity(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      propertyId: json['propertyId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
