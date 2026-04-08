class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      profileImage: json['profileImage'],
    );
  }
}

class WorkerModel {
  final String id;
  final UserModel user;
  final List<String> skills;
  final double experience;
  final String? bio;
  final double avgRating;
  final int totalRatings;
  final int totalBookings;
  final bool isAvailable;
  final String status;
  final int serviceRadius;

  WorkerModel({
    required this.id,
    required this.user,
    required this.skills,
    required this.experience,
    this.bio,
    required this.avgRating,
    required this.totalRatings,
    required this.totalBookings,
    required this.isAvailable,
    required this.status,
    required this.serviceRadius,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['_id'] ?? '',
      user: json['user'] is Map 
          ? UserModel.fromJson(Map<String, dynamic>.from(json['user'])) 
          : UserModel(id: json['user']?.toString() ?? '', name: 'Unknown', email: '', phone: '', role: 'worker'),
      skills: List<String>.from(json['skills'] ?? []),
      experience: (json['experience'] ?? 0).toDouble(),
      bio: json['bio'],
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      status: json['status'] ?? 'pending',
      serviceRadius: json['serviceRadius'] ?? 10,
    );
  }
}

class BookingModel {
  final String id;
  final String serviceType;
  final String description;
  final String status;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final WorkerModel? worker;
  final UserModel? customer;
  final double? estimatedCost;
  final double? finalCost;
  final ReviewModel? review;
  final List<String> images;

  BookingModel({
    required this.id,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    this.worker,
    this.customer,
    this.estimatedCost,
    this.finalCost,
    this.review,
    required this.images,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? '',
      serviceType: json['serviceType'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      worker: json['worker'] is Map ? WorkerModel.fromJson(Map<String, dynamic>.from(json['worker'])) : null,
      customer: json['customer'] is Map ? UserModel.fromJson(Map<String, dynamic>.from(json['customer'])) : null,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      finalCost: (json['finalCost'] as num?)?.toDouble(),
      review: json['review'] != null ? ReviewModel.fromJson(json['review']) : null,
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class ReviewModel {
  final double rating;
  final String? comment;
  final DateTime? createdAt;

  ReviewModel({required this.rating, this.comment, this.createdAt});

  factory ReviewModel.fromJson(dynamic json) {
    if (json is! Map) return ReviewModel(rating: 0);
    final j = Map<String, dynamic>.from(json);
    return ReviewModel(
      rating: (j['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }
}

class MessageModel {
  final String id;
  final String bookingId;
  final UserModel sender;
  final String senderRole;
  final String? content;
  final String? image;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.bookingId,
    required this.sender,
    required this.senderRole,
    this.content,
    this.image,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      bookingId: json['booking'] ?? '',
      sender: json['sender'] is Map 
          ? UserModel.fromJson(Map<String, dynamic>.from(json['sender'])) 
          : UserModel(id: json['sender']?.toString() ?? '', name: 'User', email: '', phone: '', role: 'customer'),
      senderRole: json['senderRole'] ?? 'customer',
      content: json['content'],
      image: json['image'],
      type: json['type'] ?? 'text',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
