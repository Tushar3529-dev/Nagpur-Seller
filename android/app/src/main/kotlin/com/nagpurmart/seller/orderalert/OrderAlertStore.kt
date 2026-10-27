package com.nagpurmart.seller.orderalert

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/** An order offered to this seller that is waiting to be accepted. */
data class OrderAlert(
    val orderId: String,
    val title: String,
    val body: String,
    val receivedAt: Long,
    /** Came from a push, not from the app's own pending list. */
    val fromPush: Boolean = false,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("order_id", orderId)
        .put("title", title)
        .put("body", body)
        .put("received_at", receivedAt)
        .put("from_push", fromPush)

    companion object {
        fun fromJson(json: JSONObject): OrderAlert? {
            val orderId = json.optString("order_id").trim()
            if (orderId.isEmpty()) return null
            return OrderAlert(
                orderId = orderId,
                title = json.optString("title"),
                body = json.optString("body"),
                receivedAt = json.optLong("received_at"),
                fromPush = json.optBoolean("from_push"),
            )
        }
    }
}

/**
 * The alerts ringing for the seller, kept on disk so they survive the process
 * being killed and the alert service being restarted by Android.
 *
 * Pushes and the app's pending list add alerts. Only two things stop one:
 * the seller accepting the order, or the order being reassigned to another
 * seller (a reassign push, or the server's pending list no longer having it).
 */
object OrderAlertStore {
    private const val PREFS = "order_alert"
    private const val KEY_LOGGED_IN = "logged_in"
    private const val KEY_PENDING = "pending"
    private const val KEY_HANDLED = "handled"

    /** How long a stopped order is ignored when its push arrives again. */
    private const val HANDLED_TTL_MS = 6 * 60 * 60 * 1000L

    /**
     * A pushed order may reach the pending endpoint a little after its push.
     * Until then, its absence from that list doesn't mean it was reassigned.
     */
    private const val PUSH_GRACE_MS = 60 * 1000L

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Set by Flutter. Alerts only ring while someone who gets orders is logged in. */
    fun isLoggedIn(context: Context): Boolean = prefs(context).getBoolean(KEY_LOGGED_IN, false)

    fun setLoggedIn(context: Context, loggedIn: Boolean) {
        prefs(context).edit().putBoolean(KEY_LOGGED_IN, loggedIn).commit()
    }

    /** Oldest first. */
    @Synchronized
    fun pending(context: Context): List<OrderAlert> {
        val json = readObject(prefs(context), KEY_PENDING)
        return json.keys().asSequence()
            .mapNotNull { key -> json.optJSONObject(key)?.let(OrderAlert::fromJson) }
            .sortedBy { it.receivedAt }
            .toList()
    }

    /**
     * Adds a pushed [alert]. Returns false for a duplicate: the order is
     * already ringing, or was accepted within [HANDLED_TTL_MS].
     */
    @Synchronized
    fun addFromPush(context: Context, alert: OrderAlert): Boolean {
        val prefs = prefs(context)
        val pending = readObject(prefs, KEY_PENDING)
        val handled = pruned(readObject(prefs, KEY_HANDLED), alert.receivedAt)
        if (pending.has(alert.orderId) || handled.has(alert.orderId)) return false
        pending.put(alert.orderId, alert.toJson())
        prefs.edit()
            .putString(KEY_PENDING, pending.toString())
            .putString(KEY_HANDLED, handled.toString())
            .commit()
        return true
    }

    /**
     * From the open app: [alerts] are its unaccepted orders and ring (if not
     * ringing already); [acceptedIds] were accepted and stop.
     *
     * [serverIds], when given, are every order the server's pending list just
     * returned. A ringing order missing from it was reassigned and stops,
     * unless it was pushed moments ago and isn't listed yet.
     */
    @Synchronized
    fun sync(
        context: Context,
        alerts: List<OrderAlert>,
        acceptedIds: Collection<String>,
        serverIds: Set<String>?,
    ) {
        val prefs = prefs(context)
        val now = System.currentTimeMillis()
        val pending = readObject(prefs, KEY_PENDING)
        val handled = pruned(readObject(prefs, KEY_HANDLED), now)
        for (alert in alerts) {
            if (alert.orderId in acceptedIds) continue
            // The app shows it unaccepted, so a past stop no longer applies.
            handled.remove(alert.orderId)
            // Keep a ringing alert as is, with its start time (oldest first).
            if (!pending.has(alert.orderId)) pending.put(alert.orderId, alert.toJson())
        }
        val stopped = acceptedIds.toMutableSet()
        if (serverIds != null) {
            for (key in pending.keys().asSequence().toList()) {
                if (key in serverIds) continue
                val alert = pending.optJSONObject(key)?.let(OrderAlert::fromJson)
                val justPushed = alert != null && alert.fromPush &&
                    now - alert.receivedAt < PUSH_GRACE_MS
                if (!justPushed) stopped.add(key)
            }
        }
        for (id in stopped) {
            pending.remove(id)
            handled.put(id, now)
        }
        prefs.edit()
            .putString(KEY_PENDING, pending.toString())
            .putString(KEY_HANDLED, handled.toString())
            .commit()
    }

    /** The order was reassigned to another seller: stop, and ignore late pushes. */
    @Synchronized
    fun stop(context: Context, orderId: String) {
        val prefs = prefs(context)
        val now = System.currentTimeMillis()
        val pending = readObject(prefs, KEY_PENDING).apply { remove(orderId) }
        val handled = pruned(readObject(prefs, KEY_HANDLED), now).put(orderId, now)
        prefs.edit()
            .putString(KEY_PENDING, pending.toString())
            .putString(KEY_HANDLED, handled.toString())
            .commit()
    }

    /** On logout: nothing rings for the next user who logs in here. */
    @Synchronized
    fun clearPending(context: Context) {
        prefs(context).edit().remove(KEY_PENDING).commit()
    }

    private fun readObject(prefs: SharedPreferences, key: String): JSONObject =
        try {
            JSONObject(prefs.getString(key, null) ?: "{}")
        } catch (e: Exception) {
            JSONObject()
        }

    private fun pruned(handled: JSONObject, now: Long): JSONObject {
        val expired = handled.keys().asSequence()
            .filter { now - handled.optLong(it) > HANDLED_TTL_MS }
            .toList()
        expired.forEach(handled::remove)
        return handled
    }
}
