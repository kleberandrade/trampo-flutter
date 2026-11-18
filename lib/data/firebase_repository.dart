import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/workspace.dart';
import 'repository.dart';

/// Optional real-service boundary, never initialized by the local demo.
/// Each signed-in owner has a single snapshot with optimistic concurrency.
class FirebaseWorkspaceRepository implements WorkspaceRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  int? _revision;
  String? _loadedUid;
  FirebaseWorkspaceRepository({required this.firestore, required this.auth});
  String get _uid {
    final user = auth.currentUser;
    if (user == null) throw StateError('authentication-required');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      firestore.doc('users/$uid/workspace/current');
  @override
  Future<Workspace?> load() async {
    final uid = _uid;
    final snapshot = await _document(uid)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    final workspace = data == null
        ? null
        : Workspace.fromJson(data['payload'] as Map<String, dynamic>);
    if (uid != _uid) throw StateError('authentication-changed');
    _revision = data?['revision'] as int? ?? 0;
    _loadedUid = uid;
    return workspace;
  }

  @override
  Future<void> save(Workspace workspace) async {
    final uid = _uid;
    if (_loadedUid != uid || _revision == null) {
      throw StateError('load-required');
    }
    final payload = workspace.toJson();
    if (utf8.encode(jsonEncode(payload)).length > 750000) {
      throw StateError('snapshot-too-large');
    }
    final expected = _revision!;
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_document(uid));
      final actual = snapshot.data()?['revision'] as int? ?? 0;
      if (actual != expected) throw StateError('concurrent-update');
      if (uid != _uid) throw StateError('authentication-changed');
      transaction.set(_document(uid), {
        'revision': expected + 1,
        'payload': payload,
      });
    });
    _revision = expected + 1;
  }
}

/// Current Firebase email/password API. No synthetic user or implicit sign-in.
class FirebaseAccounts {
  final FirebaseAuth auth;
  FirebaseAccounts(this.auth);
  User? get currentUser => auth.currentUser;
  Future<UserCredential> signIn(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<UserCredential> register(String email, String password) => auth
      .createUserWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> sendPasswordReset(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  Future<void> signOut() => auth.signOut();
}
