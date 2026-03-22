package com.company.sevekam

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        val existing = manager.getNotificationChannel(GENERAL_CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            GENERAL_CHANNEL_ID,
            "General notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Sevakam updates, booking activity, support replies, and messages."
            enableVibration(true)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val GENERAL_CHANNEL_ID = "sevakam_general"
    }
}
