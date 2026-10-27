package com.nagpurmart.seller.orderalert

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `com.nagpurmart.seller/order_alert`, between MainActivity and
 * `OrderAlertBridge` in Dart: setLoggedIn, sync.
 */
class OrderAlertChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.nagpurmart.seller/order_alert"
    }

    private val channel = MethodChannel(messenger, NAME)

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setLoggedIn" -> {
                val loggedIn = call.argument<Boolean>("loggedIn") == true
                OrderAlertStore.setLoggedIn(context, loggedIn)
                if (!loggedIn) OrderAlertStore.clearPending(context)
                OrderAlertService.refresh(context)
                result.success(null)
            }
            // Unaccepted orders start ringing; accepted and reassigned ones stop.
            "sync" -> {
                val now = System.currentTimeMillis()
                val alerts = call.argument<List<Map<String, Any?>>>("alerts").orEmpty()
                    .mapNotNull { item ->
                        val id = item["orderId"]?.toString()?.trim().orEmpty()
                        if (id.isEmpty()) return@mapNotNull null
                        OrderAlert(
                            orderId = id,
                            title = item["title"]?.toString().orEmpty(),
                            body = item["body"]?.toString().orEmpty(),
                            receivedAt = now,
                        )
                    }
                val accepted = call.argument<List<Any?>>("acceptedIds").orEmpty()
                    .mapNotNull { it?.toString()?.trim()?.takeIf(String::isNotEmpty) }
                val serverIds = call.argument<List<Any?>>("serverIds")
                    ?.mapNotNull { it?.toString()?.trim()?.takeIf(String::isNotEmpty) }
                    ?.toSet()
                OrderAlertStore.sync(context, alerts, accepted, serverIds)
                OrderAlertService.refresh(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
