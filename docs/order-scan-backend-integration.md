# Real backend integration — 30 September 2026

The supplied contract is preserved in [seller-order-popup-flow-api.md](seller-order-popup-flow-api.md). The user confirmed mobile `/api/seller/orders` endpoints use the same contract as the web examples. This document supersedes the draft spec's dummy-barcode and per-item popup API sections.

## Implemented

- Pending lists parse item statuses, real barcodes, SKU, weight and dimensions. Server-accepted orders open directly in scan mode without ringing as new orders. Mixed awaiting/accepted orders still require the order-level accept action.
- Accept sends `POST {ordersApi}/{seller_order_id}/accept-items` with an empty body. Already-accepted items rely on the documented idempotency. Packing details come from the pending response; the accept response only acknowledges accepted IDs.
- Preparing sends a single `POST {ordersApi}/{seller_order_id}/verify-and-prepare` with all locally verified item IDs, actual scanned/typed barcodes and exactly confirmed quantities. No per-item popup preparing fallback or production dummy barcode generation remains.
- Matching is case-sensitive, aligning with the backend's exact-match requirement. Scanner/manual input still trims surrounding whitespace.
- Expected barcodes are hidden in all popup builds. SKU, weight and dimensions can identify products without revealing expected codes.
- Missing barcode: `Barcode missing for <product>. Contact support.` The item cannot be verified or prepared. Admin makes barcodes mandatory, but this defensive case remains visible.
- Structured backend validation errors retain item IDs and field names. Invalidated items lose their ticks, show their field errors, and must be scanned and counted again before resubmission.
- Confirming quantity requires a preceding matching scan/manual code. Actual codes are saved with verification progress. Legacy saved ticks without scanned values require re-verification.
- Refreshing an accepted order updates its packing data. Changed quantities/barcodes invalidate affected ticks; unchanged pending polls preserve a matched code while quantity is being entered.
- Test helpers and the persistent fake preview remain isolated from real endpoints. Fixture A1–An values are test data, not a production fallback. Test sources were adapted to the new contract; they were not executed.

## Deferred backend confirmation — remember this

**OPEN: Is `verify-and-prepare` safe to retry if the backend commits the transition but its success response is lost?**

The user explicitly deferred this question pending backend confirmation. It remains a TODO in `PendingOrdersRepo.markOrderPreparing`. The current Retry preparing action resends the full verified item set. Do not claim that preparing retries are idempotent. Confirm whether a repeat returns success for an already-preparing order, returns a specific conflict, or requires an idempotency key before finalizing recovery behavior.

## Scope and verification

The Orders list and Order Details pages remain unchanged under the original scope constraint. Their status actions may need a separate update because the new backend contract requires barcode and quantity for single-item preparing requests too.

No analyzer, automated tests, emulator runs or backend requests were performed for this integration: testing remains paused at the user's request. Previous test results in order-scan-verification.md apply to the earlier implementation, not this API integration.
