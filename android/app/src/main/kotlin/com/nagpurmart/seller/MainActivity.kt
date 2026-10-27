package com.nagpurmart.seller

import com.nagpurmart.seller.orderalert.OrderAlertChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var orderAlertChannel: OrderAlertChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        orderAlertChannel = OrderAlertChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        orderAlertChannel?.dispose()
        orderAlertChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
