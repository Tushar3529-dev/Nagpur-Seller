# Product stock quantity

Creation and full product editing retain the existing per-store stock fields under Pricing & Taxes, for simple products and every variation. A new store pricing entry has no stock default; edits hydrate the backend's quantity, including zero. The stock field retains its controller across rebuilds, accepts nonnegative whole numbers, and describes its value as the total units available. Empty values, negatives, decimals and invalid/overflowing integers cannot pass stock validation. Existing creation/update pricing payloads carry this stock value.

Product Details → Variants & Availability also has **Edit stock** for sellers with product edit permission. It opens the existing stock quantity and allows choosing a store when a variation has several stores. Save calls:

```http
POST {productsApi}/{product_id}/inventory
Content-Type: application/json
Accept: application/json
Authorization: Bearer <current seller token>
```

```json
{"store_product_variant_id": 789, "stock": 25}
```

The repository requires positive product/inventory IDs and a nonnegative integer stock. It uses the response's `data.new_stock` to update the details view and refresh the product list. This is an absolute total, not an increment. Save failures preserve entered quantity and show retryable errors. Cancel leaves stock unchanged. Existing product edit permissions and demo restrictions apply.

## Live backend findings — 30 September 2026

- Product details for products 20 and 21 return inventory IDs under `variants[].stores[].id`: 182 and 186 respectively, with `store_id: 1`. The model now maps that nested row ID to `store_product_variant_id` in outgoing requests, preferring the explicit field if supplied. It never substitutes `store_id`.
- `POST /api/seller/products/21/inventory` returns HTTP 404: the route could not be found.
- `/seller/products/21/inventory` is a web route (GET reports POST is supported), but POST with the app's Bearer token returns HTTP 419, `CSRF token mismatch`.
- Both POST probes used inventory ID 0 and stock -1, which cannot target a valid stock record. No live inventory was changed.

**Backend action required:** expose/deploy `POST /api/seller/products/{product_id}/inventory` for the mobile seller's Bearer authentication. The current web/session/CSRF route cannot be used with this app's existing authentication. The client mapping fix removes the screenshot's missing-ID error, but successful live saving remains blocked by the server route.

No live product stock was modified during implementation.

## Verification

- `flutter test`: 134 passed, 0 failed. New tests cover blank creation values, zero payloads, integer filtering, editing/hydration, cancel, missing inventory IDs, failures/retry, and the exact JSON request with quantities 0, 5 and 25 against a local HTTP server.
- `flutter analyze lib test`: 0 errors, 2 pre-existing warnings and 32 informational findings; no findings in the changed stock code.
- `flutter build apk --debug`: successful. The updated APK was installed on Pixel_10_Pro.

## Product listing shortcut

Each editable product card now shows **Edit qty** beside its stock badge, including low/out-of-stock products. It opens a popup in the list, loads fresh product details for inventory IDs/current stock, and offers variation/store selection when needed. Success refreshes the current list; failures offer retry. Tapping the shortcut does not open Product Details. Narrow card headers wrap the badge/button to avoid overflow.

Current verification: 141 tests passed, 0 failed; analyzer 0 errors with the same 2 warnings and 32 informational findings. Debug APK rebuilt and installed on Pixel_10_Pro. The backend route/authentication blocker above remains open; no live inventory quantity was modified.
