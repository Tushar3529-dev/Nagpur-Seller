# Codex task: Seller app — bring back Retake / Confirm in the order scan flow

You are working in a Flutter seller app (`package:hyper_local_seller`, flutter_bloc + mobile_scanner). Once a seller accepts an incoming order, a full-screen scan panel opens: they scan each product, count its quantity, pack everything in a bag, scan the bag, and tap "Dispatch order".

To make scanning faster, an earlier change removed the **Retake / Confirm** step. Now a camera scan counts immediately, and the only feedback is a green toast that disappears after 1.2 s. Sellers can't tell whether a scan registered, or which product it counted. **Bring back a short review step for camera scans of products and of the bag: freeze the frame, show what was scanned and whether it matches, then the seller taps Retake or Confirm.** Keep the rest of the fast flow (pages per product, +/− quantity, auto-slide to the next product, packing step) exactly as it is.

Follow this document exactly. Do not invent new endpoints, cubit methods, persistence, or screens beyond what is written here.

---

## 0. Read these first

- `lib/screen/order_page/incoming_orders/widgets/order_scan_panel.dart` — **the only production file you should need to change.** Read all of it. Key parts:
  - `enum _Phase { items, bag, ready }` and `_phaseOf`.
  - `_onCameraCode` (repeat suppression with `_repeatDelay`) → `_handleCode` → `_checkItem` / `_assignBag`.
  - `_counts` (units counted per `orderItemId`), `_changeQuantity`, `_verify`, `_showPage`, `_showNextAfter`.
  - `_buildCamera`, `_buildManual`, `_buildPages`, `_buildBag`, `_buildPacking`, `_buildSummary`, `_buildActions`.
  - `_ScanHeader`, `_ScanMessage`, `_ItemPage`, `_BagRow`.
- `lib/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart`:
  - `matchCode(order, code)` → `(ScanMatch, PendingOrderItem?)`. It doesn't verify anything, but it records the matched code in `_matchedCodes`, which `confirmQuantity` needs later.
  - `confirmQuantity(item, quantity)` → `bool` (verifies the item; quantity must equal the ordered quantity).
  - `assignBag(order, barcode)` → `Future<String?>` (null = success, otherwise the message to show). `state.assigningBagOrderId` is set while it runs.
- `lib/screen/order_page/incoming_orders/cubit/incoming_orders_state.dart` — `enum ScanMatch { matched, alreadyVerified, notInOrder }`.
- `lib/widgets/custom/barcode_scan_widgets.dart` — reuse: `ScanCameraView`, `ScanCodeBox`, `ScanPrimaryButton`, `ScanSecondaryButton`, `ScanManualEntryButton`, `ScanErrorText`, `ScanBottomBar`, `firstBarcodeValue`. **Don't create new versions of these.**
- **Reference implementation of the same review pattern** (copy its approach, not its layout):
  - `lib/screen/more_page/view/bag_inventory/widgets/add_bags_dialog.dart`: `MobileScannerController(returnImage: true)`, `_scannedCode` / `_scannedImage`, `_onDetect` passing `capture.image`, and `_go(...)` disposing the scanner while reviewing.
  - `lib/screen/products_page/products/widgets/product_scan_dialog.dart`: `_buildReview` (frozen `Image.memory` on black, `ScanCodeBox(label: 'Detected code', ...)`) and `_buildReviewActions` (Retake + green Confirm).
- Tests: `test/incoming_orders/overlay_test.dart`. Read its helpers (`startScan`, `manual`, `detect`, `countRest`, `settleScan`, `verifyOnlyItem`, `qty`) and the fake camera passed through `cameraBuilder`. The fake camera shows a `Detect <code>` button that calls `onCode(code, null)`.

---

## 1. Ground rules

1. Change only `order_scan_panel.dart` and `test/incoming_orders/overlay_test.dart`. **Don't change the cubit, the state, the repo, `scan_session_store.dart`, or the shared scan widgets.** If you think one of them needs a change, stop and explain why instead of doing it.
2. The working tree has a lot of uncommitted work in other features (delivery boys, dispatch, system users, l10n, and more). **Don't touch, revert, or reformat any of it.**
3. Match the file's existing style: hard-coded English strings (this panel doesn't use l10n; don't add it here), `HapticFeedback` calls, comment density, and the private widget classes at the bottom.
4. Strings in this document are exact. Tests look them up by text.
5. Finish with `flutter analyze` (no new issues) and `flutter test test/incoming_orders` (all green).

---

## 2. Behaviour

### 2.1 New review state

Add transient review state to `_OrderScanPanelState`, for example:

```dart
/// Camera scan waiting for the seller to confirm or retake it. Null while
/// the camera is live.
_Review? _review;
```

```dart
class _Review {
  final String code;
  final Uint8List? image;          // frozen camera frame, null in tests or when unavailable
  final bool bag;                  // true in the bag phase
  final ScanMatch? match;          // product scans only
  final PendingOrderItem? item;    // matched or already-verified product
  final String? error;             // why it can't be confirmed (wrong code, or the server rejected the bag)
  bool get canConfirm => error == null;
}
```

- `_review` lives only in widget state. It isn't saved, and closing or backgrounding the panel can drop it.
- Clear `_review` whenever the phase changes (in `didUpdateWidget`, next to `_error = null`).

### 2.2 Camera and frozen frame

- Create the scanner with `MobileScannerController(returnImage: true)` everywhere `_scanner` is created in `_syncCamera`.
- `_onDetect` must pass `capture.image` through: `_onCameraCode(code, capture.image)`.
- Add `_review == null` to the "wanted" condition in `_syncCamera`, so the camera is **disposed while reviewing** (same approach as `add_bags_dialog.dart`) and recreated on Retake or Confirm.
- `_onCameraCode` must ignore codes while `_review != null`. This matters for the fake test camera, which stays tappable.
- While reviewing, the top area (where `_buildCamera()` normally goes) shows a new `_buildFrozen()` instead of the camera and instead of `cameraBuilder`'s preview:
  - Black box filling the same space. `Image.memory(image, fit: BoxFit.contain)` when `image != null`; otherwise a centred `Icons.qr_code_2` (or `Icons.shopping_bag_outlined` for a bag), white70, size 64.
  - A small top-left chip: `Icons.pause` + `Frozen frame`, white text on `Colors.black54`, 6 px radius.
  - A result banner pinned to the bottom of the box, reusing `_ScanMessage`:
    - Product matched: green, `Matches <product name>` (`item.product`; add ` · <variant>` when `item.variant != null`).
    - Not in order: red, `Not in this order`.
    - Already verified: red, `<product> is already verified`.
    - Bag, not yet sent: no banner.
    - Bag rejected by the server: red, the server message.

### 2.3 Products (phase `items`)

**Confirm rule: only the first camera scan of a product needs Confirm.** That scan proves it's the right product. After that, + / − and more scans of the same product count directly, as they do today.

Rewrite the camera path of `_checkItem(code)` (manual entry is covered in §2.5):

1. `final (match, item) = _cubit.matchCode(widget.order, code);`
2. If `match == ScanMatch.matched` and `_countOf(item) > 0`, the product was already confirmed once. Run today's matched branch unchanged (count +1, `_verify` when it reaches the quantity, otherwise stay on the page). **No review.**
3. Otherwise, open review:
   - `matched` (first scan): `HapticFeedback.selectionClick()`, `_showPage(item)` so the product's page is visible under the frozen frame, set `_review = _Review(code, image, bag: false, match, item)`.
   - `alreadyVerified`: `HapticFeedback.heavyImpact()`, `_review` with `error: '${item.product} is already verified. Scan the next item.'`.
   - `notInOrder`: `HapticFeedback.heavyImpact()`, `_review` with `error: "This barcode isn't in this order. Check the product and try again."`.
   - Clear `_error` and `_matched` when opening review.
4. **Confirm** (`_confirmReview()` for a product):
   - Count one unit: `count = _countOf(item) + 1`.
   - If `count >= item.quantity`: clear `_review`, then call `_verify(item)`. This keeps the existing green toast `<product> verified` and the slide to the next product.
   - Otherwise: set `_counts[item.orderItemId] = count`, clear `_review`, `HapticFeedback.mediumImpact()`, and show a green toast on the live camera: `1 of 3 counted` (`'$count of ${item.quantity} counted'`). Reuse the `_matched` / `_matchedTimer` mechanism; generalise `_matched` to hold the full message text if needed, so it can show either `<product> verified` or `x of y counted`.
   - Call `_syncCamera()` (inside or after `setState`) so the camera starts again.
5. **Retake** (`_retake()`):
   - Clear `_review` and `_error`, then `_syncCamera()`.
   - **Set `_lastCode = review.code` and `_lastCodeAt = DateTime.now()`**, so the barcode still in front of the lens isn't captured again straight away. The existing `_repeatDelay` (1500 ms) logic then ignores it until it has been out of view.
   - Don't change `_counts`.
6. After Confirm, the same code may still be in view. Make sure step 2 doesn't count it again right away. `_onCameraCode`'s repeat suppression handles this as long as `_lastCode` / `_lastCodeAt` are set when the review opened (they already are, because `_onCameraCode` sets them before `_handleCode`). Keep it that way, and refresh `_lastCodeAt = DateTime.now()` on Confirm as well.
7. While reviewing, the product `PageView` must not swipe (`physics: _review != null ? const NeverScrollableScrollPhysics() : null`), and the `_ItemPage` +/− buttons must do nothing (pass a no-op, or disable them).

### 2.4 Bag (phase `bag`, after "Scan bag")

1. A camera code in the bag phase **no longer calls `_assignBag` straight away**. It opens review instead: `HapticFeedback.selectionClick()`, `_review = _Review(code, image, bag: true)`.
2. **Assign bag** (Confirm for a bag): call the existing `_assignBag(review.code)` flow (`_cubit.assignBag`).
   - While it runs (`_isAssigningBag`), the confirm button shows its loading state and Retake is disabled.
   - Success: clear `_review`. The phase moves to `ready` through `didUpdateWidget`, as it does today. `HapticFeedback.mediumImpact()`.
   - Error: `HapticFeedback.heavyImpact()`, keep the review open with `error: <server message>`. Now only Retake is offered.
3. **Retake** for a bag works the same as for a product (§2.3 step 5).

### 2.5 Manual entry — unchanged

Typed codes (`_manual == true`, "Check code" / "Assign bag" buttons, `onSubmitted`) **skip the review** and behave exactly as they do today, including first-time product matches and bags. Typing is already deliberate. Make sure your `_checkItem` / `_handleCode` changes keep that path. One simple way: add a `fromCamera` flag (or pass the image / a bool) from `_onCameraCode`, while the manual path calls the existing logic.

### 2.6 Header

`_ScanHeader.title` while `_review != null`:
- Product review: `Check the scan` (keep `position`, for example `2 / 4`).
- Bag review: `Check the bag`.

Otherwise the titles stay `Scan items` / `Assign a bag` / `Ready to dispatch`.

### 2.7 Area below the frozen frame

- Product review: keep showing `_buildPages()`, already moved to the matched product's page. Below the page dots, add a `ScanCodeBox(label: 'Detected code', code: review.code)`. For a matched product, also add a hint line (bodySmall, hint colour, centred): `Confirm counts 1 of <quantity>.`, or `Confirm verifies <product>.` when the quantity is 1. For an error review, show `ScanErrorText(error)` instead of the hint.
  - Keep it from overflowing: put the code box and hint in the same scrollable area as the pages, or shrink the page area. The existing "no overflow" tests (§3) must still pass at every size listed there.
- Bag review: replace `_buildBag()` content with `ScanCodeBox(label: 'Bag code', code: review.code)`, then either the hint `All <n> items verified. Confirm to assign this bag to the order.` or `ScanErrorText(error)`, plus the existing spinner while assigning.
- **Never show the expected barcode of an order item.** Only show the code the camera actually read. An existing test checks that the expected barcode never appears.

### 2.8 Bottom bar while reviewing

Add a branch at the top of `_buildActions` (after the dispatch-error handling, before the other branches) when `_review != null`:

- `canConfirm`:
  ```
  [ ↻ Retake ]  [ ✓ Confirm ]          // product
  [ ↻ Retake ]  [ ✓ Assign bag ]       // bag
  ```
  `Row` of two `Expanded`. `ScanSecondaryButton(label: 'Retake', onPressed: _isAssigningBag ? null : _retake)` and `ScanPrimaryButton(label: 'Confirm' | 'Assign bag', icon: Icons.check, color: Colors.green.shade600, isLoading: _isAssigningBag, onPressed: _confirmReview)`.
- Error (`!canConfirm`): a single full-width `ScanPrimaryButton(label: 'Retake', icon: Icons.refresh, onPressed: _retake)` in the default primary colour. **No Confirm button.**

Hide the manual-entry button and the progress bar while reviewing.

### 2.9 Docs in code

Update the class doc comment on `OrderScanPanel` and the comments on `_counts` / `_checkItem` to describe the new flow: the first camera scan of each product and the bag scan are frozen for Retake / Confirm, extra units count directly, and typed codes skip the review.

---

## 3. Tests (`test/incoming_orders/overlay_test.dart`)

Add helpers next to `detect`:

```dart
Future<void> confirmScan(WidgetTester tester) async {
  await tester.tap(find.text('Confirm'));
  await settleScan(tester);
}

Future<void> retake(WidgetTester tester) async {
  await tester.tap(find.text('Retake'));
  await settleScan(tester);
}
```

The fake camera passes `image == null`, so the frozen frame shows the placeholder icon. That's expected.

### 3.1 Update existing tests to the new flow

These currently expect a camera detect to count straight away. Insert `confirmScan` after the **first** detect of each product and after each bag detect, and update the assertions:

- `quantity is asked after the scan, then the next product slides in`:
  - After `detect('A1')`: expect `Check the scan`, `Matches Product 11`, `Detected code`, `A1`, `Retake`, `Confirm`, and `qty`/counts **not** started yet (`cubit.state.verifiedItemIds` empty, `find.text('Add quantity')` findsNothing).
  - `confirmScan` → `qty(11) == '1'`, `1 of 3 counted`, title back to `Scan items`.
  - The repeat detect of `A1` right after must still not count twice.
  - `detect('ZZ9')` → `Not in this order`, the "isn't in this order" text, **no** `Confirm`, `Retake` present. `retake` → back to `Scan items`.
  - `detect('A2')` → `confirmScan` → `countRest` → bag step.
- `a product ordered once is verified by its scan alone` → rename to `a product ordered once is verified by one confirmed scan`. Detect, check it's not verified yet, `confirmScan`, then verified and `2 / 2`.
- `items can be scanned in any order; swiping shows them`: add `confirmScan` where needed.
- `a scanned bag is assigned straight away and unlocks dispatch` → rename to `a scanned bag is assigned after Assign bag and unlocks dispatch`. After `detect('A2')` in the bag phase: `Check the bag`, `Bag code`, `repo.bagCalls` **still empty**. Tap `Assign bag` → `repo.bagCalls == ['1 A2']`, `Ready to dispatch`, `Assigned`.
- `back and backgrounding preserve scan progress`, and the `no overflow at …` / `scan page, keyboard and quantity fit $size` size loops: add `confirmScan` where a detect now opens review.
- Tests that use `manual(...)` (typed codes) must keep passing **without** any confirm. That's the point of §2.5.

### 3.2 New tests

1. **`first camera scan freezes and waits for confirm`**: detect `A1` → `Check the scan`, `Frozen frame`, `Matches Product 11`, `Confirm` + `Retake`; nothing verified, `repo.calls` unchanged; tapping `Detect A1` / `Detect A2` again does nothing while reviewing.
2. **`retake discards the scan`**: detect `A1` → `retake` → `Scan items`, `Scan the barcode, then add the quantity.` still shown, `qty` key for item 11 not present, nothing verified. Then detect `A1` again **after** `tester.pump(const Duration(milliseconds: 1600))` → the review opens again.
3. **`wrong or already-verified code offers only retake`**: detect `ZZ9` → `Not in this order`, `find.text('Confirm')` findsNothing. Verify item 11 fully (detect + confirm + countRest), swipe back or use a single-item order, detect `A1` again after the repeat delay → `Product 11 is already verified`, only `Retake`.
4. **`extra units after the first confirm count without review`**: quantity-3 order: detect `A1`, `confirmScan` (1 of 3), `pump(1600 ms)`, detect `A1` → `qty == '2'` and **no** `Check the scan`; again → verified and slides to the next product.
5. **`page swipes and quantity buttons are locked while reviewing`**: during a product review, a fling on the `PageView` doesn't change the `x / n` header, and the +/− tooltips (if visible) don't change counts.
6. **`rejected bag keeps the frozen scan with only retake`**: `repo.assignBagError = ApiException('The bag is not available in your bag pool.', statusCode: 422)`; reach the bag phase, `Scan bag`, detect `BAG-USED`, tap `Assign bag` → the server message shows, `Assign bag` button gone, `Retake` present, `Dispatch order` absent. Clear the error, `retake`, `pump(1600 ms)`, detect `BAG-OK`, `Assign bag` → `repo.bagCalls` ends with `'1 BAG-OK'`, `Dispatch order` present.
7. **`typed codes skip the review`**: `manual(tester, 'A1')` → no `Check the scan`, `qty(11) == '1'` immediately (current behaviour).
8. **No-overflow** in review state: for the sizes already used by the overflow loop, open a product review and a bag review and assert `tester.takeException()` is null.

---

## 4. Out of scope

- Any change to how the server verifies items or bags, to `confirmQuantity` / `assignBag`, or to scan-progress persistence.
- Requiring Confirm for every unit (only the first camera scan of each product needs it; see §2.3).
- Review for manually typed codes.
- The bag inventory screen (`add_bags_dialog.dart`) and the product scan dialog. They already have their own Retake / Confirm.
- Sounds: the beep in `ScanCameraView` already plays on every read. Don't add more audio.

## 5. Done when

- Scanning a product with the camera freezes the frame, shows `Matches <product>` or a red reason, and waits for **Confirm** or **Retake**. Confirm counts it and the camera comes back. A wrong code offers only Retake.
- Units after the first confirmed scan count with + / − or more scans, with no extra prompt. At the ordered quantity, the product turns green and the next one slides in.
- Scanning a bag freezes, shows `Bag code`, and only calls the assign-bag API on **Assign bag**. A server rejection shows the message with only Retake.
- Typed codes behave exactly as before.
- `flutter analyze` is clean for the touched files and `flutter test test/incoming_orders` passes.
