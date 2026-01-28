class AppUser {
  final String uid;
  final String email;
  final bool roundUpEnabled;
  final int totalSavedSats;

  AppUser({
    required this.uid,
    required this.email,
    this.roundUpEnabled = true,
    this.totalSavedSats = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'roundUpEnabled': roundUpEnabled,
      'totalSavedSats': totalSavedSats,
      'createdAt': DateTime.now(),
    };
  }
}
