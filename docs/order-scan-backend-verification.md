# Backend flow verification — 30 September 2026

Testing resumed following the user's request. This report applies to the real API integration, superseding the earlier draft's test results.

## Results

- `flutter test`: **120 passed, 0 failed**.
- `flutter test test/incoming_orders`: **112 passed, 0 failed**.
- `flutter analyze lib test`: **0 errors, 2 warnings, 32 informational lints**. The command exits nonzero due to the remaining findings. Warnings are `unused_element_parameter` in pagination_controller.dart and `unnecessary_null_comparison` in current_plan_model.dart; neither is in changed incoming-order code.
- `flutter build apk --debug`: passed. Installed and launched the APK on emulator-5554; `emu avd name` returned **Pixel_10_Pro**.
- Production `lib/` has no fake-order repo, test fixture import, A1–An generation, or barcode fallback. The fake device preview and five demo barcode PNGs were removed. Its isolated Hive backend/session files were also removed from this emulator. Automated fixtures remain only in tests, including deliberate A1 input to prove it is rejected for real or missing barcodes.

## Regression coverage added

Server-accepted resume without another accept request or ringing; actual scanned-code persistence; quantity confirmation requiring a preceding valid scan; missing barcodes blocking preparing without an HTTP request; expected barcodes hidden even in debug UI; unchanged polls preserving in-flight scans; changed quantities invalidating verification; backend 422 item errors clearing only affected ticks; direct and nested item status responses; atomic preparing callbacks; stale saved orders removed after successful pending refresh; failed modes preserving progress; legacy dummy-value sessions replaced by current backend data.

## Pixel_10_Pro evidence and limits

The old installation showed a saved accepted popup even though regular and wholesale pending APIs returned zero orders. After rebuilding, the new code cleared that stale session, displayed the dashboard normally, and continued polling both modes successfully with zero pending orders. Its startup status lookup also reported `Order not found` for the stale order. Screenshot: [no-pending-orders.png](order-scan-screenshots/backend/no-pending-orders.png).

The complete 12-step order journey in draft spec §9.5 was **not run** in this verification: there are no current backend pending test orders. None of those steps is claimed to pass based on widget tests. A real backend test order with known barcodes is needed to verify camera detection, acceptance, quantity entry, preparing, queuing, and restart behavior end to end. The fake preview is no longer available, per the user's instruction to remove demo data. No live order was accepted or prepared during these checks.

## Still deferred

Backend confirmation of `verify-and-prepare` retry behavior after the server commits but the success response is lost remains open. See [order-scan-backend-integration.md](order-scan-backend-integration.md). Orders list and Order Details buttons remain outside this flow's scope.
