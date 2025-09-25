class AppUser {
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        userId: map['userId'],
        name: map['name'],
        email: map['email'],
        photoUrl: map['photoUrl'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}
