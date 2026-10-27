# Codex task: Seller app — System User Status and Login Approval

You are working in a Flutter seller app (`package:hyper_local_seller`, flutter_bloc + go_router + dio + Hive + flutter_screenutil). Extend the existing **System Users** feature so the seller admin can see each system user's **activity status** (`active` / `inactive`) and **login approval status** (`not_requested` / `pending` / `approved` / `disapproved`), see when an approval expires, approve a login **with a chosen duration**, view a user's details, and revoke (disapprove) access.

**The API contract in section 2 is the single source of truth. Follow it exactly. Do not invent endpoints, fields, query params, defaults or behaviours that are not written there.** Where the contract says something about UI behaviour (badges, refresh timing, what approval does), implement it as written.

Much of this flow already exists. Your job is to **extend and fix** it, not rebuild it. Read section 1 before writing any code.

---

## 0. Ground rules

1. Read these files first and keep their style, structure and naming:
   - `lib/screen/more_page/view/system_users/model/system_users_model.dart`
   - `lib/screen/more_page/view/system_users/model/login_approval_model.dart`
   - `lib/screen/more_page/view/system_users/repo/system_users_repo.dart`
   - `lib/screen/more_page/view/system_users/bloc/system_user_bloc.dart`, `system_user_event.dart`, `system_user_state.dart`
   - `lib/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart`, `login_approvals_page.dart`
   - `lib/screen/more_page/view/system_users/view/system_users_page.dart` (includes `_PendingLoginApprovalsBanner`)
   - `lib/screen/more_page/view/system_users/widgets/system_user_card.dart`, `manage_system_user_bottom_sheet.dart`
   - `lib/widgets/custom/custom_card.dart` (`CardType.systemUser` renders `SystemUserCard` from a `Map<String, dynamic>`)
   - `lib/screen/auth/repo/auth_repo.dart`, `lib/screen/auth/view/login_page.dart`, `lib/screen/auth/widgets/login_approval_pending_view.dart`, `lib/screen/auth/bloc/auth/*`
   - `lib/service/session_manager.dart`, `lib/service/api_base_helper.dart`, `lib/service/notification_service.dart`, `lib/service/master_api_service.dart`
   - `lib/screen/order_page/incoming_orders/view/incoming_orders_controller.dart` (existing `WidgetsBindingObserver` / `didChangeAppLifecycleState` pattern)
2. Reuse the existing shared widgets and utilities. Do not create new equivalents of: `CustomScaffold`, `showCustomSnackbar`, `showAppAlertDialog` (or the `AlertDialog` pattern already used in `login_approvals_page.dart`), `EmptyStateWidget`, `CardShimmer`, `CustomLoadingIndicator`, `DemoGuard.shouldProceed(context)` (call it before every write action), `PermissionChecker.hasPermission`, `JsonParser` (`lib/service/json_parser.dart`), `AppColors`, `ImagesPath`, `UIUtils`, `context.screenType`.
3. Errors: `ApiBaseHelper` throws `ApiException(message, statusCode, responseData)`. Show `message` to the user. Never show raw exception strings like `Exception: ...`. Where existing code does `catch (e) { ... e.toString() }`, use the `ApiException.message` for new code paths you add.
4. All new user-facing strings go through l10n: add keys to `lib/l10n/app_en.arb`, `app_hi.arb` and `app_ar.arb` (English text is fine in hi/ar if you have no translation). Use them as `l10n?.key ?? 'English fallback'`, like the rest of the app. Regenerate with `flutter gen-l10n`.
5. **Security (from the contract):** never log, print or `debugPrint` access tokens or passwords. Never store the system user's password to poll for approval.
6. Do not touch unrelated files. In `lib/config/api_routes.dart`, do not change existing URLs; append only if something is missing (the needed routes already exist: `systemUsersApi`, `loginApprovalsApi`, `approveLoginApi(id)`, `rejectLoginApi(id)`, `loginApi`, `logoutApi`).
7. Do not touch the in-progress Delivery Boys work (`lib/screen/more_page/view/delivery_boys/`, its routes and permissions).
8. Permissions: viewing statuses, the detail sheet and the approvals inbox needs `AppPermissions.systemUserView`. Approve, extend and revoke need `AppPermissions.systemUserEdit` (same rule as the existing `LoginApprovalsCubit.canView` / `canManage`). Hide or disable write actions when the permission is missing, and show the existing "You don't have permission…" warning snackbar if one is tapped anyway.
9. Run `flutter analyze` at the end and fix every issue you introduced.

---

## 1. What already exists (keep it working)

| Piece | Where | Status |
| --- | --- | --- |
| Routes for list, approvals, approve, reject, login, logout | `lib/config/api_routes.dart` | Done |
| Pending approvals inbox, approve/disapprove, pagination | `login_approvals_cubit.dart`, `login_approvals_page.dart`, route `AppRoutes.loginApprovals` | Done; approve has **no duration** and its toast says "24 hours" (wrong) |
| "N login requests awaiting approval" banner | `_PendingLoginApprovalsBanner` in `system_users_page.dart` | Done |
| Staff pending-approval screen on 403 pending | `auth_repo.dart` → `LoginApprovalPendingException`, `login_page.dart`, `login_approval_pending_view.dart` | Done; verify only (section 5.8) |
| 401 / approval-403 → clear session and go to login | `session_manager.dart`, `api_base_helper.dart` | Done; verify only |
| Push type `seller_system_user_login_approval` refreshes inbox | `notification_service.dart` (`loginApprovalType`) | Done; extend (section 5.7) |
| Logout calls API then clears Hive | `auth_repo.dart` `logout()` | Done; verify only |

**Missing pieces you must build:**
- `SystemUser` has no status/approval fields.
- The list card shows no badges.
- Approve cannot send `duration_hours`.
- There is no detail view and no revoke action from the list.
- The list does not refresh on app resume or after inbox actions.

---

## 2. API contract (authoritative)

All requests and responses are JSON. Send `Accept: application/json`; send `Content-Type: application/json` when a request has a body (`ApiBaseHelper` already does this and attaches the Bearer token).

### 2.1 Status concepts

Show the two statuses as **separate fields**:

| Field | Values | Meaning |
| --- | --- | --- |
| `system_user_status` | `active`, `inactive` | Whether the system user has an active seller-app session. |
| `login_approval_status` | `not_requested`, `pending`, `approved`, `disapproved` | Whether the seller has granted the user login access. |

- **Do not derive `system_user_status` from the approval status.** A user can be approved but inactive because they haven't logged in yet, or have logged out.
- A logged-in user stays active until they log out, are disapproved, or their approval expires.

UI rules from the contract:
- Show **Active** with a green badge when `system_user_status == active`.
- Show **Inactive** with a neutral (grey) badge when it is `inactive`.
- Show the approval status separately. For an approved grant, show `login_approved_until` in the seller's **local** time if present.
- Refresh the list after approval actions and when returning to the screen. The status is persisted server-side; **never infer it from a local app session.**

### 2.2 List seller system users

```http
GET /api/seller/system-users?per_page=15&search=packer
```

`per_page` (default 15) and `search` (matches name, email or mobile) are optional. The app already sends `page` too; keep that.

HTTP 200:
```json
{
  "success": true,
  "message": "Users fetched successfully.",
  "data": {
    "current_page": 1, "last_page": 1, "per_page": 15, "total": 1,
    "data": [
      {
        "id": 196,
        "name": "Staff User",
        "email": "staff@example.com",
        "mobile": "9876543210",
        "login_approval_status": "approved",
        "login_approval_requested_at": "2026-10-25T08:00:00.000000Z",
        "login_approved_until": "2026-10-26T08:00:00.000000Z",
        "system_user_status": "active"
      }
    ]
  }
}
```

- Rows also contain the user model's other public fields (`access_panel`, timestamps, `profile_image`, …). Keep parsing those as today.
- The two status fields and the two approval timestamps are authoritative for this feature.
- `login_approval_requested_at` and `login_approved_until` may be `null`.

### 2.3 Get a system user's details

```http
GET /api/seller/system-users/{userId}
```

HTTP 200:
```json
{
  "success": true,
  "message": "User retrieved.",
  "data": {
    "user": { "id": 196, "name": "Staff User", "email": "staff@example.com", "mobile": "9876543210" },
    "login_approval_status": "approved",
    "login_approval_requested_at": "2026-10-25T08:00:00.000000Z",
    "login_approved_until": "2026-10-26T08:00:00.000000Z",
    "system_user_status": "active"
  }
}
```

The status fields sit **next to** `user`, not inside it. `user` holds the public model fields and roles; its other fields may change over time, so parse defensively.

### 2.4 List pending login approvals

```http
GET /api/seller/system-users/login-approvals?per_page=15
```

Returns only pending requests for this seller, paginated like 2.2. Rows use **`user_id`** (not `id`), plus `name`, `email`, `mobile`, `login_approval_status` (`pending`), `login_approval_requested_at`, `login_approved_until` (null) and `system_user_status`. Use `user_id` as `{userId}` for the actions below. *(Already implemented by `LoginApprovalsPage`; also parse `system_user_status` there.)*

### 2.5 Approve a system user's login

```http
POST /api/seller/system-users/{userId}/approve-login
```

The body is optional. A custom grant duration in hours may be sent:
```json
{ "duration_hours": 6 }
```

- If `duration_hours` is omitted, the grant defaults to **up to 12 hours**, capped by the platform maximum. The server enforces the bounds; show its 422 message if it rejects a value.
- When no duration is chosen, send an empty body `{}` (don't send `duration_hours: null`).

HTTP 200:
```json
{
  "success": true,
  "message": "System user login approval updated.",
  "data": {
    "user_id": 196,
    "login_approval_status": "approved",
    "login_approved_until": "2026-10-25T14:00:00.000000Z",
    "system_user_status": "inactive",
    "duration_hours": 6
  }
}
```

Approval grants permission to log in; it **does not start a session**. The user usually stays `inactive` until they actually log in. Update the row's approval fields from this response, then refresh the list.

### 2.6 Disapprove a system user's login

```http
POST /api/seller/system-users/{userId}/reject-login
```

No body. The route keeps the legacy name `reject-login`. It disapproves the grant **and revokes the user's existing tokens** (ends their session).

HTTP 200:
```json
{
  "success": true,
  "message": "System user login approval updated.",
  "data": {
    "user_id": 196,
    "login_approval_status": "disapproved",
    "login_approved_until": null,
    "system_user_status": "inactive",
    "duration_hours": null
  }
}
```

Update the local row immediately from this response, then refresh the list.

### 2.7 System-user login (staff side — already implemented)

`POST /api/seller/login` with `email` (or `mobile`), `password`, optional `fcm_token`, `device_type`.

- **Approved:** HTTP 200 with `success: true`, `access_token`, `token_type`, `data` (user) and `assigned_permissions`. Save the token and continue. Login sets `system_user_status` to `active`.
- **Pending or expired grant:** HTTP 403, no token:
  ```json
  { "success": false, "message": "Your login request is waiting for seller approval.",
    "data": { "login_approval_status": "pending", "approval_requested_at": "2026-10-25T08:00:00.000000Z" } }
  ```
  Show the pending screen. To check again, the user re-enters credentials and retries; **do not persist the password**. Treat the response as pending **only** when `data.login_approval_status == "pending"`.
- **Invalid credentials:** `success: false`, an invalid-credentials message and `data: []`. The HTTP status may still be **200**. Validation errors also use `success: false`. Always check `success` and `data`, not just the HTTP status.

### 2.8 Logout (already implemented)

`POST /api/seller/logout` with no body. The server revokes the token and marks the system user inactive. Call it **before** clearing the local token, then return to login.

### 2.9 Errors

Standard envelope: `{ "success": false, "message": "...", "data": null }`.

| HTTP | Meaning | Client behaviour |
| --- | --- | --- |
| 401 | Missing, invalid or revoked token | Clear the token and go to login (already done by `SessionManager`). |
| 403 | Permission denied, or seller approval required | Pending-login payload → pending screen. Otherwise show the message. |
| 404 | User or seller not found | Refresh the screen; show a not-found message if it persists. In the detail sheet: show the message, close the sheet and refresh the list. |
| 422 | Validation failed | Show the server message (e.g. a bad `duration_hours`). |

When an approval expires, the user becomes inactive and their sessions are revoked server-side.

### 2.10 Notifications

Approval notifications only prompt a refresh; the API response is the source of truth. The payload may include `type: "seller_system_user_login_approval"`, `system_user_id` and `seller_id`.

---

## 3. Data layer

### 3.1 `system_users_model.dart` — extend `SystemUser`

Add these fields, parsed with `JsonParser` (nullable-safe), and include them in `toJson`:

```dart
String loginApprovalStatus;        // 'not_requested' | 'pending' | 'approved' | 'disapproved'; default 'not_requested'
DateTime? loginApprovalRequestedAt; // parsed with DateTime.tryParse(...)?.toLocal()
DateTime? loginApprovedUntil;       // parsed with DateTime.tryParse(...)?.toLocal()
String systemUserStatus;            // 'active' | 'inactive'; default 'inactive'
```

Add getters:
- `bool get isActive => systemUserStatus == 'active';`
- `isApprovalPending`, `isApproved`, `isDisapproved`.

Rules:
- Unknown or missing values fall back to the defaults above. Never throw.
- `isActive` must come **only** from `systemUserStatus`, never from the approval status.

Add `SystemUser copyWithApproval({String? loginApprovalStatus, DateTime? loginApprovedUntil, bool clearApprovedUntil = false, String? systemUserStatus})`. Use it to patch a row from an approve/reject response.

### 3.2 New model `LoginApprovalResult`

Put it in `login_approval_model.dart`, parsed from `response['data']` of 2.5 / 2.6:

```dart
class LoginApprovalResult {
  final int userId;
  final String loginApprovalStatus;
  final DateTime? loginApprovedUntil; // toLocal()
  final String systemUserStatus;
  final int? durationHours;
  factory LoginApprovalResult.fromJson(Map<String, dynamic> json);
}
```

Also add `systemUserStatus` (default `'inactive'`) to the existing `LoginApprovalRequest`.

### 3.3 New model `SystemUserDetail`

For 2.3. Parse `data.user` into a `SystemUser` and override its four status fields with the **top-level** `data.*` values (those are authoritative). A simple approach: merge the top-level status keys into the `user` map, then call `SystemUser.fromJson`. If `user` is missing, throw an `ApiException`-style error with a clear message.

### 3.4 `system_users_repo.dart`

- `Future<SystemUser> getSystemUserDetail(int id)` calls `GET {systemUsersApi}/{id}` and returns the parsed user from 3.3. Keep the old `getSystemUserById` if anything uses it.
- Change `approveLogin` to `Future<LoginApprovalResult> approveLogin(int userId, {int? durationHours})`. Post `{'duration_hours': durationHours}` when non-null, else `{}`. Fix the doc comment: the default is "up to 12 hours (server default)", **not** 24.
- Change `disapproveLogin` to return `Future<LoginApprovalResult>`.
- Update every caller.

---

## 4. State management

### 4.1 `SystemUserBloc`

Add events, following the existing event/handler style:
- `ApproveSystemUserLoginEvent({required int id, int? durationHours})`
- `DisapproveSystemUserLoginEvent({required int id})`
- `ApplyLoginApprovalResultEvent(LoginApprovalResult result)`: patches the matching user in `state.users` via `copyWithApproval`, with no network call. The inbox uses it so the list stays in sync without a reload.

Approve/disapprove handlers:
1. Add the id to a new `Set<int> processingIds` in `SystemUserState` (add it to `copyWith`).
2. Call the repo.
3. On success, patch the row from the result and set `actionMessage`:
   - Approve: "Login approved until {local time}". If `loginApprovedUntil` is null, use "Login approved".
   - Disapprove: "Access revoked".
4. Then refetch the current list (`FetchSystemUsersEvent(isRefresh: true, search: state.search)`) **without** showing the full-screen shimmer. Keep showing the existing users while it reloads; add a `silent` flag to `FetchSystemUsersEvent` if needed.
5. On error, remove the id from `processingIds` and set `errorMessage` to the `ApiException` message.

After a successful approve or disapprove from the list or detail sheet, also call `context.read<LoginApprovalsCubit>().fetch()` from the UI so the banner count stays correct.

### 4.2 `LoginApprovalsCubit`

- `approve(int userId, {int? durationHours})` passes the duration to the repo.
- Success message:
  - With a returned `loginApprovedUntil`: "Login approved until {dd MMM, hh:mm a}".
  - Otherwise: "Login approved".
  - **Remove** the hardcoded "Login approved for 24 hours".
- Update the class doc comment that says "(24h access)".
- Add an optional `void Function(LoginApprovalResult)? onDecision` callback. Alternatively, expose the last result in state and use a `BlocListener` in the page; pick whichever matches existing patterns best. Use it so `LoginApprovalsPage` can dispatch `ApplyLoginApprovalResultEvent` to `SystemUserBloc` and trigger a silent list refetch after each decision. `SystemUserBloc` is provided app-wide via `MasterApiService`; check how it is provided and use `context.read` safely (wrap in try/catch like `notification_service.dart` does).

---

## 5. UI

### 5.1 Status badges (shared widget)

Create `lib/screen/more_page/view/system_users/widgets/system_user_status_badges.dart` with two small widgets:

- `SystemUserActivityBadge(status)`:
  - `active` → green pill, dot + "Active"; use the app's success green (check `AppColors` for an existing green, else `Colors.green`).
  - `inactive` → neutral grey pill, hollow dot + "Inactive".
- `LoginApprovalBadge(status)`:
  - `pending` → orange "Pending", matching the existing orange "Pending" pill in `_LoginApprovalCard`.
  - `approved` → primary/blue "Approved".
  - `disapproved` → red "Disapproved".
  - `not_requested` → render nothing (`SizedBox.shrink()`).

Pill style: `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)`, radius 20, 12% alpha background of the colour, 12px w600 text in the colour. Copy the existing pill in `login_approvals_page.dart` and refactor that pill to use `LoginApprovalBadge` too.

### 5.2 System users list card (`system_user_card.dart` + `system_users_page.dart`)

In `system_users_page.dart`, pass the new fields through the `CustomCard` data map:

```dart
'systemUserStatus': user.systemUserStatus,
'loginApprovalStatus': user.loginApprovalStatus,
'loginApprovedUntil': user.loginApprovedUntil,       // DateTime?
'loginApprovalRequestedAt': user.loginApprovalRequestedAt, // DateTime?
```

`SystemUserCard` layout:
- **Row 1:** name (+ existing `accessPanel`) on the left, `SystemUserActivityBadge` on the right.
- **Row 2:** email · mobile (existing).
- **Row 3, new:** `LoginApprovalBadge`, then muted text:
  - approved with `loginApprovedUntil` → "until 26 Oct, 1:30 PM" (`DateFormat('dd MMM, hh:mm a')`, local time)
  - pending with `loginApprovalRequestedAt` → "requested {TimeUtils.formatTimeAgo}"
  - disapproved or not_requested → no extra text
- **Pending rows only, if the user has `systemUserEdit`:** a small "Approve" text button aligned right. It opens the Approve sheet (5.3). Pass an `onApprove` callback through `CustomCard`, or render the card directly. Choose the least invasive change that keeps the existing edit/delete menu working.
- Keep the existing created-at "time ago" line, or drop it if the row gets too tall. Prefer keeping it.
- While the user's id is in `processingIds`, show a small `CustomLoadingIndicator` in place of the Approve button.
- **Tapping the card** opens the User detail sheet (5.4). Edit and delete stay in the existing card menu, unchanged.

### 5.3 Approve sheet (new): `widgets/approve_login_bottom_sheet.dart`

A modal bottom sheet, styled like `manage_system_user_bottom_sheet.dart`. It returns the chosen duration via `Navigator.pop(context, ApproveChoice(durationHours: int?))`, or `null` on cancel.

- **Title:** "Approve login for {name}"
- **Subtitle:** "They can sign in until access ends. Approval doesn't log them in."
- **Label:** "Access duration"
- **Choice chips:** `2 h`, `4 h`, `8 h`, `12 h (default)`, `Custom`.
  - `12 h (default)` is preselected and maps to `durationHours: null`, so the server default applies and no field is sent.
  - The other presets map to their number.
- **Custom:** reveals a numeric `TextField` (digits only, hours, required, must be ≥ 1). Show an inline error if empty or 0. Don't hardcode an upper bound; the server enforces it and its 422 message is shown.
- **Preview line:** "Access until {dd MMM, hh:mm a}", computed as `DateTime.now().add(Duration(hours: chosen ?? 12))`. For the default, prefix "About" because the server may cap it.
- **Buttons:** `Cancel` (outlined) and `Approve` (filled, `AppColors.primaryColor`).

Use this sheet from **all three** entry points:
- the Approve button in `_LoginApprovalCard` (`login_approvals_page.dart`; currently approves immediately without a sheet)
- the Approve link on a pending list card
- Approve / Extend access in the detail sheet

Run the permission and `DemoGuard.shouldProceed` checks **before** opening the sheet.

### 5.4 User detail sheet (new): `widgets/system_user_detail_bottom_sheet.dart`

Opened by tapping a card. On open, call `getSystemUserDetail(id)`. Show a shimmer while loading, and an error message + Retry on failure. On 404, show the message, close the sheet and refetch the list.

Content:
- **Header:** avatar (`profileImage` if present, otherwise initials circle), name, email, and `SystemUserActivityBadge` on the right.
- **Info rows** (label muted on the left, value on the right):
  - Activity: "Active (logged in)" / "Inactive"
  - Login approval: `LoginApprovalBadge` (show "Not requested" text for `not_requested`)
  - Access until: local time, or "—"
  - Last requested: local time, or "—"
  - Mobile
- **Actions**, only if `systemUserEdit`; run `DemoGuard` before each:
  - `pending` → `Disapprove` (red outlined) + `Approve` (filled). Approve opens 5.3.
  - `approved` → `Extend access` (outlined; opens 5.3, which re-approves with the new duration) + `Revoke access` (red outlined).
  - `disapproved` or `not_requested` → `Approve` (filled; opens 5.3).
- **Revoke / Disapprove confirmation** (reuse the dialog from `login_approvals_page.dart`):
  - Title: "Revoke access?"
  - Body: "{name} won't be able to sign in and any active session on their device will end."
  - Buttons: Cancel / Revoke (red)
- After any action:
  - dispatch the bloc event from 4.1
  - update the sheet's own displayed values from the `LoginApprovalResult` (don't wait for the refetch)
  - refetch the inbox count
  - show the snackbar
- A small footer note under the actions: "Approval allows sign-in. Status turns Active only after they log in."

Keep the sheet's state local (a small `StatefulWidget` or cubit), since it doesn't need to be global.

### 5.5 Approvals inbox (`login_approvals_page.dart`)

- Approve opens the sheet (5.3), then calls `approve(userId, durationHours: …)`.
- Use the shared `LoginApprovalBadge` for the pending pill.
- After each decision, sync the users list (4.2).
- Everything else stays as it is.

### 5.6 Refresh on open and on resume (contract 2.1 / section 11.6)

`SystemUsersPage` already fetches on open. Add `WidgetsBindingObserver` (follow `incoming_orders_controller.dart`). On `AppLifecycleState.resumed`, silently refetch the users list with the current search and call `LoginApprovalsCubit.fetch()`. Do the same in `LoginApprovalsPage` (refetch its list). Remove the observer in `dispose`.

Also refetch silently when the user comes back to `SystemUsersPage` from a pushed route (e.g. returning from the inbox). Await the `context.push(AppRoutes.loginApprovals)` in the banner, then refetch.

### 5.7 Notifications (`notification_service.dart`)

In the existing `loginApprovalType` handling (`_refreshLoginApprovalsFromContext`), also trigger a silent `SystemUserBloc` refetch if one is available, wrapped in try/catch like the existing code. Never trust the payload values; only use the push as a refresh trigger. Don't change how other notification types are handled.

### 5.8 Staff side — verify, change only if it breaks the contract

Check each item and fix only what deviates from 2.7–2.9:

1. `auth_repo.dart` treats the response as pending **only** when `statusCode == 403 && data.login_approval_status == 'pending'`. This is already true; keep it.
2. A 200 response with `success: false` (invalid credentials) must show as a login **error**, never as success or pending, and no token may be saved. Check `_extractAndSaveToken` and the `AuthBloc` login handler. If a `success: false` 200 could save a token or navigate into the app, fix it to throw/emit an error with the server `message`.
3. Disapproved or expired logins (non-pending 403) show the server message as a normal error. This is already the case; keep it.
4. `LoginApprovalPendingView` "Check again" re-sends the login with the credentials the user enters or still has **in memory** from the form. It must never write the password to Hive, SharedPreferences or logs. Verify this and fix if needed.
5. `logout()` calls `POST /seller/logout` **before** `HiveStorage.clearAll()`. This is already the case; keep it.
6. `SessionManager.isLoginApprovalError` + 401 handling: already correct; keep it.

Do **not** change the login request body.

---

## 6. Copy (add to l10n; English below)

| Key | English |
| --- | --- |
| `statusActive` | Active |
| `statusInactive` | Inactive |
| `approvalPending` | Pending |
| `approvalApproved` | Approved |
| `approvalDisapproved` | Disapproved |
| `approvalNotRequested` | Not requested |
| `approvedUntil` | until {time} |
| `requestedAgo` | requested {ago} |
| `approveLoginFor` | Approve login for {name} |
| `approveLoginSubtitle` | They can sign in until access ends. Approval doesn't log them in. |
| `accessDuration` | Access duration |
| `defaultDuration` | 12 h (default) |
| `customDuration` | Custom |
| `hoursLabel` | Hours |
| `enterValidHours` | Enter a number of hours |
| `accessUntilPreview` | Access until {time} |
| `aboutAccessUntilPreview` | About {time} |
| `approve` | Approve |
| `extendAccess` | Extend access |
| `revokeAccess` | Revoke access |
| `revokeAccessTitle` | Revoke access? |
| `revokeAccessBody` | {name} won't be able to sign in and any active session on their device will end. |
| `loginApprovedUntil` | Login approved until {time} |
| `loginApproved` | Login approved |
| `accessRevoked` | Access revoked |
| `activityLabel` | Activity |
| `activeLoggedIn` | Active (logged in) |
| `loginApprovalLabel` | Login approval |
| `accessUntilLabel` | Access until |
| `lastRequestedLabel` | Last requested |
| `approvalFooterNote` | Approval allows sign-in. Status turns Active only after they log in. |

Before adding a key, check whether `app_en.arb` already has an equivalent (e.g. `approve`, `cancel`, `mobile`) and reuse it.

---

## 7. Edge cases checklist

- `login_approved_until` / `login_approval_requested_at` null → show no expiry text and "—" in the detail sheet; never crash.
- Unknown status strings → treated as `inactive` / `not_requested`.
- An approve response with `system_user_status: inactive` is **normal**: show Approved + Inactive, not an error.
- An approved row whose `login_approved_until` is already in the past locally → still show the server's values (the server is the source of truth); the next refetch corrects it.
- Double taps: ignore an action while the id is in `processingIds` (list) or the sheet is busy.
- Actions on a user that was deleted elsewhere (404) → show the message and refetch.
- No permission → no action buttons; the read-only badges still show.
- Demo mode → `DemoGuard.shouldProceed` blocks all write actions.
- All times are shown in the device's local time zone.
- Dark mode: badges and sheets must read well in both themes (use `Theme.of(context)` / `AppColors` like the existing widgets).
- Tablet/large `screenType`: use the `UIUtils` sizes like the surrounding code.

---

## 8. Acceptance criteria

1. The system users list shows an Active/Inactive badge and a separate approval badge on every row, plus "until {local time}" for approved users.
2. Approving from the inbox, a list card, or the detail sheet opens the duration sheet:
   - default → POST body `{}`
   - preset or custom → `{ "duration_hours": N }`
3. After approve/disapprove:
   - the row updates immediately from the response
   - the list and inbox count are refetched
   - the snackbar shows the server-derived expiry
   - no "24 hours" text remains anywhere (`grep -rn "24 hours" lib` returns nothing related to approvals)
4. Revoke on an approved user calls `reject-login` after a confirmation, then shows Disapproved + Inactive.
5. Tapping a card opens the detail sheet loaded from `GET /system-users/{id}`, with the top-level status fields winning over `user.*`.
6. Bringing the app back to the foreground on System Users or Login Approvals refetches the data.
7. A `seller_system_user_login_approval` push refreshes both the inbox and the users list.
8. Staff side: pending only on 403 + `pending`; a 200 `success:false` never logs in; the password is never persisted; logout calls the API before clearing.
9. `flutter analyze` shows no new issues; existing System Users create/edit/delete still work.

---

## 9. Deliverable

When done, reply with:
- every file you created or changed, with one line each on what changed
- anything in section 5.8 you found broken and fixed
- any deviation from this spec and why
