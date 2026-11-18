# Validation record

Work date: **2026-11-17, America/Sao_Paulo**. Tests ran locally on macOS using a project-isolated Flutter SDK. Some host logs use UTC on 2026-11-18; user-facing dates use the work timezone.

## Toolchain and dependency audit

Flutter **3.50.0**, framework `ab2912035e160d9cad6306df307576da6128ebdb`, Dart **3.14.0**. The copied SDK reports a local `[user-branch]` checkout; its release/revision match the installed 3.50.0 distribution. No shared Flutter SDK was changed. The [official release notes](https://flutter.dev/blog/whats-new-in-flutter-3-50) and [Material migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui) were consulted.

The pub.dev package API and `flutter pub outdated` were checked against the actual lockfile. All direct/dev packages resolve to the current stable catalog versions. Two SDK-constrained transitives remain: `material_color_utilities 0.13.0` (catalog 0.13.1) and `test_api 0.7.14` (catalog 0.7.15). No overrides were added.

## Passing checks

- Dart formatting and `flutter analyze`: no issues after migration to standalone Material widgets/localizations and removal of obsolete/generated stores.
- `flutter test --coverage`: **18 tests passed**, **one optional Firebase browser test skipped**. Covers exact cents/discounts; adjacent and conflicting reservations; terminal status/date guards; invalid backup totals/transitions/references; storage recreation/corruption/write failure; historical client identity; desktop quote/conflict/schedule/locale flow; mobile client creation/navigation/recovery; accessible labels, Android tap targets and text contrast with 150% text; navigation in short desktop/mobile windows; invalid-backup rejection and confirmed valid restore; rejection of restored work starting before its reservation.
- `flutter build web --release`: passed. Flutter's Wasm dry-run also succeeded; **a Wasm runtime build was not exercised**.
- Auth/Firestore emulator REST smoke: passed against **demo-trampo**, loopback Auth 9198 / Firestore 8188, CLI **15.36.0**, Java from the installed Android Studio runtime and isolated Node 24. Account credentials and data were synthetic. Checks include persistence, cross-user/unauthenticated rejection, revision sequencing, stale writes, denied deletion and invalid-password rejection.

## Actual browser inspection

The release Web build was served at `http://127.0.0.1:8768`, inspected at desktop **1280 × 720** and mobile viewport **390 × 844**. Captures under `docs/screenshots` are actual browser screenshots, not generated application mockups.

Verified overview, local-mode labeling, navigation, PT-BR/EN switching, preserved synthetic service values, mobile client creation and persistence after a page reload. The synthetic client `Cliente de demonstração` and phone `(11) 90000-0199` remained visible in the client list after reloading. No real contact was entered or contacted. The final desktop and mobile captures therefore show four clients; first launch starts with three.

## Blocked or unverified

- The opt-in FlutterFire Chrome test compiled but timed out at `Firebase.initializeApp`, before reaching Auth/Firestore. HTTP access to the SDK app-module URL returned 200 independently, so the underlying browser initialization cause is unresolved. REST emulator success does not prove Dart adapter transactions at runtime.
- Android/iOS scaffold updated, **native compilation/signing/simulator/physical-device testing not performed**. Mobile screenshots are browser viewports. Minimum configured API/iOS levels are 23 / 15.0.
- No offline cold start, PWA installation, multi-tab safety, real Firebase deployment, email delivery, store publication or real-data migration was tested or claimed.
- No linked Medium lesson URL was found in current/historical README or repository source; no Medium editorial connector was available. A concrete Portuguese revision is provided in `lesson-pt-br.md`, with a new conceptual cover, real app images, aligned examples, references and exactly five final exercises. It has **not** been published or substituted for an unidentified existing article.
- CRAP/dryer/mutation-specific tools described by the requested development practice are not installed or exposed in this session. Behavioral tests and static analysis were used; no mutation score or tool-based complexity result is claimed.

## Publication authorization

Repository modernization, commits and repository metadata updates are within this task. A Git push publishes source changes, not an app/backend deployment. No hosted app deployment is authorized by inference from unrelated engine projects. The Web output is ready for a separately authorized hosting step. Final commit/push and metadata outcomes are recorded in the handoff, without inventing CI success before GitHub runs it.

## Repository metadata

The GitHub description was updated and read back successfully. Nine topics were set and verified: dart, firebase, flutter, client-management, local-first, material-design, quotes, scheduling, service-management. No homepage or hosting deployment was created.
