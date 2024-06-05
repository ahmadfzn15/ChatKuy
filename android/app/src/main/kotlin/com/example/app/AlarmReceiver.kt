package com.example.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title")
        val message = intent.getStringExtra("message")
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra("title", title)
            putExtra("message", message)
        }
        context.startForegroundService(serviceIntent)
    }
}
