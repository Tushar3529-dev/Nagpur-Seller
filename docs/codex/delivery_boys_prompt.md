# Codex task: Seller app — Delivery Boys (rider) management

You are working in a Flutter seller app (`package:hyper_local_seller`, flutter_bloc + go_router + dio + Hive + flutter_screenutil). Build a complete **Delivery Boys** feature that lets the seller manage their own riders: list, claim, create, edit, delete, approve/disapprove password login, and show/rotate a QR login credential.

**The API contract below is the single source of truth. Follow it exactly. Do not invent endpoints, fields, query params, defaults or behaviours that are not written here.** Where the contract says something about UI behaviour (badges, refresh timing, what approval does), implement it as written.

---

## 0. Ground rules

1. Copy the existing **System Users** module's style and structure exactly — read these first and mirror them:
   - `lib/screen/more_page/view/system_users/repo/system_users_repo.dart` (repo pattern, `ApiBaseHelper`)
   - `lib/screen/more_page/view/system_users/bloc/*` (bloc/event/state with Equatable)
   - `lib/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart` + `login_approvals_page.dart` (approve/disapprove UX, pagination on scroll, `canView`, `BlocConsumer` listener for messages)
   - `lib/screen/more_page/view/system_users/view/system_users_page.dart`, `widgets/system_user_card.dart`, `widgets/manage_system_user_bottom_sheet.dart`
   - `lib/screen/more_page/view/delivery_zone/*` (zone model + repo for the zone dropdown)
2. Reuse existing shared widgets/utilities — do not create new equivalents:
   `CustomScaffold`, `showCustomSnackbar`, `showAppAlertDialog`, `EmptyStateWidget`, `card_shimmers.dart`, `CustomLoadingIndicator`, `DemoGuard.shouldProceed(context)` (call before every write action), `PermissionChecker.hasPermission`, `JsonParser` (`lib/service/json_parser.dart`) for null-safe parsing, `AppColors`, `ImagesPath`, `context.screenType`, `platformPage(...)` in the router.
3. Errors: `ApiBaseHelper` throws `ApiException(message, statusCode, responseData)`. Show `message` to the user. Never surface raw exception strings.
4. All user-facing strings go through l10n: add keys to `lib/l10n/app_en.arb`, `app_hi.arb`, `app_ar.arb` (English text is fine in hi/ar if no translation) and use `l10n?.key ?? 'English fallback'` like the rest of the app. Regenerate with `flutter gen-l10n`.
5. **Security (from the contract):** the QR credential (`qr_token` / `qr_payload`) must never be logged, printed, stored in Hive, or put in debug output. Make sure the dio logger / `debugPrint` calls in new code do not print QR responses. Do not cache it anywhere beyond the in-memory cubit state of the open QR screen.
6. Do not touch unrelated files. Do not change existing URLs in `api_routes.dart` (only append).
7. Run `flutter analyze` at the end and fix every issue you introduced.

---

## 1. API contract (authoritative)

All endpoints require the seller's Sanctum token (already attached by `ApiBaseHelper`). Base: `ApiRoutes.baseUrl` = `.../api/seller`.

### Permissions
- `delivery_boy.view` → can list riders.
- `delivery_boy.manage` → can claim, create, edit, delete, approve/disapprove login, and get/rotate QR.
- `available_riders` is returned non-empty only for users with `delivery_boy.manage`.

### Rider object (same shape everywhere)
```json
{
  "id": 17,
  "user_id": 42,
  "name": "Rider Name",
  "email": "rider@example.com",
  "mobile": "9876543210",
  "delivery_zone_id": 3,
  "status": "inactive",                 // "active" | "inactive"
  "verification_status": "verified",    // e.g. "verified" | "pending" (treat any other value generically)
  "login_approval_status": "pending",   // "disapproved" | "pending" | "approved"
  "login_approval_requested_at": "2026-10-23T20:00:00.000000Z", // nullable
  "login_approved_until": null,          // nullable ISO-8601 UTC
  "qr_login_expires_at": "2026-10-24T08:00:00.000000Z"          // nullable (null until a QR is first requested)
}
```
Semantics (implement exactly):
- `status` is the **source of truth** for ACTIVE/INACTIVE. **Never infer it** from `login_approval_status` or `verification_status`. A rider can be verified + approved and still be `inactive` until they actually log in.
- A password-login grant is valid **only while `login_approved_until` is in the future**. If `login_approval_status == "approved"` but `login_approved_until` is past/null, display it as expired, not approved.
- Approval only grants permission to use email/password; it does **not** log the rider in and does **not** change `status`.

### 1.1 List riders
`GET /api/seller/delivery-boys?search=&per_page=15&available_page=1`
- `search`: matches name, email or mobile (optional, omit when empty)
- `per_page`: 1–100, default 15
- `available_page`: page of unassigned riders (default 1)
- Assigned riders paginate with the standard `page` param (Laravel paginator).

Response `200`:
```json
{
  "success": true,
  "message": "Riders retrieved.",
  "data": {
    "assigned_riders":  { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1, "data": [ <Rider> ] },
    "available_riders": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1, "data": [ <Rider> ] }
  }
}
```

### 1.2 Claim an existing platform rider
`POST /api/seller/delivery-boys/{rider_id}/claim` — no body.
- `200` → `data.rider` (Rider). Message: "Existing delivery boy added to your seller account."
- `409` with `data.code == "rider_already_assigned"` → another seller claimed it first. Show the server message, remove it from the available list and refresh.
- Claiming resets approval/QR and revokes the rider's tokens (server side). After success, refresh: it moves to assigned riders.

### 1.3 Create rider
`POST /api/seller/delivery-boys`
```json
{ "full_name": "Rider Name", "email": "rider@example.com", "mobile": "9876543210", "password": "temporary-password", "delivery_zone_id": 3 }
```
- Required: `full_name`, unique `email`, `password` (min 8), active `delivery_zone_id`. `mobile` optional (omit if empty).
- Zone selector is populated from the existing `GET /api/delivery-zone` (`ApiRoutes.deliveryZonesApi`, reuse `DeliveryZoneRepo` / `DeliveryZoneModel`).
- `201` → `data.rider`, message "Rider created. Platform verification is required before login." Show this message. New rider has `verification_status: "pending"`.

### 1.4 Update rider
`POST /api/seller/delivery-boys/{rider_id}`
```json
{ "full_name": "...", "email": "...", "mobile": "...", "delivery_zone_id": 3, "password": "optional-new-password" }
```
- Required: `full_name`, `email`, `delivery_zone_id`. `mobile` and `password` optional.
- **Omit `password` from the body when the field is empty** (empty/omitted = unchanged). Omit `mobile` when empty.
- Changing the password revokes all rider tokens and marks the rider inactive — show a helper text under the password field in edit mode saying so.
- `200` → `data.rider`.

### 1.5 Delete rider
`DELETE /api/seller/delivery-boys/{rider_id}` → `200`, `data: []`. Soft-deletes and revokes tokens. Confirm with a destructive `showAppAlertDialog` first.

### 1.6 Approve password login
`POST /api/seller/delivery-boys/{rider_id}/approve-login`
Optional body: `{ "duration_hours": 6 }`
- `duration_hours`: integer from 1 to the platform max `riderLoginDurationHours` (platform range 1–720). If omitted, server default is 12h (or the platform max if lower).
- Response `200`:
```json
{ "success": true, "message": "Rider password login approved.",
  "data": { "rider_id": 17, "login_approval_status": "approved", "login_approved_until": "2026-10-24T08:00:00.000000Z", "status": "inactive", "duration_hours": 6 } }
```
- The platform max is admin-configured and **not exposed to the seller by this contract**. Therefore: let the user pick a duration (default selection **12**), accept integers 1–720 client-side, and rely on the server's `422` message if the value exceeds the platform max. Also offer a "Use default" option that sends **no body** (server picks default).

### 1.7 Disapprove password login
`POST /api/seller/delivery-boys/{rider_id}/reject-login` — no body.
- `200` → `data: { rider_id, login_approval_status: "disapproved", login_approved_until: null, status: "inactive" }`.
- Revokes the current session regardless of login method. The QR credential itself remains valid until expiry or rotation — say this in the confirm dialog text.

### 1.8 Get QR credential
`GET /api/seller/delivery-boys/{rider_id}/login-qr` — no body.
```json
{ "success": true, "message": "Rider QR login credential retrieved.",
  "data": { "rider_id": 17, "qr_token": "opaque-64-char", "qr_payload": "opaque-64-char", "expires_at": "2026-10-24T08:00:00.000000Z" } }
```
- Render **`qr_payload`** (exact string, unmodified) as a QR code.
- Only for platform-verified riders; `422` if not verified → show message.
- An unexpired request returns the same credential; once expired, the next GET creates a new one (old QR stops working). So: **when `expires_at` passes, call GET again automatically** and redraw.

### 1.9 Rotate QR
`POST /api/seller/delivery-boys/{rider_id}/rotate-login-qr`
Body (**required**): `{ "duration_hours": 6 }` — integer 1..platform max (1–720).
- Same response shape as 1.8 with a new token/payload/expires_at.
- Invalidates the previous QR and any sessions authenticated with it; if that was the active session the rider becomes `inactive`.

### 1.10 Errors
- `422` validation → show message; on forms map `errors` to fields where possible (fallback: snackbar with `ApiException.message`).
- `404` missing seller context or rider out of scope → snackbar + refresh list.
- `403` insufficient permission → snackbar "You don't have permission…". (Note: `ApiBaseHelper` already logs out on the system-user login-approval 403; don't interfere with that.)
- `409 rider_already_assigned` → see 1.2.

### 1.11 Refresh rules (from the contract)
Refresh the rider list:
- when the page opens,
- when the user returns to the page (route pop back to it / app resumed via `WidgetsBindingObserver` while the page is visible),
- after approve, disapprove, claim, create, edit, delete, QR rotation,
- after a viewed QR expires (status badges may change),
- and periodically every **60 seconds** while the page is visible (backend reconciles expired sessions at least once per minute). Cancel the timer in `dispose` and when the app is paused. Periodic refresh must be silent (no shimmer, keep current list, keep scroll position, keep search).

---

## 2. Files to create

All under `lib/screen/more_page/view/delivery_boys/`:

```
model/delivery_boy_model.dart
repo/delivery_boy_repo.dart
bloc/delivery_boy_bloc.dart
bloc/delivery_boy_event.dart
bloc/delivery_boy_state.dart
qr/rider_qr_cubit.dart
view/delivery_boys_page.dart
view/rider_qr_page.dart
view/add_edit_rider_page.dart
widgets/rider_card.dart
widgets/available_rider_card.dart
widgets/rider_status_badge.dart
widgets/rider_actions_sheet.dart
widgets/login_duration_sheet.dart
```

### 2.1 `model/delivery_boy_model.dart`
- `enum RiderStatus { active, inactive }` (unknown → inactive).
- `enum RiderLoginApproval { disapproved, pending, approved }` (unknown → disapproved).
- `class DeliveryBoy extends Equatable` with every field in the Rider object; parse dates with `DateTime.tryParse(...)?.toLocal()`; parse ints/strings with `JsonParser`.
  - getters: `bool get isActive`, `bool get isVerified => verificationStatus == 'verified'`, `bool get isApprovalLive => loginApproval == approved && loginApprovedUntil != null && loginApprovedUntil!.isAfter(DateTime.now())`, `bool get isApprovalExpired => loginApproval == approved && !isApprovalLive`, `bool get isLoginPending => loginApproval == pending`.
  - `copyWith(...)` to apply approve/reject responses locally before the refresh lands.
- `class RiderPage` (current_page, last_page, per_page, total, `List<DeliveryBoy> data`) with `bool get hasMore => currentPage < lastPage`.
- `class DeliveryBoysListResponse` holding `assigned` and `available` `RiderPage`s.
- `class RiderQrCredential` (`riderId`, `qrPayload`, `expiresAt`). **Do not keep `qr_token` separately and do not override `toString` to include the payload.**

### 2.2 `repo/delivery_boy_repo.dart`
Class `DeliveryBoyRepo` using `ApiBaseHelper`, methods:
- `Future<DeliveryBoysListResponse> getRiders({int page = 1, int availablePage = 1, int perPage = 15, String? search})`
- `Future<DeliveryBoy> claimRider(int riderId)`
- `Future<DeliveryBoy> createRider({required String fullName, required String email, String? mobile, required String password, required int deliveryZoneId})`
- `Future<DeliveryBoy> updateRider(int riderId, {required String fullName, required String email, String? mobile, String? password, required int deliveryZoneId})` — omit empty `mobile`/`password`
- `Future<void> deleteRider(int riderId)`
- `Future<Map<String, dynamic>> approveLogin(int riderId, {int? durationHours})` — body `{}` when null, else `{'duration_hours': n}`
- `Future<Map<String, dynamic>> rejectLogin(int riderId)`
- `Future<RiderQrCredential> getLoginQr(int riderId)`
- `Future<RiderQrCredential> rotateLoginQr(int riderId, {required int durationHours})`

Return the response `message` too where the UI shows it (e.g. return a small result record `(DeliveryBoy rider, String message)` or expose message in the bloc via `response['message']`).

### 2.3 `api_routes.dart` (append only)
```dart
// delivery boys
static String deliveryBoysApi = '$baseUrl/delivery-boys';
static String deliveryBoyApi(int id) => '$deliveryBoysApi/$id';
static String claimDeliveryBoyApi(int id) => '$deliveryBoysApi/$id/claim';
static String approveDeliveryBoyLoginApi(int id) => '$deliveryBoysApi/$id/approve-login';
static String rejectDeliveryBoyLoginApi(int id) => '$deliveryBoysApi/$id/reject-login';
static String deliveryBoyLoginQrApi(int id) => '$deliveryBoysApi/$id/login-qr';
static String rotateDeliveryBoyLoginQrApi(int id) => '$deliveryBoysApi/$id/rotate-login-qr';
```

### 2.4 `app_permissions.dart`
```dart
// Delivery boys
static const String deliveryBoyView = "delivery_boy.view";
static const String deliveryBoyManage = "delivery_boy.manage";
```

### 2.5 Bloc — `DeliveryBoyBloc`
State (Equatable, `copyWith`):
- `status` (initial / loading / success / failure), `isRefreshing` (silent refresh),
- `assigned` list + `assignedPage`, `assignedHasMore`, `assignedTotal`, `isLoadingMoreAssigned`,
- `available` list + `availablePage`, `availableHasMore`, `availableTotal`, `isLoadingMoreAvailable`,
- `search`,
- `Set<int> busyRiderIds` (spinner on that card's buttons while an action runs),
- `String? errorMessage`, `String? actionMessage` (one-shot, cleared via `ClearMessages` event, same as `LoginApprovalsCubit`).

Events:
- `FetchRiders({bool silent = false})` — resets both lists to page 1; silent = no shimmer.
- `LoadMoreAssigned`, `LoadMoreAvailable` — next page of the respective list; use `page` for assigned and `available_page` for available, keep the other list unchanged (send its current page = 1 is fine; only merge the list being paginated).
- `SearchChanged(String query)` — debounce 400 ms (use `EventTransformer` / `bloc_concurrency` style restartable debounce; if `bloc_concurrency` is not a dependency, implement debounce with a `Timer` inside the page instead and dispatch `FetchRiders`).
- `ClaimRider(int id)`, `CreateRider(...)`, `UpdateRider(...)`, `DeleteRider(int id)`, `ApproveLogin(int id, int? durationHours)`, `RejectLogin(int id)`, `ClearMessages`.
- After every successful write: apply local change (copyWith / remove / insert) for instant UI, set `actionMessage` to the server `message`, then dispatch `FetchRiders(silent: true)`.
- On `ApiException` with `statusCode == 409` and `responseData['data']['code'] == 'rider_already_assigned'`: remove that rider from `available`, set `errorMessage` to server message, refresh silently.
- On `404`: set `errorMessage`, refresh silently.
- Static helpers like the approvals cubit: `static bool get canView => PermissionChecker.hasPermission(AppPermissions.deliveryBoyView);` and `canManage` for `deliveryBoyManage`.

Register `DeliveryBoyRepo` as a `RepositoryProvider` and `DeliveryBoyBloc` as a `BlocProvider` in `lib/main.dart` next to `DeliveryZoneRepo` / `DeliveryZoneBloc`. Also clear/reset it wherever `MasterApiService.clearAllApisData(context)` resets other blocs on logout (add a reset event or recreate state — follow how other blocs are cleared there).

### 2.6 QR cubit — `RiderQrCubit` (scoped to the QR page, created in the page via `BlocProvider`)
State: `loading`, `credential` (RiderQrCredential?), `remaining` (Duration), `isRotating`, `errorMessage`, `rotatedMessage`.
- `load()` → GET login-qr; start a 1-second `Timer.periodic` updating `remaining = expiresAt - now`.
- When `remaining <= 0`: stop timer, call `load()` again automatically (server issues a new credential), and notify the list to refresh (`DeliveryBoyBloc.add(FetchRiders(silent: true))` from the page listener).
- `rotate(int hours)` → POST rotate-login-qr; replace credential; restart timer; signal list refresh.
- If GET returns `422` (not verified) show the message in an empty/error state on the page with a back button.
- Cancel timer in `close()`.

---

## 3. UI (follow the approved mockups)

Use the app's existing design language (AppColors, CustomScaffold app bar with back + centered title, cards similar to `system_user_card.dart`, ScreenUtil sizing, light/dark theme support). Support tablet via `context.screenType` like the approvals page.

### 3.1 More page entry
`lib/screen/more_page/more_page.dart` → in the **Account & Users** section, after System Users and before Logout:
```dart
if (PermissionChecker.hasPermission(AppPermissions.deliveryBoyView))
  SettingsTileData(
    img: <existing suitable svg in ImagesPath, e.g. the delivery/zone icon>,
    title: l10n?.deliveryBoys ?? 'Delivery Boys',
    subtitle: l10n?.deliveryBoysSubtitle ?? 'Riders, login and QR',
    onTap: () => context.pushNamed(AppRoutes.deliveryBoys),
  ),
```
Pick an existing SVG from `ImagesPath`; do not add new assets.

### 3.2 Routes
In `lib/router/app_routes.dart` add constants and `GoRoute`s (use `platformPage`, name == path like existing ones):
- `deliveryBoys = '/delivery-boys'` → `DeliveryBoysPage`
- `addEditRider = '/delivery-boys/manage'` → `AddEditRiderPage(rider: state.extra as DeliveryBoy?)` (null = create)
- `riderLoginQr = '/delivery-boys/qr'` → `RiderQrPage(rider: state.extra as DeliveryBoy)`

### 3.3 `DeliveryBoysPage` (mockup 2)
- If `!canView` → `EmptyStateWidget` "You don't have permission to view delivery boys" (same as approvals page).
- App bar title "Delivery Boys"; trailing **+** icon only if `canManage` → push add page; on return with `true` → silent refresh.
- Search field (name, email or mobile) → debounced `SearchChanged`.
- Two tabs (TabBar or segmented toggle): **My riders (assignedTotal)** and **Available (availableTotal)**. Hide the Available tab entirely when `!canManage`.
- Each tab: `RefreshIndicator` → `FetchRiders`; infinite scroll at 90% → `LoadMoreAssigned` / `LoadMoreAvailable`; shimmer on first load; `EmptyStateWidget` when empty (different copy for "no riders yet" vs "no search results"); error state with retry.
- Lifecycle: `WidgetsBindingObserver` → on resume refresh silently and restart the 60 s timer; on pause cancel timer. Use `RouteAware` or refresh after `await context.push(...)` returns to cover "user returns to the page".
- `BlocConsumer` listener shows `actionMessage` (success snackbar) / `errorMessage` (error snackbar), then `ClearMessages`.

### 3.4 `RiderCard` (assigned)
- Name (bold), email · mobile, zone name if resolvable from the zones list (else omit).
- Top-right `RiderStatusBadge`: `active` → green **ACTIVE**; `inactive` → neutral grey **INACTIVE**. Driven ONLY by `rider.status`.
- Chips row:
  - Verification: `verified` → "Verified"; anything else → "Verification pending" (warning colour) + small caption "Platform admin must verify before login".
  - Login approval:
    - `isApprovalLive` → "Login approved until {local time, e.g. 25 Oct, 8:00 PM}" (success colour)
    - `isApprovalExpired` → "Approval expired" (neutral)
    - `pending` → "Login requested {relative time from login_approval_requested_at}" (warning)
    - `disapproved` → "Login not approved" (neutral)
- If `canManage` and `isLoginPending`: inline **Approve** (primary) and **Disapprove** (danger outline) buttons on the card, showing a spinner when `busyRiderIds.contains(id)`.
- Tap card (if `canManage`) → `RiderActionsSheet`.

### 3.5 `AvailableRiderCard`
Name, email · mobile, `RiderStatusBadge`, verification chip, and an **Add to my team** button → confirm dialog ("This rider will be added to your team. Their login approval and QR will be reset and they'll be logged out.") → `ClaimRider`.

### 3.6 `RiderActionsSheet` (mockup 3, modal bottom sheet)
Header: name, zone, current approval text. Actions:
1. **Approve password login** → opens `LoginDurationSheet` (mode: approve) → `ApproveLogin`. Label "Extend approval" when `isApprovalLive`.
2. **Disapprove / end session** → destructive confirm: "This disapproves password login and ends the rider's current session. The QR stays valid until it expires or you regenerate it." → `RejectLogin`. Hide when already `disapproved` and `!isActive`.
3. **Show login QR** → push `RiderQrPage`. Disabled (with caption "Available after platform verification") when `!isVerified`.
4. **Edit rider** → push `AddEditRiderPage(rider)`.
5. **Delete rider** → destructive confirm → `DeleteRider`.

### 3.7 `LoginDurationSheet` (mockup 4) — reused for approve and rotate
- Preset chips: 1h, 4h, 6h, **12h (default selected)**, 24h, plus **Custom** → numeric `TextField` (digits only).
- Validation: integer 1–720, inline error text otherwise. Caption: "Maximum duration is set by the platform."
- Approve mode only: extra option "Use platform default" that sends no `duration_hours`.
- Preview line: "Rider can log in with email and password until {now + hours, local}. Approval alone doesn't log them in." (approve mode) / "New QR valid until {now + hours}. The old QR and its session stop working." (rotate mode).
- Returns the chosen `int?` via `Navigator.pop`.

### 3.8 `RiderQrPage` (mockup 5)
- App bar "Login QR · {name}".
- Centered QR of `credential.qrPayload` using the **`qr_flutter`** package (add `qr_flutter: ^4.1.0` to `pubspec.yaml`, run `flutter pub get`). White background behind the QR in dark mode so it scans. Size ~ 240.w.
- Countdown chip "Expires in HH:MM:SS" + absolute local expiry time below.
- Caption: "The rider scans this in the rider app to log in. Don't share it."
- **Regenerate QR** button → `LoginDurationSheet` (rotate mode, duration required) → `rotate(hours)`, then success snackbar with the server message.
- Auto-reload at expiry (see 2.6) with a brief loading overlay.
- On pop, trigger a silent list refresh.

### 3.9 `AddEditRiderPage` (mockup 6)
- Title "Add Delivery Boy" / "Edit Delivery Boy". Use a `Form` with validators:
  - Full name: required.
  - Email: required, valid email format.
  - Mobile: optional, digits only (reuse the app's phone field style if one is used in `manage_system_user_bottom_sheet.dart`; otherwise a plain numeric field).
  - Password: create → required, min 8; edit → optional, if non-empty min 8, helper "Leave empty to keep current password. Changing it logs the rider out."
  - Delivery zone: required dropdown from `DeliveryZoneBloc`/`DeliveryZoneRepo` (fetch if not loaded; show only active zones if the model exposes an active flag).
- Create mode: info banner (warning tint) "After creation, the platform admin must verify the rider before they can log in."
- Submit → `CreateRider` / `UpdateRider`; button shows loader; on success show server message and `context.pop(true)`; on 422 show field errors from `responseData['errors']` under the matching fields (`full_name`, `email`, `mobile`, `password`, `delivery_zone_id`), fallback snackbar.
- Prefill all fields from `rider` in edit mode (password empty).

---

## 4. Date/time formatting
- Parse all API timestamps as UTC (`DateTime.parse(...)`) and display with `.toLocal()` using `intl` `DateFormat('d MMM, h:mm a')`.
- Relative time for `login_approval_requested_at`: "just now", "5m ago", "2h ago", "3d ago".
- Countdown: `HH:MM:SS`, clamp at zero.

---

## 5. Acceptance checklist
- [ ] More → Delivery Boys tile visible only with `delivery_boy.view`.
- [ ] List shows assigned riders with ACTIVE (green) / INACTIVE (grey) badge driven only by `status`.
- [ ] Available tab (only with `delivery_boy.manage`) lists unassigned riders with **Add to my team**; 409 `rider_already_assigned` handled.
- [ ] Search by name/email/mobile works (debounced); pagination works for both lists independently (`page` / `available_page`).
- [ ] Approve with 1–720h or platform default; approval does not flip status to active; chip shows "approved until …" only while it's in the future.
- [ ] Disapprove confirms, then sets disapproved + inactive.
- [ ] QR page renders `qr_payload`, counts down, auto-fetches a new credential at expiry, Regenerate requires a duration and replaces the QR; disabled for unverified riders; 422 handled.
- [ ] Create / edit / delete work with the exact request bodies above; empty password and mobile are omitted on update.
- [ ] List refreshes on open, on return, after each action, after QR expiry/rotation, and silently every 60 s while visible (timer stops when paused/disposed).
- [ ] Write actions are gated by `delivery_boy.manage` and `DemoGuard.shouldProceed`.
- [ ] No QR token/payload in logs, Hive, or `toString`.
- [ ] All strings in the three `.arb` files; `flutter gen-l10n` run.
- [ ] `flutter analyze` clean for new/changed files.

Do not add features beyond this document (no screenshot blocking, no extra endpoints, no fetching the platform max duration from anywhere).
