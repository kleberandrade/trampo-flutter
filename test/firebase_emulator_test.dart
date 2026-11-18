import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trampo/data/demo.dart';
import 'package:trampo/data/firebase_repository.dart';

// Opt-in browser integration: never points at a real Firebase project.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'emulators: auth, persistence, revision conflicts, owner isolation and sign-out',
    () async {
      final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:123456:web:trampo',
          messagingSenderId: '123456',
          projectId: 'demo-trampo',
        ),
      ).timeout(const Duration(seconds: 20));
      final auth = FirebaseAuth.instanceFor(app: app);
      final db = FirebaseFirestore.instanceFor(app: app);
      await auth.useAuthEmulator('127.0.0.1', 9198);
      db.useFirestoreEmulator('127.0.0.1', 8188);
      db.settings = const Settings(persistenceEnabled: false);
      final accounts = FirebaseAccounts(auth);
      final email =
          'test-${DateTime.now().microsecondsSinceEpoch}@example.invalid';
      const password = 'synthetic-password-123';
      await accounts
          .register(email, password)
          .timeout(const Duration(seconds: 20));
      final owner = auth.currentUser!.uid;
      final repo = FirebaseWorkspaceRepository(firestore: db, auth: auth);
      expect(await repo.load(), isNull);
      final original = demoWorkspace(DateTime.now());
      await repo.save(original);
      final second = FirebaseWorkspaceRepository(firestore: db, auth: auth);
      expect((await second.load())!.toJson(), original.toJson());
      await repo.save(original.copy(language: 'en'));
      await expectLater(second.save(original), throwsStateError);
      await accounts.signOut();
      await expectLater(repo.load(), throwsStateError);
      await expectLater(
        db
            .doc('users/$owner/workspace/current')
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await accounts.register('other-$email', password);
      await expectLater(
        db
            .doc('users/$owner/workspace/current')
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await accounts.signOut();
      await accounts.signIn(email, password);
      expect((await repo.load())!.language, 'en');
      await expectLater(
        db.doc('users/$owner/workspace/current').set({
          'revision': 99,
          'payload': original.toJson(),
        }),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await accounts.signOut();
      await db.terminate();
      await app.delete();
    },
    skip: !const bool.fromEnvironment('RUN_FIREBASE_EMULATOR'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
