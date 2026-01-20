class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String sessionId;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.sessionId,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      photoUrl: json['photo_url'],
      sessionId: json['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'photo_url': photoUrl,
      'session_id': sessionId,
    };
  }
}
