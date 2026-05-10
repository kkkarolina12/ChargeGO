class User {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? avatarUrl;
  final double balance;
  final String status;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.balance = 0.0,
    this.status = 'activo',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['id_usuario']) as String,
      email: json['email'] as String,
      name: (json['name'] ?? _fullNameFromSchema(json)) as String?,
      phoneNumber: (json['phoneNumber'] ?? json['telefono']) as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] ?? json['estado'] ?? 'activo') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'balance': balance,
      'status': status,
    };
  }

  Map<String, dynamic> toFirestoreSchema() {
    return {
      'id_usuario': id,
      'nombre': name ?? '',
      'apellido': '',
      'email': email,
      'telefono': phoneNumber ?? '',
      'estado': status,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? avatarUrl,
    double? balance,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      balance: balance ?? this.balance,
      status: status ?? this.status,
    );
  }
}

String? _fullNameFromSchema(Map<String, dynamic> json) {
  final firstName = (json['nombre'] as String?)?.trim() ?? '';
  final lastName = (json['apellido'] as String?)?.trim() ?? '';
  final fullName = [
    firstName,
    lastName,
  ].where((part) => part.isNotEmpty).join(' ');
  return fullName.isEmpty ? null : fullName;
}
