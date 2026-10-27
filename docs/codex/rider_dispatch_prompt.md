# Codex task: Seller app — Rider Dispatch Center

You are working in a Flutter seller app (`package:hyper_local_seller`, flutter_bloc + go_router + dio + Hive + flutter_screenutil). Build a **Rider Dispatch** feature that lets the seller monitor how the backend is dispatching their prepared, bagged orders to riders, get alerted when an order has **no nearby rider**, mark an order for **seller self-delivery**, and see **rider availability** around their pickup stores.

**The API contract below is the single source of truth. Follow it exactly. Do not invent endpoints, fields, query params, push events, timeouts or behaviours that are not written here.** Where the contract says something about UI behaviour (alert, refresh timing, when an action is allowed), implement it as written.

---

## 0. Background (read before coding)

The **backend owns rider selection**. The seller app never picks or assigns a rider. When an order is bagged (existing scan → bag flow in `lib/screen/order_page/incoming_orders/`), the server reserves the order to one eligible rider and pushes it to the rider app. Eligible = rider `active`, has an FCM token, reported a location in the last 2 minutes, is within 200 m of the pickup store, and has no pending offer or `assigned`/`in_progress` delivery.

There is **no timeout**: an offer stays with the rider until it is accepted, cancelled, or a person handles it. So the seller app's job is:

1. **Monitor** the dispatch queue (poll).
2. **Alert** when `summary.no_nearby_riders > 0`, and point at the affected orders.
3. **Self-deliver**: let the seller take over a ready order that a rider has not accepted yet.

The seller can also see a **rider availability** snapshot (active / available-within-radius / inactive counts plus a per-rider table with the reason a rider is unavailable), refreshed every 30 seconds.

Out of scope (do NOT build), because the backend does not support it yet:
- **Marking a self-delivery order as delivered.** Self-delivery only assigns delivery responsibility to the seller. The existing seller order status API (`POST /api/seller/orders/{orderItemId}/{status}`) does **not** support `delivered`, and there is no seller completion endpoint. **Never call the status API to simulate delivery** and do not add any "Mark delivered" button.
- **Seller push for `no_nearby_riders`.** No seller FCM event exists. Do not add an FCM handler for `dispatch_alert` or anything similar; discover the state only by polling.
- **Cancel a pending rider offer / re-dispatch.** No seller API exists. Self-deliver is the only fallback.
- Rider-side work: rider acceptance, the `new_order` / `order_alert_cancel` pushes, the rider location heartbeat.
- Choosing or reassigning a specific rider.
- The web-panel **session** routes `GET /seller/orders/dispatch-center`, `GET /seller/orders/dispatch-center/data` and `POST /seller/orders/{orderId}/self-deliver` (no `/api` prefix). The app uses only the three `/api/seller` bearer-token endpoints in §2.

---

## 1. Ground rules

1. Mirror the existing modules' style and structure exactly — read these first:
   - `lib/screen/more_page/view/delivery_boys/` — repo (`ApiBaseHelper`, `lastMessage`), bloc/state with Equatable, model parsing with `JsonParser`, the 60 s `Timer.periodic` + `WidgetsBindingObserver` refresh pattern in `view/delivery_boys_page.dart`, status badge widget `widgets/rider_status_badge.dart`.
   - `lib/screen/order_page/` — `repo/order_repo.dart`, `view/order_page.dart` (`CustomScaffold`, `RefreshIndicator`, `CardShimmer`, `EmptyStateWidget`), `widgets/order_card.dart` (status color mapping), `widgets/order_dialogs.dart`.
   - `test/delivery_boys/repo_test.dart` + `state_test.dart` (local `HttpServer` + `initTestHive` from `test/incoming_orders/helpers.dart`).
2. Reuse existing shared widgets/utilities — do not create new equivalents:
   `CustomScaffold`, `CustomCard`, `showCustomSnackbar`, `showAppAlertDialog`, `EmptyStateWidget`, `CardShimmer` / `card_shimmers.dart`, `CustomShimmer`, `CustomLoadingIndicator`, `DemoGuard.shouldProceed(context)` (call before the self-deliver write), `PermissionChecker.hasPermission`, `JsonParser` (`lib/service/json_parser.dart`), `AppColors`, `ImagesPath`, `UIUtils`, `ScreenSizeBloc` / `screenType`, `platformPage(...)` in the router.
3. Errors: `ApiBaseHelper` throws `ApiException(message, statusCode, responseData)`. Show the server `message` to the user. Never surface raw exception strings.
4. All user-facing strings go through l10n: add keys to `lib/l10n/app_en.arb`, `app_hi.arb`, `app_ar.arb` (English text is acceptable in hi/ar where no translation is known) and use `l10n?.key ?? 'English fallback'` like the rest of the app. Regenerate with `flutter gen-l10n`.
5. Do not touch unrelated files. In `api_routes.dart` **only append**; do not change existing URLs.
6. The working tree already contains uncommitted Delivery Boys work (`lib/screen/more_page/view/delivery_boys/`, and edits to `main.dart`, `app_routes.dart`, `app_permissions.dart`, `master_api_service.dart`, `api_routes.dart`, l10n files). **Keep all of it intact** — add your changes alongside it.
7. Run `flutter analyze` and `flutter test test/dispatch` at the end and fix every issue you introduced.

---

## 2. API contract (authoritative)

Both endpoints require `Authorization: Bearer <seller_sanctum_token>` and `Accept: application/json` (already attached by `ApiBaseHelper`). Base: `ApiRoutes.baseUrl` = `.../api/seller`.

### 2.1 Dispatch dashboard
```http
GET /api/seller/orders/dispatch-dashboard
```
No query params. Success `200`:
```json
{
  "success": true,
  "message": "Dispatch dashboard fetched successfully.",
  "data": {
    "summary": {
      "ready_orders": 2,
      "no_nearby_riders": 1,
      "assigned_orders": 1
    },
    "orders": [
      {
        "order_id": 183,
        "order_number": "NM-20261025-AB3XK9ZM",
        "status": "no_nearby_riders",
        "delivery_boy_id": null,
        "delivery_boy_name": null,
        "pickup": "Sharma Kirana",
        "pickup_store_id": 12,
        "pickup_latitude": "21.14580000",
        "pickup_longitude": "79.08820000",
        "nearby_available_riders": 0,
        "bag_barcode": "BAG-000183",
        "created_at": "2026-10-25T10:00:00+00:00"
      },
      {
        "order_id": 184,
        "order_number": "NM-20261025-CD4LM2PQ",
        "status": "awaiting_rider_acceptance",
        "delivery_boy_id": 5,
        "delivery_boy_name": "Rider Name",
        "pickup": "Sharma Kirana",
        "pickup_store_id": 12,
        "pickup_latitude": "21.14580000",
        "pickup_longitude": "79.08820000",
        "nearby_available_riders": 2,
        "bag_barcode": "BAG-000184",
        "created_at": "2026-10-25T10:01:00+00:00"
      }
    ]
  }
}
```

Order `status` values (implement exactly these meanings):

| status | meaning | UI |
|---|---|---|
| `no_nearby_riders` | Seller **alert** state. No eligible rider near the pickup store. Seller may self-deliver or wait for an eligible rider to report a location. | Red / danger. Show "Deliver myself" as the primary action. |
| `waiting_for_dispatch` | An eligible rider is nearby; dispatch is pending. | Neutral / grey. "Deliver myself" available (secondary). |
| `awaiting_rider_acceptance` | Reserved and pushed to one rider (`delivery_boy_name`). The alert remains active until a person acts. The server does **not** time out or clear it. | Amber / warning. Show reserved rider name. "Deliver myself" available (secondary). |
| `rider_assigned` | Rider accepted the order. | Green / success. **No** self-deliver action. |
| `seller_self_delivery` | Seller took responsibility for delivery. | Purple/primary tint. **No** action. |

Any other / unknown status string → parse to `DispatchStatus.unknown`, render a neutral badge with the raw string humanised (`snake_case` → `Snake case`), no action. Never crash on unknown values.

Field notes:
- `delivery_boy_id` / `delivery_boy_name` are nullable.
- `pickup_latitude` / `pickup_longitude` are **strings** — parse with `double.tryParse`, nullable. Do not display raw coordinates in the UI.
- `created_at` is ISO-8601 with offset → `DateTime.tryParse(...)?.toLocal()`; display as relative time ("4 min ago") — reuse an existing relative-time helper if the project has one (search `timeago`/`ago` in `lib/utils`), otherwise write a tiny private one.
- `order_id` is the id used in the self-deliver URL (§2.2). It is **not** necessarily the same as `SellerOrder.id`/`sellerOrderId` in the orders list — when correlating with the orders list (§4.6) match on **`order_number`**.

### 2.2 Mark an order for seller self-delivery
```http
POST /api/seller/orders/{order_id}/self-deliver
```
No body (send `{}`), where `{order_id}` is `order_id` from §2.1.

Allowed for a ready bagged order owned by the seller. Rejected if a rider already accepted it. If a rider had a pending offer, the server sends that rider an `order_alert_cancel` (`reason: reassigned`) — nothing for the app to do, but **tell the seller in the confirm dialog** (see §4.4).

Success `200`:
```json
{ "success": true, "message": "Order marked for seller self-delivery.", "data": { "order_id": 183 } }
```

Conflict `409` — rider already accepted, or already marked for self-delivery:
```json
{ "success": false, "message": "The rider has already accepted this order. Contact dispatch to reassign it.", "data": {} }
```

Not found `404` — order not owned by this seller:
```json
{ "success": false, "message": "Order not found for this seller.", "data": {} }
```

Handling:
- `200` → success snackbar with server `message`; locally set that order's status to `seller_self_delivery` and clear rider fields; then refresh the dashboard.
- `409` → error snackbar with server `message`; revert any optimistic change; refresh the dashboard (the order's true status will come back, e.g. `rider_assigned`).
- `404` → error snackbar with server `message`; refresh (the order will drop out).
- Other (`403`, `422`, `5xx`, network) → error snackbar with `ApiException.message`; revert; no crash.

What self-delivery means (show this to the seller): it **only** moves delivery responsibility to the seller. It does not mark items delivered, and the app cannot complete the delivery. A `seller_self_delivery` order card must show an info line such as "You're responsible for delivering this order. Completing it in the app isn't available yet." and **no** action buttons.

### 2.3 Rider availability
```http
GET /api/seller/orders/rider-availability
```
Bearer-token endpoint (seller authentication + seller approval middleware). No query params. It returns data only for the authenticated seller's pickup stores and delivery zones.

Success `200`:
```json
{
  "success": true,
  "message": "Rider availability fetched successfully.",
  "data": {
    "summary": {
      "active_riders": 4,
      "available_riders_in_radius": 2,
      "inactive_riders": 3
    },
    "riders": [
      {
        "id": 5,
        "name": "Rider Name",
        "status": "active",
        "verification_status": "verified",
        "delivery_zone": "Dharampeth",
        "is_available_in_radius": true,
        "nearest_pickup_distance_m": 84,
        "location_reported_at": "2026-10-25T10:00:00+00:00",
        "location_age_seconds": 18,
        "unavailable_reason": null
      },
      {
        "id": 6,
        "name": "Another Rider",
        "status": "active",
        "verification_status": "verified",
        "delivery_zone": "Dharampeth",
        "is_available_in_radius": false,
        "nearest_pickup_distance_m": null,
        "location_reported_at": "2026-10-25T09:54:00+00:00",
        "location_age_seconds": 378,
        "unavailable_reason": "location_stale"
      }
    ]
  }
}
```

Semantics:
- `available_riders_in_radius` uses the dispatch eligibility rules: active and verified, registered FCM token, location reported within 2 minutes, within 200 m of a seller pickup store, no pending offer, and no `assigned`/`in_progress` delivery.
- Rows do **not** include GPS coordinates. Never try to show a map.
- Nullable: `delivery_zone`, `nearest_pickup_distance_m` (int, metres), `location_reported_at`, `location_age_seconds`, `unavailable_reason`.
- `unavailable_reason` values and their UI labels (l10n):

| value | label |
|---|---|
| `inactive` | Offline |
| `not_verified` | Not verified |
| `no_fcm_token` | Notifications not set up |
| `location_stale` | Location not updated recently |
| `no_pickup_store` | No pickup store |
| `outside_pickup_radius` | Too far from store |
| `pending_offer` | Has a pending offer |
| `active_delivery` | On a delivery |
| anything else | humanised raw string |

- Refresh this snapshot every **30 seconds** while it is visible (the web page does the same).
- Errors: `403` (seller not approved / no permission) → hide the availability section and show nothing else for it (no error snackbar on silent polls). Other errors on first load → small inline error with "Retry"; on silent polls keep the old data.

### 2.4 Seller app workflow (from the contract — implement as written)
1. Poll `GET /api/seller/orders/dispatch-dashboard`. The web dispatch page refreshes every **15 seconds**; use the same interval.
2. Show an alert when `summary.no_nearby_riders > 0`; identify affected orders by their `no_nearby_riders` status.
3. If the seller chooses self-delivery, call `POST .../{order_id}/self-deliver` and stop offering that order for rider dispatch (i.e. after success it no longer shows the action).
4. For `awaiting_rider_acceptance`, show the reserved rider and keep monitoring. Do not add any client-side timeout or auto-action.
5. Rider locations are kept fresh by the rider app; the backend retries dispatch on location updates. Nothing to do in the seller app except keep polling.

---

## 3. Files to create

```
lib/screen/order_page/dispatch/
  model/dispatch_model.dart
  repo/dispatch_repo.dart
  cubit/dispatch_cubit.dart
  cubit/dispatch_state.dart
  cubit/rider_availability_cubit.dart
  cubit/rider_availability_state.dart
  view/dispatch_center_page.dart
  widgets/dispatch_summary_row.dart
  widgets/dispatch_order_card.dart
  widgets/dispatch_status_badge.dart
  widgets/dispatch_alert_banner.dart
  widgets/self_deliver_sheet.dart
  widgets/rider_availability_section.dart
  widgets/rider_availability_tile.dart
test/dispatch/
  model_test.dart
  repo_test.dart
  cubit_test.dart
  availability_test.dart
```

### 3.1 `model/dispatch_model.dart`
```dart
enum DispatchStatus {
  noNearbyRiders('no_nearby_riders'),
  waitingForDispatch('waiting_for_dispatch'),
  awaitingRiderAcceptance('awaiting_rider_acceptance'),
  riderAssigned('rider_assigned'),
  sellerSelfDelivery('seller_self_delivery'),
  unknown('');
  // static DispatchStatus parse(dynamic raw) — unknown for anything else
  // bool get canSelfDeliver => this == noNearbyRiders || this == waitingForDispatch || this == awaitingRiderAcceptance;
  // bool get needsAction => this == noNearbyRiders;
}
```
- `class DispatchSummary extends Equatable` — `readyOrders`, `noNearbyRiders`, `assignedOrders` (ints, default 0 via `JsonParser`). `bool get hasAlert => noNearbyRiders > 0`.
- `class DispatchOrder extends Equatable` — every field from §2.1: `orderId`, `orderNumber`, `status` (`DispatchStatus`), `rawStatus` (String, keep for unknown display), `deliveryBoyId` (int?), `deliveryBoyName` (String?, null when empty), `pickup`, `pickupStoreId` (int?), `pickupLatitude` (double?), `pickupLongitude` (double?), `nearbyAvailableRiders` (int), `bagBarcode` (String), `createdAt` (DateTime?). `fromJson`, `copyWith` (must allow setting `deliveryBoyId`/`deliveryBoyName` back to null — use a sentinel or `ValueGetter<T?>?` pattern).
- `class DispatchDashboard extends Equatable` — `summary`, `List<DispatchOrder> orders`. `fromJson(Map response)` reads `response['data']`; tolerate missing `summary`/`orders` (empty defaults).
- Do not add `toString` overrides that dump coordinates.
- Rider availability models (same file or `model/rider_availability_model.dart`):
  - `enum RiderUnavailableReason { inactive, notVerified, noFcmToken, locationStale, noPickupStore, outsidePickupRadius, pendingOffer, activeDelivery, unknown }` with `parse(dynamic raw)` (null → returns null at the call site, unknown string → `unknown`). Keep the raw string for display of unknown values.
  - `class RiderAvailabilitySummary` — `activeRiders`, `availableRidersInRadius`, `inactiveRiders` (ints, default 0).
  - `class AvailableRider` — `id`, `name`, `status` (String), `verificationStatus` (String), `deliveryZone` (String?), `isAvailableInRadius` (bool), `nearestPickupDistanceM` (int?), `locationReportedAt` (DateTime?, local), `locationAgeSeconds` (int?), `unavailableReason` (`RiderUnavailableReason?`), `rawUnavailableReason` (String?).
  - `class RiderAvailability` — `summary`, `List<AvailableRider> riders`; tolerant `fromJson` like `DispatchDashboard`.

### 3.2 `repo/dispatch_repo.dart`
Class `DispatchRepo` using `ApiBaseHelper` (same style as `DeliveryBoyRepo`):
- `String lastMessage = '';`
- `Future<DispatchDashboard> getDashboard()` → `GET ApiRoutes.dispatchDashboardApi`.
- `Future<RiderAvailability> getRiderAvailability()` → `GET ApiRoutes.riderAvailabilityApi`.
- `Future<int> markSelfDelivery(int orderId)` → `POST ApiRoutes.selfDeliverApi(orderId)` with `{}`; sets `lastMessage` from `response['message']`; returns `data.order_id` (fallback `orderId`). Let `ApiException` propagate.

### 3.3 `api_routes.dart` (append only, under the existing `ordersApi` block or at the end)
```dart
// rider dispatch
static String dispatchDashboardApi = '$ordersApi/dispatch-dashboard';
static String selfDeliverApi(int orderId) => '$ordersApi/$orderId/self-deliver';
static String riderAvailabilityApi = '$ordersApi/rider-availability';
```
Keep `dispatchDashboardApi` a non-final `static String` like the others so tests can point it at a local server.

### 3.4 `cubit/dispatch_state.dart`
```dart
enum DispatchFilter { all, needsAction, awaiting, assigned }

class DispatchState extends Equatable {
  final DispatchDashboard? dashboard;   // null until first load
  final bool isLoading;                 // first load only → shimmer
  final bool isRefreshing;              // pull-to-refresh / silent poll — keep list visible
  final String? error;                  // first-load error → error/empty state with Retry
  final DispatchFilter filter;
  final Set<int> pendingSelfDeliver;    // order ids with an in-flight self-deliver call
  final DateTime? lastUpdated;
  // List<DispatchOrder> get visibleOrders — apply filter:
  //   all → everything
  //   needsAction → status == noNearbyRiders
  //   awaiting → waitingForDispatch || awaitingRiderAcceptance
  //   assigned → riderAssigned || sellerSelfDelivery
  // Sort: noNearbyRiders first, then awaitingRiderAcceptance, waitingForDispatch, riderAssigned, sellerSelfDelivery, unknown; within a group oldest createdAt first.
}
```

### 3.5 `cubit/dispatch_cubit.dart`
`class DispatchCubit extends Cubit<DispatchState>` taking `DispatchRepo` and an injectable `Duration pollInterval = const Duration(seconds: 15)` (for tests).
- `Future<void> load()` — first load, sets `isLoading`.
- `Future<void> refresh({bool silent = true})` — keep current data; on error during a silent refresh keep the old data and do **not** set `error` (log with `debugPrint` only). Ignore a refresh if one is already in flight.
- `void startPolling()` / `void stopPolling()` — `Timer.periodic(pollInterval, (_) => refresh())`. `startPolling` must be idempotent and should trigger an immediate `refresh()`. Cancel in `close()`.
- `void setFilter(DispatchFilter f)`.
- `Future<SelfDeliverResult> selfDeliver(int orderId)`:
  1. If `orderId` is already in `pendingSelfDeliver`, return early.
  2. Add to `pendingSelfDeliver`; optimistically set that order to `sellerSelfDelivery` with null rider fields and recompute summary locally (decrement `noNearbyRiders` if it was that status; never below 0).
  3. Call repo. On success → remove from pending, `refresh()`, return `SelfDeliverResult.success(repo.lastMessage)`.
  4. On `ApiException` → restore the previous order + summary, remove from pending, `refresh()`, return `SelfDeliverResult.failure(e.message, statusCode: e.statusCode)`.
  - `SelfDeliverResult` is a small immutable class (or record) — the UI shows the snackbar from it.
- `void reset()` — stop polling, emit initial state (used on logout/store switch).

### 3.6 `cubit/rider_availability_cubit.dart`
Separate small cubit (different refresh interval and lifecycle):
- State: `RiderAvailability? data`, `bool isLoading`, `String? error`, `bool isForbidden` (true after a `403`), `bool expanded` (rider table open/closed), `DateTime? lastUpdated`.
- `load()`, silent `refresh()` (ignore if in flight; keep old data on error), `startPolling()` / `stopPolling()` with injectable `pollInterval` default **30 seconds**, `toggleExpanded()`, `reset()`. On `403` set `isForbidden = true` and stop polling.
- Rider list sort: available-in-radius first (by `nearestPickupDistanceM` ascending, nulls last), then active-but-unavailable, then inactive; ties by name.

### 3.7 Provide them globally (so the Orders page and the Dispatch page share one poller each)
- `main.dart`: `RepositoryProvider(create: (_) => DispatchRepo())` next to `OrdersRepo`, and `BlocProvider(create: (context) => DispatchCubit(context.read<DispatchRepo>()))` and `BlocProvider(create: (context) => RiderAvailabilityCubit(context.read<DispatchRepo>()))` next to `OrdersBloc`.
- `lib/service/master_api_service.dart`: in the reset section, call `context.read<DispatchCubit>().reset();` and `context.read<RiderAvailabilityCubit>().reset();` (same place `DeliveryBoyReset` is added).

---

## 4. UI

Follow the existing Material look of the Orders screens (`AppColors.primaryColor`, `UIUtils` spacing, `screenType` responsive sizing). Use semantic colours: danger = red, warning = amber/orange, success = green, self-delivery = `AppColors.primaryColor` tint, neutral = grey — same palette approach as `order_card.dart` (`color` + `color.withValues(alpha: 0.1)` background).

### 4.1 Route
- `lib/router/app_routes.dart`: add `static const String dispatchCenter = '/orders/dispatch';` and a `GoRoute(path: AppRoutes.dispatchCenter, name: AppRoutes.dispatchCenter, pageBuilder: (context, state) => platformPage(const DispatchCenterPage()))`. Make sure it does not collide with the existing `orderDetails` route pattern (check whether `orderDetails` is `/orders/:id`; if so register `dispatchCenter` **before** it or use `/dispatch-center`).

### 4.2 `DispatchCenterPage` (new screen)
- `StatefulWidget` with `WidgetsBindingObserver`:
  - `initState`: if dashboard is null → `cubit.load()`; then `cubit.startPolling()`.
  - `didChangeAppLifecycleState`: `resumed` → `startPolling()` (immediate refresh); `paused`/`inactive`/`hidden` → `stopPolling()`.
  - `dispose`: remove observer. Do **not** stop polling if the Orders page (§4.6) is still using it — simplest: the Dispatch page calls `stopPolling()` on dispose only if it started it and the Orders page is not visible. Acceptable simpler approach: the Orders page owns start/stop based on its own visibility, and the Dispatch page calls `startPolling()` on init and nothing on dispose (the Orders page underneath keeps polling). Pick one, document it in a one-line comment, and make sure **no timer leaks after logout** (`reset()`).
- `CustomScaffold(title: l10n?.dispatchCenter ?? 'Dispatch center', showAppbar: true, centerTitle: true)` with a refresh `IconButton` in the actions (if `CustomScaffold` supports actions; otherwise put it in the header row).
- Body (`RefreshIndicator` → `CustomScrollView`/`ListView` with `AlwaysScrollableScrollPhysics`):
  1. "Updated HH:mm:ss · auto-refresh every 15s" caption from `lastUpdated` (muted, small).
  2. `DispatchAlertBanner` when `summary.hasAlert` — e.g. "1 order has no nearby rider" (pluralised l10n) + "Deliver it yourself or wait for a rider nearby." Tapping it sets filter to `needsAction`.
  3. `DispatchSummaryRow` — three equal tiles: Ready (`ready_orders`), No rider (`no_nearby_riders`, danger-tinted when > 0), Assigned (`assigned_orders`). Tapping a tile sets the matching filter (Ready→all, No rider→needsAction, Assigned→assigned).
  4. Filter chips (`ChoiceChip`s): All · Needs action · Awaiting · Assigned — each with a count.
  5. List of `DispatchOrderCard`s from `state.visibleOrders`.
- States:
  - first load → `CardShimmer(type: 'order')` ×6 and shimmer tiles.
  - first-load error → `EmptyStateWidget` with the error text and a "Retry" action → `load()`.
  - empty `orders` → `EmptyStateWidget` "No orders waiting for dispatch" / "Bagged orders will appear here while riders are being assigned." with "Refresh".
  - empty for the current filter → small inline text "No orders in this filter" + "Show all" text button.
- Permission: page requires `AppPermissions.orderView`. If the user lacks it show the same "no permission" pattern used elsewhere in the app.

### 4.3 `DispatchOrderCard`
Bordered card (danger-coloured border when `noNearbyRiders`). Contents:
- Row: `#{order_number}` (bold, ellipsis) · `DispatchStatusBadge`.
- `Icons.storefront_outlined` + `pickup` · `Icons.qr_code_2` + `bag_barcode`.
- Rider line, by status:
  - `awaitingRiderAcceptance` → `Icons.person_outline` + "Offered to {delivery_boy_name}" (fallback "Offered to rider #{delivery_boy_id}").
  - `riderAssigned` → "Rider: {delivery_boy_name}".
  - `noNearbyRiders` / `waitingForDispatch` → "{nearby_available_riders} riders nearby" (pluralised).
  - `sellerSelfDelivery` → "You're responsible for delivering this order. Completing it in the app isn't available yet." (muted info line, no buttons — see §2.2).
- Relative `created_at` ("4 min ago").
- Action row only when `status.canSelfDeliver` **and** user has `AppPermissions.orderUpdateStatus`:
  - `noNearbyRiders` → filled primary button "Deliver myself".
  - `waitingForDispatch` / `awaitingRiderAcceptance` → outlined button "Deliver myself".
  - While `pendingSelfDeliver.contains(orderId)` → button shows a small `CustomLoadingIndicator` and is non-interactive.
- Tapping the card body: if the order can be found in `OrdersBloc.state.items` by `orderNumber`, push `AppRoutes.orderDetails` with that `sellerOrderId`; otherwise do nothing (no new endpoint).

### 4.4 `SelfDeliverSheet` (confirm)
Modal bottom sheet (or `showAppAlertDialog` if that is the app's convention for confirms — check `order_dialogs.dart` and match it):
- Title "Deliver this order yourself?"
- Subtitle `#{order_number} · {bag_barcode}`.
- If `status == awaitingRiderAcceptance` → warning box: "{delivery_boy_name} has a pending offer for this order. It will be cancelled and you'll be responsible for delivery."
- Else → info text: "This order will stop being offered to riders and you'll be responsible for delivery."
- Buttons: "Cancel" / "Confirm".
- On confirm: `if (!await DemoGuard.shouldProceed(context)) return;` → `cubit.selfDeliver(orderId)` → `showCustomSnackbar(message: result.message, isError: !result.isSuccess)`.

### 4.5 `DispatchStatusBadge`
Pill like `rider_status_badge.dart`. Labels (l10n): "No nearby riders", "Waiting for dispatch", "Awaiting rider", "Rider assigned", "Self delivery", unknown → humanised raw string.

### 4.6 Orders page add-ons (`lib/screen/order_page/view/order_page.dart`)
Minimal, non-invasive changes:
1. Polling ownership: in `_OrderPageState.initState` call `context.read<DispatchCubit>().startPolling()` (and `load()` if dashboard is null); add `WidgetsBindingObserver` to stop on pause / start on resume; stop in `dispose`. Only do this if the user has `AppPermissions.orderView`.
2. Above the `TabBar`, a `BlocBuilder<DispatchCubit, DispatchState>` that shows `DispatchAlertBanner` (compact variant) when `summary.hasAlert`; tap → `context.pushNamed(AppRoutes.dispatchCenter)`.
3. An entry point to the Dispatch center that is always visible (not just when alerting): a header button with `Icons.delivery_dining_outlined` and a small red count badge = `no_nearby_riders` (hidden when 0). Put it in the `CustomScaffold` actions if supported; otherwise next to the order-count text row (`"$total Orders"`) as a trailing `TextButton.icon("Dispatch")`.
4. On each order card, when a `DispatchOrder` with the same `order_number` exists in the dashboard, show a small `DispatchStatusBadge` under the existing status. Do this by passing an extra optional key in the `data` map to `CustomCard` (e.g. `'dispatch_status': DispatchOrder?`) and rendering it in `order_card.dart` only when present — do not change behaviour for cards without it. Build a `Map<String, DispatchOrder>` by `orderNumber` once per build, not per item.
5. Do not change the existing accept/reject/scan logic.

### 4.6a `RiderAvailabilitySection` (on the Dispatch center, between the summary row and the filter chips)
- Header row: "Riders near your stores" + `lastUpdated` caption + expand/collapse chevron (`toggleExpanded`).
- Three compact tiles: Active (`active_riders`), Available nearby (`available_riders_in_radius`, success-tinted when > 0, danger-tinted when 0 and the dispatch summary has `no_nearby_riders > 0`), Offline (`inactive_riders`).
- When expanded, a list of `RiderAvailabilityTile`s (not a wide table — the app is mobile-first). Each tile: name, `delivery_zone`, a status pill (green "Available" when `is_available_in_radius`, otherwise the `unavailable_reason` label from §2.3), distance ("84 m from store" when `nearest_pickup_distance_m` is not null), and location freshness ("Location 18s ago" from `location_age_seconds`; use minutes when ≥ 60).
- Empty `riders` → "No riders found for your stores and delivery zones."
- Hide the whole section when `isForbidden`.
- Polling: `startPolling()` when the Dispatch center opens / app resumes, `stopPolling()` when it closes / app pauses. Do **not** poll availability from the Orders page.
- Do not show coordinates or a map.

### 4.7 Home page (optional, only if trivial)
If `lib/screen/home_page/view/home_page.dart` already has an alert/notice area, show the same compact `DispatchAlertBanner` there when `hasAlert`. Skip if it requires restructuring.

---

## 5. Localization keys (add to all three ARB files)

`dispatchCenter`, `dispatchAutoRefresh` ("Updated {time} · auto-refresh every 15s", placeholder `time`), `dispatchNoRiderAlertTitle` (plural on `count`: "{count} order has no nearby rider" / "{count} orders have no nearby rider"), `dispatchNoRiderAlertBody`, `dispatchReady`, `dispatchNoRider`, `dispatchAssigned`, `dispatchFilterAll`, `dispatchFilterNeedsAction`, `dispatchFilterAwaiting`, `dispatchFilterAssigned`, `dispatchStatusNoNearbyRiders`, `dispatchStatusWaitingForDispatch`, `dispatchStatusAwaitingRider`, `dispatchStatusRiderAssigned`, `dispatchStatusSelfDelivery`, `dispatchOfferedTo` (placeholder `name`), `dispatchRiderName` (placeholder `name`), `dispatchNearbyRiders` (plural on `count`), `dispatchDeliverMyself`, `dispatchSelfDeliverTitle`, `dispatchSelfDeliverPendingOffer` (placeholder `name`), `dispatchSelfDeliverInfo`, `dispatchSelfDeliveryInfo`, `dispatchRidersNearStores`, `dispatchActiveRiders`, `dispatchAvailableNearby`, `dispatchOfflineRiders`, `dispatchRiderAvailable`, `dispatchReasonInactive`, `dispatchReasonNotVerified`, `dispatchReasonNoFcmToken`, `dispatchReasonLocationStale`, `dispatchReasonNoPickupStore`, `dispatchReasonOutsideRadius`, `dispatchReasonPendingOffer`, `dispatchReasonActiveDelivery`, `dispatchDistanceFromStore` (placeholder `meters`), `dispatchLocationAge` (placeholder `age`), `dispatchNoRidersFound`, `dispatchEmptyTitle`, `dispatchEmptyBody`, `dispatchEmptyFilter`, `dispatchShowAll`, `dispatchMinutesAgo` etc. only if no relative-time helper exists. Reuse existing keys for "Cancel", "Confirm", "Retry", "Refresh".

Run `flutter gen-l10n` after editing.

---

## 6. Tests (`test/dispatch/`)

Follow `test/delivery_boys/repo_test.dart` (local `HttpServer`, override `ApiRoutes.dispatchDashboardApi` / point `ApiRoutes.ordersApi` at the server, restore in `tearDown`, `initTestHive`).

`model_test.dart`
- Parses the exact §2.1 sample: summary counts, both orders, nullable rider fields, lat/lng strings → doubles, `created_at` → DateTime.
- Unknown status → `DispatchStatus.unknown`, `rawStatus` preserved.
- Missing `summary` / `orders` → zero / empty, no throw.
- `canSelfDeliver` true only for the three allowed statuses.

`repo_test.dart`
- `getDashboard` hits `GET .../api/seller/orders/dispatch-dashboard`.
- `markSelfDelivery(183)` hits `POST .../api/seller/orders/183/self-deliver`, sets `lastMessage`.
- `409` and `404` → throws `ApiException` with the server message and status code.

`availability_test.dart`
- Parses the exact §2.3 sample; nullable fields; every `unavailable_reason` value incl. `no_pickup_store`; unknown reason → `unknown` with raw kept.
- Repo hits `GET .../api/seller/orders/rider-availability`.
- Cubit: sort order; `403` → `isForbidden` and polling stopped; silent refresh error keeps old data; default poll interval is 30 s.

`cubit_test.dart` (use a fake `DispatchRepo` subclass)
- `load` → dashboard set, `lastUpdated` set.
- Silent refresh failure keeps previous data and no `error`.
- Filters produce the right `visibleOrders` and sort order.
- `selfDeliver` success → order becomes `sellerSelfDelivery`, `noNearbyRiders` decremented, result success with message.
- `selfDeliver` 409 → order and summary restored, result failure with message.
- Duplicate `selfDeliver` while pending is ignored.
- `startPolling` with a short `pollInterval` triggers refreshes; `stopPolling` / `close` / `reset` cancel the timer (use `fake_async` if it's already a dev dependency, otherwise short real durations).

---

## 7. Acceptance checklist

- [ ] Only `GET /api/seller/orders/dispatch-dashboard`, `POST /api/seller/orders/{order_id}/self-deliver` and `GET /api/seller/orders/rider-availability` are called. No other new endpoints.
- [ ] No "Mark delivered" action anywhere; the seller status API is never used to simulate delivery; `seller_self_delivery` cards show the "completion not available yet" info line.
- [ ] No new FCM handlers (no seller dispatch push exists).
- [ ] Rider availability refreshes every 30 s only while the Dispatch center is visible; all 8 `unavailable_reason` values labelled; hidden on `403`; no coordinates shown.
- [ ] Dashboard polls every 15 s while the Orders page or Dispatch center is visible and the app is foregrounded; stops when paused and on logout/reset; no leaked timers.
- [ ] Red alert appears whenever `summary.no_nearby_riders > 0`, on the Orders page and Dispatch center, and leads to the affected orders.
- [ ] "Deliver myself" shown only for `no_nearby_riders`, `waiting_for_dispatch`, `awaiting_rider_acceptance`, and only with `order.update_status` permission; never for `rider_assigned` / `seller_self_delivery`.
- [ ] Confirm sheet warns about the pending rider offer for `awaiting_rider_acceptance`.
- [ ] 200 / 409 / 404 handled exactly as §2.2 with server messages; optimistic change reverted on failure.
- [ ] `awaiting_rider_acceptance` shows the reserved rider and is never auto-cleared client-side.
- [ ] Unknown statuses render safely.
- [ ] All strings localised (en/hi/ar), `flutter gen-l10n` run.
- [ ] Existing order accept/reject/scan flow and Delivery Boys work unchanged.
- [ ] `flutter analyze` clean for new/changed files; `flutter test test/dispatch` passes.
