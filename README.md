# Visitor Management App

A Flutter app for front-desk and security staff to register visitors, generate and scan QR codes.

## Features

- **Dashboard**: Total Visitors Today, Currently Checked In, Checked Out Today (calculated from the visitor data using the device's local date) plus shortcuts to Register Visitor, Visitor List and Scan QR Code.
- **Register / Edit visitor**: name, mobile (exactly 10 digits), optional email (validated when entered), visitor type, project, purpose. New visitors start as `Registered`.
- **Visitor list**: scrollable cards, search by name or mobile, open details, edit, delete with confirmation.
- **Visitor details**: profile card, status chip, QR code (contains the visitor ID), check-in / check-out buttons and timestamps.
- **QR scanner**: camera scan, invalid-QR and unknown-visitor errors, duplicate-scan protection, camera-permission message, then opens the visitor details.
- **Check-in / check-out**: `Registered → Checked In → Checked Out`. No check-out before check-in, no double check-in, no check-in after a completed visit.
- **UI states**: loading, empty list, network failure (with Retry), validation errors, SnackBar messages.

## Technologies and concepts

| Area | What is used |
| --- | --- |
| Framework | Flutter + Dart, Material 3 |
| State management | **Riverpod** (`flutter_riverpod`): `StateNotifierProvider`, `Provider`, `StateProvider`, `FutureProvider.family` |
| Networking | **`http`** package with JSON serialization and error mapping |
| QR | `qr_flutter` (generate) and `mobile_scanner` (scan) |
| Architecture | `models` → `services` → `providers` → `screens` / `widgets` |
| Responsiveness | Scrollable screens, `SafeArea`, `LayoutBuilder`, max-width content box |

## Project structure
lib/
├── main.dart
├── core/ constants, theme, date helpers, AppException
├── models/ visitor.dart (Visitor, VisitorStatus)
├── services/ visitor_api_service.dart (http)
├── providers/ visitor_providers.dart (Riverpod state and status rules)
├── screens/ main_shell, dashboard, visitor_list, visitor_form, visitor_details, scanner
└── widgets/ reusable UI widgets


## Current backend (demo)

The demo app talks to **crudcrud.com** — a free disposable REST endpoint for prototyping. It provides `GET /visitors`, `GET /visitors/{id}`, `POST /visitors`, `PUT /visitors/{id}` and `DELETE /visitors/{id}`.

> crudcrud tokens expire after ~24 hours. When the token expires, generate a fresh one at <https://crudcrud.com/> and update `VisitorApiService._baseUrl`.

The base URL used by the service is `https://crudcrud.com/api/<TOKEN>/visitors`, and single-resource calls append `/{id}`.

### Resent changes (this iteration)

- **API wired end-to-end** — `VisitorApiService` now implements `fetchVisitors`, `fetchVisitorById`, `createVisitor`, `updateVisitor` and `deleteVisitor` against crudcrud. `VisitorRegisterScreen._save()` POSTs on register and PUTs on edit.
- **`Visitor.fromJson` reads crudcrud's `_id`** (falling back to `id`). This fixes the 404s right after register — every visitor loaded from the list now carries the real server id.
- **`Visitor.copyWith` accepts every field** — so check-in / check-out (and future edits) can copy without losing data.
- **`visitor_providers.dart` consolidated** — a single file now declares:
  - `visitorServiceProvider` (exposes `VisitorApiService`)
  - `searchQueryProvider`
  - `visitorsProvider` + `VisitorsNotifier` (`refresh`, `addVisitor`, `updateVisitor`, `deleteVisitor`, `checkIn`, `checkOut`, `upsert`)
  - `filteredVisitorsProvider`
  - `visitorByIdProvider` (`FutureProvider.autoDispose.family`)
  - `dashboardStatsProvider` → `DashboardStats` (totalToday / checkedIn / checkedOutToday)
- **`VisitorDetailsScreen`** fetches the visitor by id via `visitorByIdProvider(id)` and renders `initialVisitor` immediately while the network call is in flight. Re-fetches after check-in / check-out so the status chip and timestamps update without a manual reload.
- **`VisitorListScreen`** calls `refresh()` in `initState` (via `addPostFrameCallback`) so the list always reflects the server. Passes `initialVisitor` to details for instant render. Delete dialog now shows the visitor name.
- **`DashboardScreen`** imports the correct provider file (removed the stale `visitor_providerscopy.dart` reference), reads counts from `dashboardStatsProvider`, and has a Refresh action in the app bar.
- **`ScannerScreen`** fixed — calls `fetchVisitorById(id)` (was `getVisitor`) and uses `visitorsProvider.notifier.upsert(visitor)` to sync the local cache before opening details.
- **`VisitorsNotifier.valueOrNull` → `state.value ?? const []`** — compatible with both Riverpod 1.x and 2.x.
- **Removed the stray `visitor_providerscopy.dart`** so nothing accidentally imports the old file.
- **Deleted the hard-coded `_id` mismatch** — `Visitor.id` is now the crudcrud `_id` everywhere; delete / update / details all target the correct resource.

## Connecting a real API

The API needs a `visitors` resource with `GET /visitors`, `GET /visitors/{id}`, `POST /visitors`, `PUT /visitors/{id}` and `DELETE /visitors/{id}`, storing the fields: `name`, `mobile`, `email`, `visitor_type`, `project`, `purpose`, `status`, `created_at`, `check_in_time`, `check_out_time`, with a server-generated `id`.

**The base URL must stop at the API root** (for example "https://crudcrud.com/api//visitors). The app appends `/visitors` itself.

Pass it when running:

```bash
flutter run --dart-define=API_BASE_URL=https://crudcrud.com/api/visitors