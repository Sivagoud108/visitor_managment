import '../core/date.dart';

enum VisitorStatus {
  registered('Registered'),
  checkedIn('Checked In'),
  checkedOut('Checked Out');

  const VisitorStatus(this.label);

  final String label;

  static VisitorStatus fromLabel(String? value) {
    return VisitorStatus.values.firstWhere(
      (status) => status.label == value,
      orElse: () => VisitorStatus.registered,
    );
  }
}

class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  /// Check-in is only allowed from Registered.
  bool get canCheckIn => status == VisitorStatus.registered;

  /// Check-out is only allowed from Checked In.
  bool get canCheckOut => status == VisitorStatus.checkedIn;

  /// Full copyWith — every field is copyable.
  Visitor copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? visitorType,
    String? project,
    String? purpose,
    VisitorStatus? status,
    DateTime? createdAt,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      visitorType: visitorType ?? this.visitorType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }

  factory Visitor.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    return Visitor(
      // crudcrud returns "_id" — fall back to "id" for other backends.
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      email: (email == null || email.isEmpty) ? null : email,
      visitorType: (json['visitor_type'] ?? '').toString(),
      project: (json['project'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      status: VisitorStatus.fromLabel(json['status'] as String?),
      createdAt: _parseDate(json['created_at'] as String?) ?? DateTime.now(),
      checkInTime: _parseDate(json['check_in_time'] as String?),
      checkOutTime: _parseDate(json['check_out_time'] as String?),
    );
  }

  /// The id is not included because the server generates it.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'email': email,
      'visitor_type': visitorType,
      'project': project,
      'purpose': purpose,
      'status': status.label,
      'created_at': toIsoWithOffset(createdAt),
      'check_in_time': _toIso(checkInTime),
      'check_out_time': _toIso(checkOutTime),
    };
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _toIso(DateTime? date) => date == null ? null : toIsoWithOffset(date);