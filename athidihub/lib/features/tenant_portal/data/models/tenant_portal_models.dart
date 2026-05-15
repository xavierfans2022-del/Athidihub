// ─── Tenant Portal Data Models ───────────────────────────────────────────────

class TenantInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime joiningDate;
  final bool aadhaarVerified;
  final String? aadhaarUrl;
  final Map<String, dynamic>? aadhaarDetails;
  final bool checkInCompleted;
  final DateTime? checkInDate;
  final bool isActive;

  const TenantInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.joiningDate,
    required this.aadhaarVerified,
    this.aadhaarUrl,
    this.aadhaarDetails,
    required this.checkInCompleted,
    this.checkInDate,
    required this.isActive,
  });

  factory TenantInfo.fromJson(Map<String, dynamic> json) => TenantInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        joiningDate: DateTime.parse(json['joiningDate'] as String),
        aadhaarVerified: json['aadhaarVerified'] as bool? ?? false,
        aadhaarUrl: json['aadhaarUrl'] as String?,
        aadhaarDetails: json['aadhaarDetails'] as Map<String, dynamic>?,
        checkInCompleted: json['checkInCompleted'] as bool? ?? false,
        checkInDate: json['checkInDate'] != null
            ? DateTime.tryParse(json['checkInDate'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class TenantAssignment {
  final String id;
  final DateTime startDate;
  final String? bedNumber;
  final String? bedType;
  final String? roomNumber;
  final int? floorNumber;
  final String? roomType;
  final double? monthlyRent;
  final double? securityDeposit;
  final String? propertyName;
  final String? propertyAddress;
  final String? propertyCity;

  const TenantAssignment({
    required this.id,
    required this.startDate,
    this.bedNumber,
    this.bedType,
    this.roomNumber,
    this.floorNumber,
    this.roomType,
    this.monthlyRent,
    this.securityDeposit,
    this.propertyName,
    this.propertyAddress,
    this.propertyCity,
  });

  factory TenantAssignment.fromJson(Map<String, dynamic> json) => TenantAssignment(
        id: json['id'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        bedNumber: json['bedNumber'] as String?,
        bedType: json['bedType'] as String?,
        roomNumber: json['roomNumber'] as String?,
        floorNumber: json['floorNumber'] as int?,
        roomType: json['roomType'] as String?,
        monthlyRent: double.tryParse(json['monthlyRent']?.toString() ?? ''),
        securityDeposit: double.tryParse(json['securityDeposit']?.toString() ?? ''),
        propertyName: json['propertyName'] as String?,
        propertyAddress: json['propertyAddress'] as String?,
        propertyCity: json['propertyCity'] as String?,
      );
}

class TenantOrganization {
  final String id;
  final String name;
  final String? logoUrl;

  const TenantOrganization({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory TenantOrganization.fromJson(Map<String, dynamic> json) => TenantOrganization(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logoUrl'] as String?,
      );
}

class TenantInvoice {
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
  final String status; // PENDING | PAID | OVERDUE | CANCELLED
  final String? pdfUrl;
  final DateTime createdAt;
  final TenantPayment? payment;

  const TenantInvoice({
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
    this.pdfUrl,
    required this.createdAt,
    this.payment,
  });

  factory TenantInvoice.fromJson(Map<String, dynamic> json) => TenantInvoice(
        id: json['id'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        baseRent: double.tryParse(json['baseRent'].toString()) ?? 0,
        utilityCharges: double.tryParse(json['utilityCharges'].toString()) ?? 0,
        foodCharges: double.tryParse(json['foodCharges'].toString()) ?? 0,
        lateFee: double.tryParse(json['lateFee'].toString()) ?? 0,
        discount: double.tryParse(json['discount'].toString()) ?? 0,
        totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0,
        dueDate: DateTime.parse(json['dueDate'] as String),
        status: json['status'] as String,
        pdfUrl: json['pdfUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        payment: json['payment'] != null
            ? TenantPayment.fromJson(json['payment'] as Map<String, dynamic>)
            : null,
      );

  String get monthLabel {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month]} $year';
  }

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'OVERDUE';
  bool get isPending => status == 'PENDING';
}

class TenantPayment {
  final String id;
  final String invoiceId;
  final double amount;
  final String method;
  final String status;
  final DateTime? paidAt;
  final String? receiptUrl;
  final String? gatewayTxnId;
  final TenantInvoice? invoice;

  const TenantPayment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.status,
    this.paidAt,
    this.receiptUrl,
    this.gatewayTxnId,
    this.invoice,
  });

  factory TenantPayment.fromJson(Map<String, dynamic> json) => TenantPayment(
        id: json['id'] as String,
        invoiceId: json['invoiceId'] as String,
        amount: double.tryParse(json['amount'].toString()) ?? 0,
        method: json['method'] as String,
        status: json['status'] as String,
        paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'] as String) : null,
        receiptUrl: json['receiptUrl'] as String?,
        gatewayTxnId: json['gatewayTxnId'] as String?,
        invoice: json['invoice'] != null
            ? TenantInvoice.fromJson(json['invoice'] as Map<String, dynamic>)
            : null,
      );
}

class TenantDashboard {
  final TenantInfo tenant;
  final TenantAssignment? assignment;
  final TenantOrganization? organization;
  final TenantInvoice? currentInvoice;
  final List<TenantInvoice> overdueInvoices;
  final List<TenantInvoice> upcomingInvoices;
  final int overdueCount;
  final List<TenantPayment> recentPayments;
  final int maintenanceOpen;
  final double totalPaid;

  const TenantDashboard({
    required this.tenant,
    this.assignment,
    this.organization,
    this.currentInvoice,
    required this.overdueInvoices,
    required this.upcomingInvoices,
    required this.overdueCount,
    required this.recentPayments,
    required this.maintenanceOpen,
    required this.totalPaid,
  });

  factory TenantDashboard.fromJson(Map<String, dynamic> json) => TenantDashboard(
        tenant: TenantInfo.fromJson(json['tenant'] as Map<String, dynamic>),
        assignment: json['assignment'] != null
            ? TenantAssignment.fromJson(json['assignment'] as Map<String, dynamic>)
            : null,
        organization: json['organization'] != null
            ? TenantOrganization.fromJson(json['organization'] as Map<String, dynamic>)
            : null,
        currentInvoice: json['currentInvoice'] != null
            ? TenantInvoice.fromJson(json['currentInvoice'] as Map<String, dynamic>)
            : null,
        overdueInvoices: (json['overdueInvoices'] as List<dynamic>? ?? [])
            .map((e) => TenantInvoice.fromJson(e as Map<String, dynamic>))
            .toList(),
        upcomingInvoices: (json['upcomingInvoices'] as List<dynamic>? ?? [])
            .map((e) => TenantInvoice.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentPayments: (json['recentPayments'] as List<dynamic>? ?? [])
            .map((e) => TenantPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        maintenanceOpen: json['maintenanceOpen'] as int? ?? 0,
        overdueCount: json['overdueCount'] as int? ?? 0,
        totalPaid: double.tryParse(json['totalPaid'].toString()) ?? 0,
      );
}

class PaginatedInvoices {
  final List<TenantInvoice> data;
  final int total;
  final int page;
  final bool hasMore;

  const PaginatedInvoices({
    required this.data,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory PaginatedInvoices.fromJson(Map<String, dynamic> json) => PaginatedInvoices(
        data: (json['data'] as List<dynamic>)
            .map((e) => TenantInvoice.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        hasMore: json['hasMore'] as bool,
      );
}

class PaginatedPayments {
  final List<TenantPayment> data;
  final int total;
  final int page;
  final bool hasMore;

  const PaginatedPayments({
    required this.data,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory PaginatedPayments.fromJson(Map<String, dynamic> json) => PaginatedPayments(
        data: (json['data'] as List<dynamic>)
            .map((e) => TenantPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
