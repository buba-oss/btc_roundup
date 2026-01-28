import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<void> createUser(AppUser user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Stream<DocumentSnapshot> getUser(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> updateRoundUp(bool enabled, String uid) async {
    await _users.doc(uid).update({'roundUpEnabled': enabled});
  }

  Future<void> addSats(int sats, String uid) async {
    await _users.doc(uid).update({
      'totalSavedSats': FieldValue.increment(sats),
    });
  }
}
