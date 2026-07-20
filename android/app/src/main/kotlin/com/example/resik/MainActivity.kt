package com.example.resik

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle 
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ BUAT CHANNEL NOTIFIKASI AGAR BISA POP-UP (HEADS-UP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"
            val channelName = "Notifikasi Penting"
            val importance = NotificationManager.IMPORTANCE_HIGH // ✅ KUNCI UTAMA
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Channel ini digunakan agar notifikasi muncul pop-up di layar"
                enableVibration(true)
            }

            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}