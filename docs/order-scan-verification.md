# Order scan implementation and verification — 30 September 2026

Started from `0157f8b` on `feature/order-barcode-scan`. Implementation changes were committed as `5cf7081` (`test folder`) while this work was in progress; that commit is preserved. Testing was stopped at the user's request before final verification. This change must not be treated as fully verified against spec §10.

## Changes

- `lib/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart`: match against the queue's accepted copy, including dummy barcodes; discard fetch, restore, accept and preparing results from a previous login session after logout.
- `repo/pending_orders_repo.dart`: parse restore statuses directly, preserving the fallback to the outer item ID when the nested ID is absent.
- `repo/scan_session_store.dart`: configurable Hive box name, with the production default unchanged, so the device preview can isolate its persistent sessions.
- `view/incoming_order_overlay.dart` and `widgets/order_scan_panel.dart`: cameraBuilder test hook through the real overlay; shared detection handler; bound scan titles and wrap the barcode-match label to prevent small-screen overflow. Production still uses MobileScanner.
- `test/incoming_orders/helpers.dart`: in-memory FakeScanSessionStore, preparing gate, status fake and failures, per-item barcode and quantity fixtures.
- `cubit_test.dart` and `overlay_test.dart`: migrate accept-and-prepare expectations to accept → scan → prepare; cover manual entry, quantity validation, camera review and retake, retry/spinner, Back, lifecycle and keyboard layout.
- `scan_cubit_test.dart`: matching and duplicate lines, preparation gating and retry, queue/ringing state, saved sessions, restore, deferred fetching, and logout while API work is running.
- `model_test.dart` and `repo_http_test.dart`: barcode model round trips and comparisons; order accept/preparing HTTP methods, skip lists, dummy/server codes and restore statuses.
- `device_preview.dart`: five-item fake order, real camera/ringtone/controller, isolated persistent fake backend and scan sessions, Add/Fail/Reset controls, system dark theme, and simulated network failure when preparing in airplane mode. Screen refresh requests use local fakes.
- `docs/order-scan-screenshots/`: partial device evidence and QR images encoding A1–A5.

Orders list and Order Details were not modified. Their existing preparing buttons still bypass scanning. Backend calls remain on the current per-item endpoints with TODO(api) markers.

## Automated results before testing was stopped

- A complete incoming-order suite run passed **97 tests, 0 failures**, including the scan UI at 320×568 with 1.3 text scale and keyboard insets.
- After adding two logout-race regressions, the next complete run reported **98 passed, 1 failed**. Both new regressions passed. The older logout test asserted before the coalesced post-login fetch completed; its wait was updated. **No rerun was performed after that adjustment**, at the user's request.
- `flutter analyze lib test` reported **33 existing issues: 1 warning and 32 informational lints**, matching a separate analysis of `0157f8b`. A later run after adding logout guards reported **36 issues**; the three new brace-style infos were fixed in source. **The final source was not re-analyzed** after those fixes.
- `flutter pub get` completed.
- `pod install` completed, with the existing custom-base-configuration notice. No iOS build was run. The generated Podfile.lock was included in `5cf7081` and has been preserved.
- Android uses `com.nagpurmart.seller` from build.gradle (build.gradle.kts is ignored). Flutter's configured minSdk is 24.

## Pixel_10_Pro manual checklist

Confirmed `adb -s emulator-5554 emu avd name` returned `Pixel_10_Pro`. Restarted with `-camera-back virtualscene -no-snapshot-load`.

The real app launched with a logged-in seller, and both pending endpoints repeatedly returned zero orders. The fake-data preview was used for partial device checks. The backend was reachable; the absence of pending data prevented testing the requested real orders. Some initial emulator actions overlapped with user interaction, so those observations are not counted as completed acceptance steps.

| Step | Status when testing was stopped | Evidence |
|---|---|---|
| 1. Incoming popup, ringing, Back | Incomplete: popup observed; complete ringing/Back evidence not captured together | No completed step screenshot |
| 2. Accept → checklist, ringing stops | Partial: checklist observed at 0 of 5; ringing acceptance check incomplete | `order-scan-screenshots/02-accepted-checklist.png` |
| 3. Camera A1 → frozen review → quantity → tick | Partial: real virtual-scene preview opened; end-to-end detection was not completed | `order-scan-screenshots/camera-virtual-scene.png` |
| 4. Manual A2, wrong then correct quantity | Not completed | — |
| 5. Wrong code ZZ9 | Not completed | — |
| 6. Permission denial, settings, manual fallback | Not completed | — |
| 7. Force-stop and restore ticks | Not completed | — |
| 8. New order during scanning | Not completed | — |
| 9. Finish → preparing → Orders tab and next popup | Not completed; real backend status also remains unverified | — |
| 10. Airplane mode → preparing retry | Not completed | — |
| 11. Dark mode screens | Not completed | — |
| 12. Manual/quantity keyboard layouts | Not completed on device; covered by widget tests | — |

`order-scan-screenshots/scan-checklist-after-back.png` is a partial scan-checklist capture, not evidence that the complete first manual step passed. QR images under `order-scan-screenshots/barcodes/` encode A1–A5. A1 was loaded into both virtual-scene poster slots; the camera still initially faced the television rather than a poster.

## Remaining verification

Run the analyzer and all 99 incoming-order tests on the final commit, complete all 12 manual steps with screenshots, verify real backend preparing status, and finish the camera/permission/restore device checks. No final pass is claimed for these items.

## Backend questions from spec §11

1. Accept endpoint URL, method, body and sample response; order-level or per-item?
2. Preparing URL/body; should scanned codes and quantities be sent for audit?
3. Barcode field name/type, multiple codes or pack sizes, and missing-barcode handling?
4. Should pending lists include accepted-but-unprepared orders?
5. Should Orders list and Order Details also require scanning before preparing?
