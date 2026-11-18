# Architecture and decisions

## Scope and glossary

A **client** is a person/business receiving a service. A **quote** records scope and a BRL budget. A **job** is that service throughout its lifecycle. A **reservation** is the time interval held by a scheduled or active job. An **event** records an immutable snapshot of title, total, client identity and status at an instant. A **workspace** owns all clients and jobs for one professional.

The original project implemented email/password accounts and CRUD against a global Firebase jobs collection. It used Dart 2.7, non-null-safe models, MobX generated stores and obsolete FlutterFire APIs. This revision extends the original service-management purpose, replacing the obsolete state/UI path without adding hiring, marketplace or payments.

## Boundaries

Widgets call the store, which transforms an immutable workspace, saves it through a repository, then notifies listeners. Widgets never directly edit Firestore or browser storage. Pure domain constructors/methods reject invalid input. JSON parsing revalidates money, identity references, reservation overlap and history consistency at the repository/restore boundary. No forced casts suppress compiler errors; malformed JSON fails rather than silently clearing data.

The local store rejects simultaneous writes within one instance, and retains the prior workspace if persistence throws. A successful save means the platform preference write returned successfully; preferences cannot guarantee durable storage after power loss. Multiple tabs are explicitly unsupported. No service worker or production database behavior is implied by browser persistence.

## Identity and history

Client and job IDs are generated from microsecond timestamps within the single-writer demonstration. Current or historical client references prevent client deletion. Reassigning a service retains earlier client IDs in past events. Client profile edits update the current profile shown for that identity; historical names/phones are not versioned. This is an application history, not a legal or cryptographic ledger.

Schema v1 accepts early v1 event records without `clientId` by assigning their containing job's client ID. Newly saved events always include it. Existing obsolete Firebase documents are never imported automatically. There is no global schema migration side effect at startup.

## Money and time

Money arithmetic stays in integer cents; parsing is strict Brazilian notation regardless of UI locale. Labor/materials/discount and totals are bounded below JavaScript integer precision limits. There is no percentage rounding, currency conversion, tax or payment state.

Dates use instants in storage and device-local presentation. Scheduling uses half-open intervals, rejects past starts and durations over 24 hours, and excludes the current job when rescheduling. Completed/cancelled services release reservations. Active work retains its planned interval; overtime does not automatically extend it, and no background process updates status.

## Optional Firebase

The adapter requires an authenticated owner and an explicit initial load. The document is `users/{uid}/workspace/current` with `{revision, payload}`. Server reads and transactions detect other writers; a stale writer must reload and reconcile rather than silently overwrite. Account changes invalidate the loaded owner. A 750,000-byte JSON cap leaves headroom below the Firestore document limit; this snapshot strategy is for small workspaces and should be replaced with per-entity storage for scale.

Rules enforce owner-only access, basic envelope shape and monotonic revisions. Full business invariants remain in Dart. A modified owner client can write an internally invalid payload; this is not a production authorization/business-validation service. There is no local-to-cloud automatic sync, migration or UI account flow in this demo.

## Dependency and platform choices

Flutter 3.50.0/Dart 3.14.0 and `material_ui` replace deprecated bundled Material APIs. `ChangeNotifier` replaces obsolete code generation because the application has one small workspace and no need for generated global stores. Shared preferences provide the smallest portable local demonstration. Firebase SDKs remain current for the explicit integration boundary; unused Storage/HTTP/theme/service-locator/masking/codegen dependencies were removed.

Android/iOS bootstrap files were regenerated from this Flutter release, preserving identifiers, authorship and original artwork. Native platforms remain unverified, and no SDK license acceptance, shared Flutter modification, store publication or backend deployment occurred.
