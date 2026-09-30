# Incoming order: accept → scan barcodes → prepare

Build spec for the seller app (Flutter, `hyper_local_seller`). It covers every screen, state, edge case and test for the new incoming-order flow.

> **For the implementing agent (Codex):** read the whole document before changing code. Section 12 lists what already exists in the working tree. Treat that code as a draft: check it against this spec and fix or replace anything that doesn't match. Don't commit unless you're asked to.

---

## 1. Summary

**Today:** a new order opens a blocking, ringing popup. Its one button, **"Accept and prepare order"**, sends `accept` and then `preparing` for every item, and the popup closes.

**New flow:**

1. The order arrives. The popup and ringing are **unchanged**.
2. The seller taps **Accept order**. Only the accept call is sent. The **popup stays open** and switches to a **scan checklist** of the order's items. The accept response includes a **`barcode` for every product**.
3. For each product, the seller either:
   - taps **Scan**, and the camera opens *inside the popup*. It detects the barcode, freezes, and shows the captured image with the extracted code, then the seller taps **✓**; or
   - taps the **keyboard icon** (left of Scan) and types the code by hand, then taps **✓**.
4. The app compares the code with the backend barcode **on the device**, with no API call.
   - **No match:** show an error, and the seller rescans.
   - **Match:** open the **quantity step**: `−` [number] `+`. The number is also a text field, so the seller can type 24 instead of tapping 24 times.
5. The quantity must **exactly equal** the ordered quantity. Only then does the product get its **✓ tick**.
6. The seller repeats this for every product.
7. When **all** products are ticked, **Mark as preparing** appears. Tapping it calls the preparing API, the popup closes, and the next queued order (if any) shows.

There's **no reject and no close** anywhere in the popup, same as today.

---

## 2. Existing code map (read these first)

| Area | File |
|---|---|
| Queue and business logic | `lib/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart` (+ `incoming_orders_state.dart`, `part of`) |
| Pending order model | `lib/screen/order_page/incoming_orders/model/pending_order_model.dart` |
| API calls for the popup | `lib/screen/order_page/incoming_orders/repo/pending_orders_repo.dart` |
| Popup UI (sits in `MaterialApp.builder`, above every route) | `lib/screen/order_page/incoming_orders/view/incoming_order_overlay.dart` |
| Ringing, 5 s polling, Back-button blocking, app lifecycle | `lib/screen/order_page/incoming_orders/view/incoming_orders_controller.dart` |
| Count-up timer ring | `lib/screen/order_page/incoming_orders/widgets/response_timer.dart` |
| Ringtone | `lib/service/order_ringtone_service.dart` |
| Push handling (foreground push → `IncomingOrdersCubit.fetch()`) | `lib/service/notification_service.dart`, `lib/main.dart` (background handler) |
| Wiring | `lib/main.dart`: `PendingOrdersRepo` repository provider, `IncomingOrdersCubit` bloc provider, `IncomingOrdersController` wraps `AppWrapper`, and `IncomingOrderOverlay` in `MaterialApp.router(builder:)` |
| Logout clearing | `lib/service/master_api_service.dart` calls `IncomingOrdersCubit.clear()` |
| Tests | `test/incoming_orders/` (`helpers.dart` has `FakePendingOrdersRepo` and `orderJson()`), plus `device_preview.dart` for on-device preview with fake data |

Things about the current code that must keep working:

- **Queue source:** `fetch()` calls `GET {ordersApi}/pending-regular?order_mode=regular` and `...?order_mode=wholesale&popup=1` in parallel. The results are merged and de-duplicated by `seller_order_id`, oldest first. Regular orders sort by `created_at`; wholesale orders sort by when they were first shown (`shownAt`). The card currently on screen is **pinned** to the top.
- **Fetch gating:** fetches are coalesced (`_refetchQueued`) and paused while a network action runs. If one endpoint fails, the last list for that mode is kept.
- **Partial retry:** `_doneSteps[orderItemId]` records which accept/preparing calls already succeeded, so a retry only resends the missing ones.
- **Blocking:** while `hasPending`, the popup covers the app, Back is swallowed, and a `NavigationNotification` trick handles Android predictive back.

---

## 3. API contract

### 3.1 What exists now (use these until the new APIs are ready)

| Purpose | Call | Notes |
|---|---|---|
| Pending list | `GET {ordersApi}/pending-regular?order_mode=regular` and `...&order_mode=wholesale&popup=1` | Unchanged |
| Accept one item | `POST {ordersApi}/{order_item_id}/accept` body `{}` | Called for each item |
| Preparing one item | `POST {ordersApi}/{order_item_id}/preparing` body `{}` | Called for each item |
| Order details | `GET {ordersApi}/{seller_order_id}` | `data.items[].orderItem.{id,status}`. Used only to check restored sessions (§5.6) |

`{ordersApi}` is `ApiRoutes.ordersApi`.

### 3.2 What the backend will provide (not live yet)

The backend will give us **two endpoints**:

1. **Accept.** Accepts the order and **returns the order details**: product details, amount, quantity (same as today), plus a **`barcode` field on every product**.
2. **Preparing.** Moves the order to preparing.

URLs, methods, request bodies and the exact response JSON are **unknown**. Keep all of that behind two repo methods so swapping them in is a one-file change:

```dart
// pending_orders_repo.dart
Future<PendingOrder> acceptOrder(
  PendingOrder order, {
  Set<int> skipItemIds = const {},            // already accepted in an earlier, partly failed try
  void Function(int orderItemId)? onItemAccepted,
});

Future<void> markOrderPreparing(
  PendingOrder order, {
  Set<int> skipItemIds = const {},
  void Function(int orderItemId)? onItemDone,
});
```

- **For now:** `acceptOrder` loops `acceptItem(id)` over the items (skipping `skipItemIds`), then returns the order with **dummy barcodes**. `markOrderPreparing` loops `markItemPreparing(id)`.
- **Keep `acceptItem(int)` and `markItemPreparing(int)` as separate public methods.** The test fake overrides them.
- **Later:** `acceptOrder` calls the new endpoint and parses its response into a `PendingOrder` whose items carry `barcode`. Mark both methods `// TODO(api):`.

### 3.3 Dummy barcodes (until the API is ready)

- If an item has no `barcode` from the server, item N of the order (1-based position in `items`) gets the barcode **`A<N>`**: `A1`, `A2`, `A3`, and so on.
- If the server already sends `barcode`, use it.
- Put this in a single private function, `_withDummyBarcodes(order)`, marked `// TODO(api): remove`.
- In **debug builds only** (`kDebugMode`), the checklist shows the expected code next to each item (`Qty 3 · Code A1`) so testers can type it. **Release builds never show the expected barcode**, because that would defeat the check.

---

## 4. Data model

`PendingOrderItem` (in `pending_order_model.dart`):

- Add `final String? barcode;` (optional constructor parameter). Parse it with `_nonEmpty(json['barcode'])`.
- Add it to `copyWith({String? image, String? barcode})` and to `props`.
- Add `bool matchesCode(String code)`: trim both sides and compare **case-insensitively**. Return false if `barcode` is null or empty.
- Add `Map<String, dynamic> toJson()`, the inverse of `fromJson` (keys `order_item_id, product, variant, image, quantity, subtotal, barcode`).

`PendingOrder`:

- Add `Map<String, dynamic> toJson()`, the inverse of `fromJson`: `seller_order_id, order_id, order_number, order_mode (name), created_at (ISO), customer{name,phone,address}, payment_method, total, delivery, items[]`.
- **Requirement:** `PendingOrder.fromJson(o.toJson()) == o`. Test this.

---

## 5. Business logic (cubit and state)

### 5.1 State (`IncomingOrdersState`)

| Field | Meaning |
|---|---|
| `orders` | The queue. `orders.first` is the card on screen |
| `shownAt` | First time each order showed in the popup (unchanged) |
| `acceptedOrderIds: Set<int>` | Orders accepted and now being scanned |
| `verifiedItemIds: Set<int>` | `order_item_id`s whose barcode **and** quantity passed |
| `acceptingOrderId`, `preparingOrderId` | The network action in progress, if any |
| `failedOrderId`, `errorMessage` | The last accept or preparing failure |

Getters:

- `hasPending`: the queue isn't empty. **Drives the popup and Back-blocking.**
- `hasUnaccepted`: some order in the queue isn't in `acceptedOrderIds`. **Drives ringing.**
- `isBusy`: accepting or preparing.
- `isAccepted(order)`, `isVerified(item)`, `verifiedCount(order)`, `isFullyVerified(order)`.

`copyWith` must support clearing `acceptingOrderId`, `preparingOrderId`, and the error fields. Add everything to `props`.

### 5.2 Cubit API

```dart
Future<void> fetch();                                           // unchanged contract; first call also restores (§5.6)
Future<bool> accept(PendingOrder order);                        // accept only, no preparing
(ScanMatch, PendingOrderItem?) matchCode(PendingOrder order, String code);
bool confirmQuantity(PendingOrderItem item, int quantity);      // true = verified
Future<bool> markPreparing(PendingOrder order);                 // only when isFullyVerified
void clear();                                                   // logout
enum ScanMatch { matched, alreadyVerified, notInOrder }
```

### 5.3 Rules

1. **accept(order)**
   - If `isBusy`, return false. If the order is already accepted, return true.
   - Emit `acceptingOrderId`, then call `repo.acceptOrder` with `skipItemIds` taken from `_doneSteps`.
   - As soon as the **first** item is accepted, put the order in `_held`. From then on it stays in the queue even if the pending endpoint drops it.
   - **On success:** replace `_held[id]` with the returned order (which has barcodes), add the id to `acceptedOrderIds`, clear `acceptingOrderId`, call `_publish()`, save the session (§5.5) and resume fetching.
   - **On failure:** set `failedOrderId` and `errorMessage` and clear `acceptingOrderId`. The card stays on screen with **"Retry accept"**. Resume fetching.
2. **matchCode(order, code)**
   - Use the order as it appears in `state.orders`, i.e. the held copy with barcodes.
   - Return `matched` for the first **unverified** item whose barcode matches.
   - Otherwise return `alreadyVerified` if a verified item matches.
   - Otherwise return `notInOrder`.
   - If two lines share a barcode, each is verified on its own: the first scan picks the first unverified line.
3. **confirmQuantity(item, qty)**
   - Returns true only if `qty == item.quantity`. It then adds the item to `verifiedItemIds` and saves the session.
   - Returns false otherwise, and nothing changes.
4. **markPreparing(order)**
   - Return false if `isBusy` or the order isn't fully verified.
   - Emit `preparingOrderId`, then call `repo.markOrderPreparing` with `skipItemIds` taken from `_doneSteps`.
   - **On success:** remove the items' `_doneSteps`, add the order to `_handled`, remove it from `_held`, `acceptedOrderIds` and its items from `verifiedItemIds`, publish, save and resume fetching.
   - **On failure:** set the error. The panel shows **"Retry preparing"**, and a retry only resends the missing items.
5. **Queue order in `_publish()`**
   - Merge the server lists, drop `_handled`, then overlay `_held` (so the held copy with barcodes wins).
   - Sort **accepted orders first**, then by the existing oldest-first rule.
   - Keep the pin: `acceptingOrderId ?? preparingOrderId ?? current first`.
6. **Fetching** is skipped and queued while `isBusy` (currently it checks only `acceptingOrderId`).
7. **Ringing** (in `incoming_orders_controller.dart`): ring while `hasUnaccepted`, not `hasPending`. The `listenWhen` compares `hasUnaccepted`. The resume handler also restarts the ring only if `hasUnaccepted`. So:
   - Accepting the only order **stops** the ringing while the seller scans.
   - A **new order arriving during scanning rings again**. It waits behind the scanning card, and the waiting badge shows "2 orders waiting".
8. **Back button and predictive back:** unchanged. The popup is up while `hasPending`, which includes scanning.

### 5.4 Scan-state lifetime

- Scan progress (verified items) belongs to the cubit, not the widget.
- Leaving the popup is impossible, but the app can be backgrounded or killed. Progress must survive both.

### 5.5 On-device persistence (`ScanSessionStore`)

The pending endpoint no longer lists an order once it's accepted. **Without persistence, killing the app mid-scan loses the popup**, and the order is stuck in "accepted" with no popup.

- **File:** `repo/scan_session_store.dart`.
- **Storage:** a Hive box `incomingOrderScans`, key `sessions`, holding a JSON string: `[{order: PendingOrder.toJson(), verified: [orderItemId...]}]`.
- **API:** `load()`, `save(Iterable<ScanSession>)`, `clear()`. Every method catches its own errors and logs them, and never throws.
- **Wiring:** inject it into the cubit (`IncomingOrdersCubit(repo, {ScanSessionStore? store})`) so tests can pass an in-memory fake.
- **When to save:** after a successful accept, after every `confirmQuantity` that returns true, and after a successful preparing (which removes the order).
- **Logout:** `clear()` wipes it.

### 5.6 Restoring after an app restart

On the first `fetch()` after the cubit is created (or after logout and login), load the saved sessions. For each one:

- Call `repo.itemStatuses(sellerOrderId)` (`GET /orders/{id}`, which maps `orderItem.id ?? id` to its lower-cased `status`).
- If the call succeeds and returns items, but **none** of the order's items is `accepted`, the order was prepared, rejected or cancelled elsewhere. **Drop it.**
- If the call fails (offline), **keep** the order.
- For each kept order: put it in `_held`, add it to `acceptedOrderIds`, add its verified items to `verifiedItemIds`, and mark `_Step.accept` done for every item. Mark `_Step.preparing` done for items the server reports as `preparing`.
- Save again afterwards, so dropped sessions are removed.

---

## 6. UI spec (every screen)

General rules:

- Everything lives **inside the existing popup card**. Don't push routes or open `showDialog`: the popup sits above the Navigator.
- **Card shell:** 22 px radius. Background white in light mode, `AppColors.darkSubCategoryCardColor` in dark. Header background `AppColors.primaryColor` with white text.
- **Bottom bar:** background `AppColors.mainLightContainerBgColor` in light mode, `darkProductCardColor` in dark, with a top border `AppColors.lightOutline` / `darkOutline`.
- **Size:** max width 480. Content scrolls; the header and bottom bar don't. Buttons are 54 px tall with 14 px radius.
- **Wrap the barrier** (`_OrderStackBarrier`) in `Overlay.wrap(...)`. Without it, `TextField` crashes ("No Overlay widget found") because this widget is above the Navigator's Overlay.
- **Keyboard:** pad the barrier bottom with `MediaQuery.viewInsetsOf(context).bottom` so fields stay above the keyboard.
- **Strings:** the popup's strings are hard-coded English today. Keep them hard-coded, or move all of them to l10n, but be consistent.
- **Transition:** the `AnimatedSwitcher` child key changes from `ValueKey(id)` (the incoming card) to `ValueKey('scan-$id')` (the scan panel), so the switch fades.

The scan panel is a `StatefulWidget` (`widgets/order_scan_panel.dart`) with a local mode: `checklist | camera | manual | review | quantity`. Its header is shared by every mode.

### S0: Shared scan header

- Small caps line: `ORDER #<orderNumber> · ACCEPTED`
- Title, which depends on the mode: `Scan items` / `Scan barcode` / `Enter barcode` / `Check the code` / `Confirm quantity`
- Right of the title: `<verified> of <total>`
- Below it: a 6 px `LinearProgressIndicator` showing `verified/total`, in green on a translucent white track.

### S1: Incoming order card (existing card, small changes)

- **Header subtitle:**
  - Regular orders: `Review the details and accept to start packing.`
  - Wholesale orders: `Delivery slot ends within 30 minutes. Accept to start packing.`
- **Button:** `Accept order`. It shows a spinner while accepting, and on error the text `Couldn't accept this order. <error>` above it with the button reading `Retry accept`.
- Everything else is unchanged: timer, summary tiles, item rows, waiting badge, stack edges.
- **After a successful accept:** refresh `OrdersBloc(RefreshOrders)`, `NotificationListBloc(FetchUnreadCount)` and `HomePageBloc(FetchHomePageData(storeId))`, as today. Keep this in a shared helper `_refreshOrderScreens(context)`.

### S2: Checklist (the default mode after accept)

- **Body:** one row per item, in server order. Each row is a rounded 14 px container with:
  - a leading status icon: `Icons.check_circle` in green when verified, `Icons.radio_button_unchecked` in the hint colour when not
  - a 44×44 thumbnail (network image or placeholder)
  - the product name (max 2 lines)
  - a subline: `variant · Qty N`, plus `· Code A1` in debug builds
  - when verified: a trailing `N/N` in green, and the row tinted green with a green border
- **Bottom bar while not all items are verified:** `[⌨ 54×54 outlined, tooltip "Enter code manually"]` then `[Scan item]` (a filled primary button with a `qr_code_scanner` icon). The Scan button reads `Scan next item` once at least one item is verified.
- **Bottom bar once all items are verified:** only a green `Mark as preparing` button (`soup_kitchen_outlined` icon).
  - While the call runs: a spinner, and the button is disabled.
  - On error: the text `Couldn't mark as preparing. <error>` in red above it, and the button reads `Retry preparing`.
  - On success: call `_refreshOrderScreens`. The cubit removes the order and the next one appears.

### S3: Camera

- **Body:** a 280 px tall rounded preview (`MobileScanner`, from `mobile_scanner` ^7) with:
  - a white 240×130 target frame in the centre (inside `IgnorePointer`)
  - a top-right `IconButton.filledTonal` torch toggle (tooltip `Flashlight`)
  - below the preview: `Point the camera at the product's barcode.`
- **Controller:** `MobileScannerController(returnImage: true)`. Create it when entering camera mode, and dispose it when leaving camera mode and in `dispose()`.
- **Detection:** take the first barcode with a non-empty trimmed `rawValue`. Ignore it if the mode is no longer camera. Then:
  1. `HapticFeedback.mediumImpact()`
  2. store the code and `capture.image` (the frozen frame)
  3. go to review mode, which disposes the camera
- **Bottom bar:** `[⌨]` and `[Back to items]` (outlined).

### S3e: Camera error (the scanner's `errorBuilder`)

- **Permission denied** (`MobileScannerErrorCode.permissionDenied`):
  - Black box with a `no_photography_outlined` icon and the text `Camera access is off. Allow it in Settings, or enter the code manually.`
  - Buttons `Open settings` (`AppSettings.openAppSettings()`, package `app_settings` is already a dependency) and `Enter manually`.
- **Any other error:** the text `The camera isn't available. Enter the code manually.` and the `Enter manually` button.

### S4: Review the scanned code

- **Body:**
  - a 200 px black box with the captured image (`Image.memory`, `BoxFit.contain`), or a `qr_code_2` icon if there's no image
  - a code box: `Detected code` on the left, the code on the right in bold monospace (`SelectableText`)
  - if there's an error, red text
  - a hint: `Tap the tick to check it against the order.`
- **Bottom bar:** `[Retake]` (outlined, back to the camera) and `[✓ Confirm]` (green). Confirm runs `checkCode` (§6.1).

### S5: Manual entry

- **Body:**
  - the text `Type the code printed under the product's barcode.`
  - a `TextField`: `autofocus`, `TextInputAction.done`, `onSubmitted` runs checkCode, label `Barcode`, prefix icon `keyboard_outlined`, error shown through `errorText`, rounded outline border
  - the field clears whenever manual mode opens, and its error clears when the text changes
- **Bottom bar:** `[Scan instead]` (outlined, goes to the camera) and `[✓ Confirm]` (green).

### S6: Quantity

- **Body:**
  - the product row (thumbnail, name, variant)
  - `✓ Barcode matched` in green
  - `Ordered quantity: N` (centred, bold)
  - the stepper: `IconButton.outlined(remove)`, then a 96 px wide centred numeric `TextField` (digits only, max 5 chars, large bold text), then `IconButton.outlined(add)`
  - the hint `Tap the number to type it.`
  - an error line in red when needed
- **Starting value:** `1`.
- **− / +:** change the number by 1 within the range 1..99999 and clear the error. The field can be typed into directly, and submitting it confirms.
- **Bottom bar:** `[Cancel]` (outlined, back to the checklist; the item stays unverified) and `[✓ Confirm quantity]` (green, flex 2).
- **Confirm:**
  - If the value is empty or less than 1: error `Enter the quantity`.
  - Otherwise call `cubit.confirmQuantity(item, qty)`.
    - `false`: error `Quantity doesn't match the order (N). Count again.`
    - `true`: `HapticFeedback.lightImpact()`, then back to the **checklist**, where the tick is now visible.

### 6.1 checkCode(code)

This is shared by review and manual entry.

- If the code is empty: error `Enter a barcode`.
- Otherwise call `cubit.matchCode(order, code)`:
  - `matched`: remember the item, set the quantity to `1`, go to the quantity step.
  - `alreadyVerified`: error `<product> is already verified. Scan the next item.`
  - `notInOrder`: error `This barcode isn't in this order. Check the product and try again.`

---

## 7. Edge cases (expected behaviour)

| # | Case | Expected |
|---|---|---|
| E1 | Accept fails partway (item 2 of 3) | Error shown, "Retry accept". The retry sends accept only for items 2 and 3. The order stays on screen even if the server's pending list drops it |
| E2 | Accept is double-tapped | The second tap is ignored (`isBusy`). Only one set of calls is sent |
| E3 | Wrong barcode scanned | Error, and no quantity step. Retake or manual entry still work |
| E4 | Barcode of an already-ticked item | The "already verified" error |
| E5 | Same barcode on two lines | The first scan verifies line 1, the second scan verifies line 2 |
| E6 | Code differs only in case or spaces (`" a1 "` vs `A1`) | Matches |
| E7 | Quantity lower or higher than ordered | Mismatch error. The item stays unticked, and the seller can re-enter or cancel |
| E8 | Quantity field empty or 0 | `Enter the quantity` |
| E9 | Preparing fails partway | Error, "Retry preparing". The retry sends only the missing items. Ticks are kept |
| E10 | App backgrounded mid-scan | Progress is kept. The camera pauses and resumes (`MobileScanner` handles its lifecycle) |
| E11 | App killed mid-scan, then reopened | The popup comes back in scan mode with the same ticks (§5.6) |
| E12 | Restored order was prepared or cancelled elsewhere meanwhile | It's dropped silently on restore |
| E13 | Restored while offline | It's kept, and scanning can continue. Preparing needs the network (error and retry) |
| E14 | New order arrives while scanning | It rings, the badge shows "2 orders waiting", and the scanning card stays on top. After preparing, the new order shows as a normal incoming card |
| E15 | Several accepted orders (e.g. restored and new) | Accepted ones come first. Each is scanned and prepared in turn |
| E16 | Camera permission denied or permanently denied | The error box, with Open settings and Enter manually |
| E17 | Device has no camera (iOS simulator, some emulators) | The error box. Manual entry works |
| E18 | Keyboard open on a small screen | The card shifts above the keyboard and content scrolls. No overflow at 320×568 with text scale 1.3 |
| E19 | Logout mid-scan | The queue, `_held` and the stored sessions are cleared. The popup closes and ringing stops |
| E20 | Android Back during scan (including predictive back) | Swallowed. The app doesn't close |
| E21 | Order with 1 item, or with 20 items | Works. The list scrolls, and the header and bottom bar stay fixed |
| E22 | Item without a barcode after the real API is live | Treat it as a backend bug. For now the dummy fallback hides it. When the dummy code is removed, block with the error `Barcode missing for <product>. Contact support.` (Decide this with the backend; see §11) |

---

## 8. Platform setup

- **pubspec:** add `mobile_scanner: ^7.4.2` (already added in the working tree; run `flutter pub get`).
- **Android:** the plugin's manifest adds `CAMERA`, merged automatically. Nothing else is needed. Check that `minSdk` is at least 23.
- **iOS:** update `ios/Runner/Info.plist` `NSCameraUsageDescription` to: `This app uses the camera to scan product barcodes when packing orders, and to capture product images and videos.` The Podfile platform is already iOS 15. Run `cd ios && pod install`.
- **No other screens change.**
- **Open decision:** the orders list (`order_page.dart` / `order_card.dart`) and order details page still have their own **Accept** and **Mark as Preparing** buttons, which skip scanning. Leave them as they are unless the product owner says otherwise, and mention it in the final report.

---

## 9. Tests

Run everything with `flutter test test/incoming_orders`. Analyzer: `flutter analyze lib test` must report no new issues (one `unused_element_parameter` warning in `lib/bloc/pagination/pagination_controller.dart` already existed).

### 9.1 Test helpers (`test/incoming_orders/helpers.dart`)

- `FakePendingOrdersRepo`:
  - keep its overrides of `acceptItem` and `markItemPreparing` (they record `accept <id>` / `preparing <id>` in `calls`, with `failAcceptOnce`, `failPreparingOnce` and `acceptGate`)
  - add a `preparingGate`
  - add `Map<int, Map<int,String>> statuses` plus `Set<int> failStatusFor`, and override `itemStatuses`
- Add `FakeScanSessionStore` (in memory, records saves). **Always pass it to the cubit in tests.** Otherwise the real Hive box leaks sessions between tests.
- `orderJson()`: add an optional per-item `barcode` and `quantity`.

### 9.2 Existing tests that must change

| File / test | Change |
|---|---|
| `cubit_test` › accept › "accept then preparing for every item, in order" | Accept now sends **only** `accept` calls. Add a separate test for preparing |
| `cubit_test` › "accepted order leaves the queue and never comes back" | After accept, the order **stays** (scanning). It leaves only after `markPreparing` |
| `cubit_test` › "failure shows an error; retry skips calls that succeeded" | Keep it for accept, and add the same test for preparing |
| `cubit_test` › "works through a queue of six orders one at a time" | Each order: accept → verify all items → markPreparing |
| `cubit_test` › "logout clears the queue and accepted history" | Also expect `FakeScanSessionStore.clear` and empty accepted/verified sets |
| `overlay_test` › "ringtone loops while pending and stops after the last accept" | Ringing stops **after accept** (no unaccepted orders left), even though the popup is still up |
| `overlay_test` › "accept moves to the next order in the queue" | Accept shows the **scan panel** for the same order. The next order appears after Mark as preparing |
| `overlay_test` › "error then retry", "shows a spinner while accepting" | The button text is `Accept order` / `Retry accept` |
| `overlay_test` › overflow sizes loop | Also run it on the scan panel: checklist, manual (with keyboard insets) and quantity |
| `device_preview.dart` | Works with the new flow (the fake repo gives dummy barcodes through the real `acceptOrder`) |

### 9.3 New unit tests (cubit, model, repo)

- **Model:** `barcode` parsing; `toJson`/`fromJson` round trip (order and item); `matchesCode` for case, spaces, null and empty.
- **Repo** (`repo_http_test.dart`, real `ApiBaseHelper` against a local `HttpServer`):
  - `acceptOrder` posts `/orders/{id}/accept` for each item, respects `skipItemIds`, and returns barcodes `A1..An`
  - it keeps a barcode the server already sent
  - `markOrderPreparing` posts `/preparing` for each item
  - `itemStatuses` parses `data.items[].orderItem.{id,status}`
- **Cubit:**
  - `matchCode`: matched, alreadyVerified, notInOrder, duplicate-barcode lines (E5)
  - `confirmQuantity`: exact match gives true and verifies; a different number gives false and nothing changes
  - `markPreparing`: refused until fully verified; while busy, a second call is ignored; partial failure then retry (E9)
  - `hasUnaccepted`: true before accept, false after, true again when a new order arrives during scanning (E14)
  - **queue order:** an accepted order stays first when an older unaccepted order appears
  - **persistence:** saves after accept, after each verify and after preparing
  - **restore:** keeps the order and its ticks (E11); drops it when no item is `accepted` (E12); keeps it when the status call fails (E13); marks preparing done for items already `preparing`
  - **fetch** is deferred while `preparingOrderId` is set
  - **logout** clears everything (E19)

### 9.4 Widget tests (scan panel inside the overlay)

The camera can't run in widget tests. Add an **optional test seam** to `OrderScanPanel`: `@visibleForTesting final Widget Function(void Function(String code, Uint8List? image) onCode)? cameraBuilder`. In tests it renders a button that "detects" a code. In production it defaults to `MobileScanner`.

Cover:

- Accept → the checklist shows `Scan items`, `0 of N` and all rows unticked.
- Manual: ⌨ → type `A1` → Confirm → the quantity step shows `Ordered quantity: 3`.
  - `+` / `−` change the value, and typing `24` works.
  - A wrong quantity shows the mismatch error.
  - The correct quantity returns to the checklist with the row ticked and `1 of N`.
- Manual with a wrong code shows the not-in-order error. Manual with an empty code shows `Enter a barcode`.
- Camera seam: detect `A2` → review shows `Detected code A2` → ✓ → quantity step. **Retake** returns to the camera.
- Already-verified code shows its error.
- All items verified → only `Mark as preparing` is visible. Tap it → spinner → the next order's incoming card appears.
- Preparing error → error text and `Retry preparing`.
- A `TextField` in the popup doesn't throw (proves `Overlay.wrap` is in place).
- Back is swallowed during scanning.
- No overflow for the checklist with 10 items, manual mode with keyboard insets (`tester.view.viewInsets`), and the quantity step, at 320×568 ×1.3 text scale and 412×915.

### 9.5 Manual test on the **Pixel 10 Pro emulator** (required)

The AVD id is **`Pixel_10_Pro`**. The SDK tools aren't on PATH; use the full paths:

```bash
export ANDROID_SDK=~/Library/Android/sdk
$ANDROID_SDK/emulator/emulator -list-avds            # expect Pixel_10_Pro
$ANDROID_SDK/emulator/emulator -avd Pixel_10_Pro -camera-back virtualscene   # run in background
$ANDROID_SDK/platform-tools/adb devices              # wait for emulator-5554  device
$ANDROID_SDK/platform-tools/adb -s emulator-5554 emu avd name   # must print Pixel_10_Pro
```

If `flutter emulators --launch Pixel_10_Pro` exits with code 1, run the `emulator` binary directly as above to see the real error. It may already be running (check `adb devices`), or it may need `-no-snapshot-load` for a cold boot.

**Run options:**

- **Real backend:** `flutter run -d emulator-5554`, then log in as the seller. Place orders from the customer app. The user has already placed test orders, so the pending popup should appear on launch.
- **Fake data** (no backend needed): `flutter run -d emulator-5554 -t test/incoming_orders/device_preview.dart`.

**Camera on the emulator:**

- Start with `-camera-back virtualscene`.
- Generate Code-128 or QR images that encode `A1`…`A5`. Any offline generator works, e.g. a small Python `python-barcode`/`qrcode` script.
- Add them under **Extended controls → Camera → Virtual scene images** (wall/table poster), then walk up to them in the virtual scene. Alternatively, use `-camera-back webcam0` and hold a printed or on-screen barcode up to the Mac webcam.
- If the camera can't be driven, test detection through manual entry and note that in the report.

**Checklist to run, taking a screenshot of each step (`adb exec-out screencap -p > step.png`):**

1. The popup appears and rings for the existing orders. Back doesn't close it.
2. Accept → the checklist appears, and the ringing stops (if no other unaccepted order).
3. Scan (virtual scene) A1 → review screen with the image and `A1` → ✓ → quantity → correct quantity → ticked.
4. Manual `A2` with a wrong quantity → mismatch error, then the correct quantity → ticked.
5. Wrong code `ZZ9` → not-in-order error.
6. Deny the camera permission (`adb shell pm revoke com.nagpurmart.seller android.permission.CAMERA`, after checking the package id in `android/app/build.gradle*`) → error box, **Open settings**, **Enter manually**.
7. Kill the app mid-scan (`adb shell am force-stop <pkg>`), relaunch → scan mode is back with the same ticks.
8. Place another order during scanning → it rings, the badge shows 2, and the scanning card stays on top.
9. Finish all items → **Mark as preparing** → the order shows **Preparing** in the Orders tab. The next popup appears.
10. Airplane mode during Mark as preparing → error and **Retry preparing** → turn the network back on → retry succeeds.
11. Dark mode (`adb shell cmd uimode night yes`) → every screen is readable.
12. Keyboard open in manual and quantity modes → nothing hidden and no overflow stripes.

---

## 10. Acceptance criteria

- [ ] "Accept order" sends only the accept call and keeps the popup open in scan mode.
- [ ] Each item needs a matching barcode (camera or manual) **and** an exact quantity before it shows ✓.
- [ ] "Mark as preparing" appears only when every item is ✓, and it calls the preparing API.
- [ ] There's no way to dismiss the popup other than finishing the flow. Back is blocked.
- [ ] Ringing stops after accept and resumes only for new unaccepted orders.
- [ ] Scan progress survives app kill and relaunch; stale sessions are dropped.
- [ ] Partial failures on accept or preparing retry only the missing items.
- [ ] Dummy barcodes `A1..An` until the API is live, with the swap confined to `acceptOrder` / `markOrderPreparing` / `_withDummyBarcodes`.
- [ ] `flutter analyze` is clean (no new issues), and `flutter test test/incoming_orders` passes fully.
- [ ] Section 9.5 was run on **Pixel_10_Pro**, with screenshots and a short pass/fail list per step in the final report.

---

## 11. Open questions for the backend (don't block on these)

1. Accept endpoint URL, method, body and a sample response. Is it one call for the whole order or one per item?
2. Preparing endpoint URL and body. Should it receive the scanned codes or quantities for audit?
3. The barcode field's name and type. Can a product have more than one barcode (for example, several pack sizes)? What should happen for a product without a barcode?
4. Should `pending-regular` also return accepted-but-not-prepared orders? If yes, the restore logic in §5.6 becomes a backup.
5. Should the orders list and details page also require scanning before preparing (§8)?

---

## 12. Current state of the working tree (uncommitted draft)

A first implementation was written but **not fully tested**. The test run and the emulator run were interrupted. Files involved:

- `pubspec.yaml`, `pubspec.lock`: `mobile_scanner: ^7.4.2`
- `ios/Runner/Info.plist`: new camera text
- `model/pending_order_model.dart`: `barcode`, `toJson`, `matchesCode`
- `repo/pending_orders_repo.dart`: `acceptOrder`, `markOrderPreparing`, `itemStatuses`, `_withDummyBarcodes`; `acceptItem`/`markItemPreparing` kept
- `repo/scan_session_store.dart` (new)
- `cubit/incoming_orders_cubit.dart`, `cubit/incoming_orders_state.dart`: rewritten per §5
- `view/incoming_orders_controller.dart`: rings on `hasUnaccepted`
- `view/incoming_order_overlay.dart`: `Overlay.wrap`, keyboard padding, scan panel switch, new copy, `_refreshOrderScreens`
- `widgets/order_scan_panel.dart` (new): all screens from §6, **without** the `cameraBuilder` test seam from §9.4

`flutter analyze` on `lib/screen/order_page` was clean.

**Not done yet:**

- the test updates in §9.2 and the new tests in §9.3–9.4 (expect about 30 existing tests to fail until they're updated)
- `FakeScanSessionStore`
- the test seam
- the emulator run in §9.5

Review the draft against every section above before relying on it.
