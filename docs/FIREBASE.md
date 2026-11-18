# Optional Firebase integration

The default `main.dart` only creates `LocalRepository`. It does not initialize Firebase, create an account, send a reset email, access legacy collections or synchronize local data. The local demonstration is always visibly labeled. `FirebaseAccounts` preserves current email/password registration, sign-in, current-user, reset and sign-out APIs; account UI is intentionally outside this local demonstration.

## Reproduce the verified emulator checks

Use Node **24**, Java **21 or newer** and Python 3. The tested CLI is `firebase-tools 15.36.0`. The sample project ID is deliberately `demo-trampo`; emulator endpoints bind only to loopback on project-specific ports to avoid other projects' default emulators.

```sh
npx --yes firebase-tools@15.36.0 emulators:exec \
  --only auth,firestore --project demo-trampo --config firebase.json \
  "python3 tool/emulator_smoke.py"
```

The smoke script has fixed localhost URLs and creates disposable accounts under `example.invalid`. It checks real Auth emulator sign-up and password sign-in, rejects an incorrect password, writes/reads a synthetic owner snapshot, and verifies unauthenticated/other-owner denials, revision increments, stale-write rejection and blocked deletion. It does not send emails or interact with a real Firebase project. The emulator process is stopped by `emulators:exec`; it does not save an export.

## Flutter adapter browser test

With the same emulators running:

```sh
flutter test --platform chrome \
  --dart-define=RUN_FIREBASE_EMULATOR=true \
  test/firebase_emulator_test.dart
```

This opt-in test compiles the current FlutterFire APIs and attempts the actual Dart repository against the emulators. On the modernization machine, **Firebase Web initialization did not finish within 20 seconds**, before any emulator account operation. Two attempts were made, the second with an explicit initialization timeout. The exact cause was not established; HTTP access to the official Firebase app-module URL worked independently. Do not report this as a passing FlutterFire end-to-end test. The separate REST smoke test passed, proving Auth and security-rule behavior but not the Dart transaction implementation at runtime. The normal `flutter test` suite skips this test unless explicitly enabled.

## Repository contract and rules

Construct `FirebaseWorkspaceRepository(firestore: db, auth: auth)` after explicitly configuring your own app. An initial server `load()` is mandatory; `save()` uses a Firestore transaction and expected revision. The document path is `users/{uid}/workspace/current`. Every operation requires a signed-in user; changing the user requires another load. Concurrent writers cause `concurrent-update`, not automatic last-writer-wins overwrite. This integration boundary needs a real account UI, a conflict-resolution UI and a complete Web/native integration run before a production rollout.

The rules in `firebase/firestore.rules` permit only an owner's snapshot read/create/update with an incrementing revision and basic envelope validation. They deny deletes and all other paths. Business rules are validated in Dart; these rules do not fully validate arbitrary nested jobs/history against a malicious owner. Snapshot JSON is capped at 750,000 encoded bytes in the adapter. This design is suitable for a small educational workspace, not large-team synchronization.

There is no implicit migration from the historical global `jobs` collection. The old model's numeric `price` cannot safely be assumed to represent integer cents. A real migration must explicitly map ownership, create clients, convert prices with a documented rounding policy, preserve source records and review results against synthetic fixtures first.

## Before any authorized real-service use

Use your own Firebase project and official [FlutterFire setup](https://firebase.google.com/docs/flutter/setup), then supply generated options/configuration outside version control. Keep the explicit local/Firebase mode label accurate, require real authentication, and handle account changes and conflicts. Configure emulator host overrides separately from real service endpoints. Android uses `10.0.2.2` to reach host emulators from an Android emulator; physical devices cannot use host loopback. No native target or physical device was tested here.

No credentials or Firebase configuration are supplied, no production rules/backend were deployed, and no real accounts or clients were accessed. Do not run deployment commands as part of the demo setup.
