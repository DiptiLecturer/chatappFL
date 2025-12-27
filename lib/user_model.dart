class AppUser {
  final String uid;
  final String email;
  final String username;

  AppUser({required this.uid, required this.email, required this.username});

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
    );
  }
}
