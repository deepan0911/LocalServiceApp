class AdminUser {
  final String id, name, email, phone, role;
  final bool isActive;
  final DateTime createdAt;

  AdminUser({required this.id, required this.name, required this.email,
      required this.phone, required this.role, required this.isActive,
      required this.createdAt});

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['_id'] ?? '', name: j['name'] ?? '', email: j['email'] ?? '',
    phone: j['phone'] ?? '', role: j['role'] ?? 'customer',
    isActive: j['isActive'] ?? true,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class AdminWorker {
  final String id, status;
  final AdminUser user;
  final List<String> skills;
  final double avgRating, experience;
  final bool isAvailable;
  final String? aadhaarFront, aadhaarBack, additionalIdImage, rejectionReason;
  final String? additionalIdType, aadhaarNumber;
  final DateTime createdAt;

  AdminWorker({required this.id, required this.status, required this.user,
      required this.skills, required this.avgRating, required this.experience,
      required this.isAvailable, this.aadhaarFront, this.aadhaarBack,
      this.additionalIdImage, this.rejectionReason, this.additionalIdType,
      this.aadhaarNumber, required this.createdAt});

  factory AdminWorker.fromJson(Map<String, dynamic> j) => AdminWorker(
    id: j['_id'] ?? '', status: j['status'] ?? 'pending',
    user: (j['user'] is Map) ? AdminUser.fromJson(Map<String, dynamic>.from(j['user'])) : AdminUser.fromJson({}),
    skills: List<String>.from(j['skills'] ?? []),
    avgRating: (j['avgRating'] ?? 0).toDouble(),
    experience: (j['experience'] ?? 0).toDouble(),
    isAvailable: j['isAvailable'] ?? false,
    aadhaarFront: j['aadhaarFront'], aadhaarBack: j['aadhaarBack'],
    additionalIdImage: j['additionalIdImage'], rejectionReason: j['rejectionReason'],
    additionalIdType: j['additionalIdType'], aadhaarNumber: j['aadhaarNumber'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class AdminBooking {
  final String id, serviceType, status, description;
  final AdminUser? customer;
  final AdminWorker? worker;
  final DateTime createdAt, scheduledAt;

  AdminBooking({required this.id, required this.serviceType, required this.status,
      required this.description, this.customer, this.worker,
      required this.createdAt, required this.scheduledAt});

  factory AdminBooking.fromJson(Map<String, dynamic> j) => AdminBooking(
    id: j['_id'] ?? '', serviceType: j['serviceType'] ?? '',
    status: j['status'] ?? '', description: j['description'] ?? '',
    customer: (j['customer'] is Map) ? AdminUser.fromJson(Map<String, dynamic>.from(j['customer'])) : null,
    worker: (j['worker'] is Map) ? AdminWorker.fromJson(Map<String, dynamic>.from(j['worker'])) : null,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    scheduledAt: DateTime.tryParse(j['scheduledAt'] ?? '') ?? DateTime.now(),
  );
}

class Complaint {
  final String id, subject, description, status;
  final AdminUser? raisedBy, against;
  final String? resolution;
  final DateTime createdAt;

  Complaint({required this.id, required this.subject, required this.description,
      required this.status, this.raisedBy, this.against, this.resolution,
      required this.createdAt});

  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
    id: j['_id'] ?? '', subject: j['subject'] ?? '',
    description: j['description'] ?? '', status: j['status'] ?? 'open',
    raisedBy: (j['raisedBy'] is Map) ? AdminUser.fromJson(Map<String, dynamic>.from(j['raisedBy'])) : null,
    against: (j['against'] is Map) ? AdminUser.fromJson(Map<String, dynamic>.from(j['against'])) : null,
    resolution: j['resolution'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class Analytics {
  final int totalCustomers, totalWorkers, totalBookings, pendingWorkers, activeBookings;
  final double totalRevenue;
  final List<Map<String, dynamic>> bookingsByStatus, topServices;

  Analytics({required this.totalCustomers, required this.totalWorkers,
      required this.totalBookings, required this.pendingWorkers,
      required this.activeBookings, required this.totalRevenue,
      required this.bookingsByStatus, required this.topServices});

  factory Analytics.fromJson(Map<String, dynamic> j) => Analytics(
    totalCustomers: j['totalCustomers'] ?? 0,
    totalWorkers: j['totalWorkers'] ?? 0,
    totalBookings: j['totalBookings'] ?? 0,
    pendingWorkers: j['pendingWorkers'] ?? 0,
    activeBookings: j['activeBookings'] ?? 0,
    totalRevenue: (j['totalRevenue'] ?? 0).toDouble(),
    bookingsByStatus: List<Map<String, dynamic>>.from(j['bookingsByStatus'] ?? []),
    topServices: List<Map<String, dynamic>>.from(j['topServices'] ?? []),
  );
}
