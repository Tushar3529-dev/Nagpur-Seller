package com.nagpurmart.seller.orderalert

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log
import com.nagpurmart.seller.MainActivity
import com.nagpurmart.seller.R

/**
 * Rings like an incoming call while offered orders wait to be accepted.
 * Same approach as the rider app's order alert.
 *
 * A `mediaPlayback` foreground service: it plays the phone's ringtone on the
 * alarm stream (so it is heard on silent and vibrate) and keeps running
 * after the app is swiped away. An order rings until the seller accepts it
 * or it is reassigned to another seller (see [OrderAlertStore]); on logout
 * everything stops, as nobody could accept it.
 *
 * Started from a high-priority FCM message (which lets a foreground service
 * start from the background on Android 12+) or from the open app. If Android
 * refuses anyway, [postFallback] shows an insistent notification.
 *
 * Plain framework APIs only: the app pins androidx.core to an old version.
 */
class OrderAlertService : Service() {

    companion object {
        private const val TAG = "OrderAlertService"

        private const val ACTION_REFRESH = "com.nagpurmart.seller.orderalert.REFRESH"

        private const val NOTIFICATION_ID = 4301
        private const val FALLBACK_NOTIFICATION_ID = 4302

        private const val CHANNEL_ID = "seller_order_alert_v1"
        private const val FALLBACK_CHANNEL_ID = "seller_order_alert_fallback_v1"

        private val VIBRATION_PATTERN = longArrayOf(0, 800, 700)

        /** How long after a swipe-away the process must survive to ring itself again. */
        private const val SWIPE_HANDOVER_MS = 3000L

        /** How often a paused ring checks whether the call that paused it is over. */
        private const val FOCUS_RECHECK_MS = 3000L

        @Volatile
        private var instance: OrderAlertService? = null

        /** Rings for an order from a new-order push. */
        fun alertFromPush(context: Context, orderId: String, title: String?, body: String?) {
            if (!OrderAlertStore.isLoggedIn(context)) {
                Log.w(TAG, "New order $orderId ignored: nobody logged in")
                return
            }
            val alert = OrderAlert(
                orderId = orderId,
                title = title?.takeIf { it.isNotBlank() } ?: "New order received",
                body = body?.takeIf { it.isNotBlank() } ?: "Open the app to accept it.",
                receivedAt = System.currentTimeMillis(),
                fromPush = true,
            )
            if (!OrderAlertStore.addFromPush(context, alert)) {
                Log.i(TAG, "Order $orderId already ringing or handled, ignoring duplicate")
                return
            }
            Log.i(TAG, "Ringing for order $orderId")
            refresh(context)
        }

        /** The order was reassigned to another seller. */
        fun stopForReassign(context: Context, orderId: String) {
            Log.i(TAG, "Order $orderId reassigned, stopping its alert")
            OrderAlertStore.stop(context, orderId)
            refresh(context)
        }

        /** Starts, updates or stops ringing to match the stored alerts. */
        fun refresh(context: Context) {
            val running = instance
            when {
                running != null -> Handler(Looper.getMainLooper()).post { running.refresh() }
                OrderAlertStore.pending(context).isNotEmpty() -> start(context)
                else -> context.getSystemService(NotificationManager::class.java)
                    .cancel(FALLBACK_NOTIFICATION_ID)
            }
        }

        private fun start(context: Context) {
            val intent = Intent(context, OrderAlertService::class.java).setAction(ACTION_REFRESH)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException (Android 12+) when the
                // push wasn't delivered as high priority, or the app is restricted.
                Log.e(TAG, "Couldn't start alert service, showing fallback notification", e)
                postFallback(context)
            }
        }

        private fun createChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            // The service plays the sound and vibration itself, so the channel is silent.
            val main = NotificationChannel(
                CHANNEL_ID,
                "New order alerts",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Rings until you accept a new order."
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            // Used only when the service can't start: Android plays this sound,
            // repeated by FLAG_INSISTENT until the seller opens the app.
            val fallback = NotificationChannel(
                FALLBACK_CHANNEL_ID,
                "New order alerts (backup)",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Rings until you accept a new order."
                setSound(defaultRingtone(context), alarmAudioAttributes())
                enableVibration(true)
                vibrationPattern = VIBRATION_PATTERN
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannels(listOf(main, fallback))
        }

        private fun postFallback(context: Context) {
            val pending = OrderAlertStore.pending(context)
            val next = pending.firstOrNull() ?: return
            createChannels(context)
            @Suppress("DEPRECATION")
            val notification = baseNotification(context, FALLBACK_CHANNEL_ID, next, pending.size)
                // Below Android 8 there are no channels: set on the notification.
                .setSound(defaultRingtone(context), AudioManager.STREAM_ALARM)
                .setVibrate(VIBRATION_PATTERN)
                .build()
                .apply { flags = flags or Notification.FLAG_INSISTENT }
            try {
                context.getSystemService(NotificationManager::class.java)
                    .notify(FALLBACK_NOTIFICATION_ID, notification)
            } catch (e: SecurityException) {
                Log.e(TAG, "Notification permission missing, order ${next.orderId} not shown", e)
            }
        }

        private fun baseNotification(
            context: Context,
            channelId: String,
            order: OrderAlert,
            pendingCount: Int,
        ): Notification.Builder {
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .setAction(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_LAUNCHER)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val more = pendingCount - 1
            @Suppress("DEPRECATION")
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, channelId)
            } else {
                Notification.Builder(context).setPriority(Notification.PRIORITY_MAX)
            }
            return builder
                .setSmallIcon(R.drawable.notification)
                .setContentTitle(order.title)
                .setContentText(order.body)
                .setStyle(Notification.BigTextStyle().bigText(order.body))
                .setSubText(if (more > 0) "+$more more waiting" else null)
                .setCategory(Notification.CATEGORY_CALL)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setContentIntent(open)
                .addAction(Notification.Action.Builder(null, "Open", open).build())
        }

        private fun alarmAudioAttributes(): AudioAttributes =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        private fun defaultRingtone(context: Context): Uri =
            RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE)
                ?: Settings.System.DEFAULT_RINGTONE_URI
    }

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var focusRequest: AudioFocusRequest? = null
    private var pausedForFocusLoss = false
    private var alertedOrderId: String? = null

    private val audioManager by lazy { getSystemService(AudioManager::class.java) }

    private val handler = Handler(Looper.getMainLooper())

    /**
     * Resumes a ring paused for a transient focus loss once no call is going
     * on, even if focus never comes back (whoever took it may have gone away
     * without giving it back, e.g. with the app's own process teardown).
     */
    private val resumeAfterFocusLoss = object : Runnable {
        override fun run() {
            if (!pausedForFocusLoss) return
            if (audioManager.mode == AudioManager.MODE_NORMAL) {
                Log.i(TAG, "No call going on, resuming the ring")
                pausedForFocusLoss = false
                player?.start()
            } else {
                handler.postDelayed(this, FOCUS_RECHECK_MS)
            }
        }
    }

    /** Process still alive after a swipe-away: ring ourselves again. */
    private val takeBackFromFallback = Runnable {
        if (OrderAlertStore.pending(this).isEmpty()) return@Runnable
        Log.i(TAG, "Still running after swipe-away, ringing from the service again")
        getSystemService(NotificationManager::class.java).cancel(FALLBACK_NOTIFICATION_ID)
        startRinging()
    }

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            // A phone call or similar: pause, and pick up again afterwards.
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                player?.takeIf { it.isPlaying }?.let {
                    it.pause()
                    pausedForFocusLoss = true
                    handler.removeCallbacks(resumeAfterFocusLoss)
                    handler.postDelayed(resumeAfterFocusLoss, FOCUS_RECHECK_MS)
                }
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                handler.removeCallbacks(resumeAfterFocusLoss)
                if (pausedForFocusLoss) player?.start()
                pausedForFocusLoss = false
            }
            // Ducking and a permanent loss (another app starting music) don't stop
            // the alert: the order still has to be accepted.
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // startForegroundService() requires startForeground() within a few
        // seconds even when there turns out to be nothing left to ring for.
        if (!goForeground(OrderAlertStore.pending(this))) {
            stopSelf()
            return START_NOT_STICKY
        }
        refresh()
        // Android restarts the service if it kills it; the alerts are on disk.
        return START_STICKY
    }

    /**
     * The seller swiped the app away from recents. Many phones (Xiaomi, Oppo,
     * Vivo, Realme, OnePlus…) then kill the whole process, foreground service
     * included, which silences the ringtone played here. So the insistent
     * system notification takes over: Android keeps ringing it whatever
     * happens to the process. If the process is still alive moments later,
     * the service rings itself again ([takeBackFromFallback]); if it was
     * killed, START_STICKY restarts it and [refresh] does the same.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (OrderAlertStore.pending(this).isEmpty()) return
        Log.i(TAG, "App swiped away with orders waiting, system notification keeps ringing")
        stopRinging()
        postFallback(this)
        handler.removeCallbacks(takeBackFromFallback)
        handler.postDelayed(takeBackFromFallback, SWIPE_HANDOVER_MS)
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        stopRinging()
        instance = null
        super.onDestroy()
    }

    /** Re-reads the pending alerts: updates the notification, or stops. */
    fun refresh() {
        val pending = OrderAlertStore.pending(this)
        getSystemService(NotificationManager::class.java).cancel(FALLBACK_NOTIFICATION_ID)
        if (pending.isEmpty() || !OrderAlertStore.isLoggedIn(this)) {
            Log.i(TAG, "No orders waiting, stopping alert")
            handler.removeCallbacks(takeBackFromFallback)
            stopRinging()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        if (!goForeground(pending)) {
            stopSelf()
            return
        }
        startRinging()
    }

    private fun goForeground(pending: List<OrderAlert>): Boolean {
        val notification = buildNotification(pending)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "startForeground refused, showing fallback notification", e)
            postFallback(this)
            false
        }
    }

    private fun buildNotification(pending: List<OrderAlert>): Notification {
        // The order that has waited longest is shown first.
        val next = pending.firstOrNull()
        if (next == null) {
            @Suppress("DEPRECATION")
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                Notification.Builder(this)
            }
            return builder
                .setSmallIcon(R.drawable.notification)
                .setContentTitle("Checking new orders…")
                .build()
        }
        // Android 14+ lets the seller swipe even this away: show it again.
        val reshow = PendingIntent.getService(
            this,
            0,
            Intent(this, OrderAlertService::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = baseNotification(this, CHANNEL_ID, next, pending.size)
            .setDeleteIntent(reshow)
            // Pop up again only for a new order, not on every refresh.
            .setOnlyAlertOnce(alertedOrderId == next.orderId)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
        alertedOrderId = next.orderId
        return builder.build().apply {
            // Swiping the notification away must not hide a pending order.
            flags = flags or Notification.FLAG_NO_CLEAR or Notification.FLAG_ONGOING_EVENT
        }
    }

    private fun startRinging() {
        if (player == null) {
            requestAudioFocus()
            player = createPlayer()
            if (player == null) Log.e(TAG, "No ringtone could be played, vibrating only")
        }
        if (vibrator == null) startVibration()
    }

    private fun stopRinging() {
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
        pausedForFocusLoss = false
        handler.removeCallbacks(resumeAfterFocusLoss)
        vibrator?.cancel()
        vibrator = null
        abandonAudioFocus()
    }

    /** The phone's ringtone, falling back to the alarm sound, then the app's own sound. */
    private fun createPlayer(): MediaPlayer? {
        val candidates = listOfNotNull(
            RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE),
            Settings.System.DEFAULT_RINGTONE_URI,
            Settings.System.DEFAULT_ALARM_ALERT_URI,
            Uri.parse("android.resource://$packageName/${R.raw.notification_sound}"),
        )
        for (uri in candidates) {
            val mediaPlayer = MediaPlayer()
            try {
                mediaPlayer.setAudioAttributes(alarmAudioAttributes())
                mediaPlayer.setDataSource(this, uri)
                mediaPlayer.isLooping = true
                mediaPlayer.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
                mediaPlayer.prepare()
                mediaPlayer.start()
                return mediaPlayer
            } catch (e: Exception) {
                Log.w(TAG, "Couldn't play $uri", e)
                mediaPlayer.release()
            }
        }
        return null
    }

    private fun startVibration() {
        val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        } ?: return
        if (!vib.hasVibrator()) return
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> vib.vibrate(
                VibrationEffect.createWaveform(VIBRATION_PATTERN, 0),
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM),
            )
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> @Suppress("DEPRECATION") vib.vibrate(
                VibrationEffect.createWaveform(VIBRATION_PATTERN, 0),
                alarmAudioAttributes(),
            )
            else -> @Suppress("DEPRECATION") vib.vibrate(VIBRATION_PATTERN, 0, alarmAudioAttributes())
        }
        vibrator = vib
    }

    /** Rings even if focus is refused: the order still needs an answer. */
    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(alarmAudioAttributes())
                .setOnAudioFocusChangeListener(focusListener)
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusListener, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
    }
}
