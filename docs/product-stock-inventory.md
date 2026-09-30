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

## Backend confirmations still pending

1. Which product response field provides the inventory record ID? The model currently accepts the explicit `variants[].stores[].store_product_variant_id`. The user was asked whether `variants[].stores[].id` is instead that inventory ID. The code does **not** substitute a store ID, variant ID or generic `id` without confirmation. Missing inventory ID produces a visible error and no request.
2. Does the mobile inventory endpoint accept Bearer authentication alone? The supplied backend example includes `X-CSRF-TOKEN`, but this app has no CSRF token source. The current implementation uses the app's existing Bearer authentication. No placeholder CSRF token is supplied. Live endpoint verification is pending this confirmation.

No live product stock was modified during implementation.

## Verification

- `flutter test`: 134 passed, 0 failed. New tests cover blank creation values, zero payloads, integer filtering, editing/hydration, cancel, missing inventory IDs, failures/retry, and the exact JSON request with quantities 0, 5 and 25 against a local HTTP server.
- `flutter analyze lib test`: 0 errors, 2 pre-existing warnings and 32 informational findings; no findings in the changed stock code.
- `flutter build apk --debug`: successful. The updated APK was installed on Pixel_10_Pro.
