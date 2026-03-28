package com.company.sevekam

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        if (manager.getNotificationChannel(GENERAL_CHANNEL_ID) == null) {
            val soundingChannel = NotificationChannel(
                GENERAL_CHANNEL_ID,
                "General notifications",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Sevakam updates, booking activity, support replies, and messages."
                enableVibration(true)
                setShowBadge(true)
            }
            manager.createNotificationChannel(soundingChannel)
        }
        if (manager.getNotificationChannel(SILENT_CHANNEL_ID) == null) {
            val silentChannel = NotificationChannel(
                SILENT_CHANNEL_ID,
                "General notifications (silent)",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Sevakam updates, booking activity, support replies, and messages."
                setSound(null, null)
                enableVibration(true)
                setShowBadge(true)
            }
            manager.createNotificationChannel(silentChannel)
        }
    }

    companion object {
        private const val GENERAL_CHANNEL_ID = "sevakam_general"
        private const val SILENT_CHANNEL_ID = "sevakam_general_silent"
    }
}
