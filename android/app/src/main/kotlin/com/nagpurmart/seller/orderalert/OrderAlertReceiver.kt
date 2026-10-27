package com.nagpurmart.seller.orderalert

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Starts ringing for new-order pushes, and stops it for reassign pushes,
 * natively, in every app state.
 *
 * Listens to the raw FCM broadcast, like FlutterFire's own receiver does
 * (which keeps working alongside). Unlike a FirebaseMessagingService it also
 * gets pushes that carry a `notification` block while the app is in the
 * background or closed; Android then also shows that notification itself.
 */
class OrderAlertReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "OrderAlertReceiver"

        /** Mirrors `NotificationService.isNewRegularOrderType` in Dart. */
        private val NEW_ORDER_TYPES = setOf("seller_new_order", "new_order", "order", "orders")

        /** The backend gave the order to another seller: stop its ringing. */
        private val REASSIGNED_TYPES = setOf("seller_order_reassigned", "order_alert_cancel")
    }

    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        val type = extras.getString("type")?.trim()?.lowercase().orEmpty()
        val sellerOrderId = extras.getString("seller_order_id")?.trim().orEmpty()
        if (type in REASSIGNED_TYPES) {
            val orderId = sellerOrderId.ifEmpty { extras.getString("order_id")?.trim().orEmpty() }
            if (orderId.isNotEmpty()) OrderAlertService.stopForReassign(context, orderId)
            return
        }
        val isNewOrder = type in NEW_ORDER_TYPES || (type.isEmpty() && sellerOrderId.isNotEmpty())
        if (!isNewOrder) return

        val orderId = sellerOrderId.ifEmpty { extras.getString("order_id")?.trim().orEmpty() }
        if (orderId.isEmpty()) {
            Log.w(TAG, "New-order push without seller_order_id or order_id")
            return
        }
        if (extras.getString("google.delivered_priority") == "normal") {
            // Android may then refuse to start the alert service.
            Log.w(TAG, "New order $orderId arrived as normal priority")
        }
        OrderAlertService.alertFromPush(
            context,
            orderId,
            title = extras.getString("title") ?: extras.getString("gcm.notification.title")
                ?: extras.getString("gcm.n.title"),
            body = extras.getString("body") ?: extras.getString("gcm.notification.body")
                ?: extras.getString("gcm.n.body"),
        )
    }
}
