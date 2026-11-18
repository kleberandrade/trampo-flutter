# Contributing to Trampo

Use Flutter 3.50.0 / Dart 3.14.0 and the committed lockfile. Install with `flutter pub get --enforce-lockfile`. Keep SDK updates explicit in `.fvmrc`, the workflow, manifests, README and lesson; do not force SDK-constrained transitive upgrades.

Start a change with a failing behavioral test when practical. Keep business rules in `lib/domain`, storage behind `WorkspaceRepository`, and interface concerns in `lib/ui`. Preserve integer cents and UTC serialization. Never add a fake authentication state to the local demonstration or silently initialize a production Firebase project.

Run format verification, `flutter analyze --fatal-infos`, `flutter test --coverage`, then `flutter build web --release` in sequence. Avoid simultaneous heavy Flutter builds/test suites on a shared machine. For Firebase changes, run the local emulator smoke test in `docs/FIREBASE.md`; record the actual result of the separate opt-in FlutterFire test. A skipped/blocked test is not success.

Inspect the running app on desktop and a narrow mobile viewport. Check keyboard focus, accessible names, touch targets, enlarged text, money input, save failures, empty results, language persistence and reload. Screenshots must come from the running implementation and include only synthetic data. Update documentation and changelog when behavior changes.

Keep PT-BR/EN UI strings together, preserve user-entered content across locale changes, and use locally drawn circular Brazil/UK flags. Do not add remote icon/font/flag dependencies without a concrete need.

Preserve Kléber de Oliveira Andrade's authorship, credits, MIT license and third-party notices. Do not commit credentials, Google service files, real clients, emulator exports, build output or coverage output. PR descriptions should explain behavior, verification and remaining platform limitations. Production deployment, stores, payment integration or legacy-data migration require a separately authorized scope.
