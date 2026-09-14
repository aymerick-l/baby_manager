class Child {
  final String id;
  final String firstName;
  final DateTime birthDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Child({
    required this.id,
    required this.firstName,
    required this.birthDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'birth_date': birthDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'],
      firstName: map['first_name'],
      birthDate: DateTime.parse(map['birth_date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
