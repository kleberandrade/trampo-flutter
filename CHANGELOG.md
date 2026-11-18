# Changelog

## 2.0.0 — 2026-11-17

- Modernize to Flutter 3.50.0, Dart 3.14.0, standalone Material widgets and current stable FlutterFire/shared-preferences packages.
- Add a clearly labeled local synthetic workspace with browser persistence, validated JSON backup/restore, and recoverable loading/storage failure states.
- Complete client, service, BRL quote, schedule, lifecycle and historical-event flows. Prevent overlap, early starts, invalid discounts and deletion of historical client references.
- Introduce a responsive forest/lime identity, PT-BR/EN navigation, local circular flags, keyboard-accessible controls and enlarged-text accessibility checks.
- Separate modern Firebase account and owner-scoped repository APIs; provide emulator rules and a passing REST smoke test. Record the FlutterFire browser initialization timeout separately.
- Regenerate native/Web scaffold, preserve original app identifiers and artwork, add automated quality checks, current application captures, MIT license, architecture/contribution docs and a Portuguese lesson revision.

## 1.0.0 — Historical implementation

Original work by Kléber de Oliveira Andrade: Flutter sign-in, sign-up, password reset and service CRUD with Firebase/MobX. The historical manifest is retained in `docs/pubspec-legacy.yaml`; it is not supported by the active toolchain.
