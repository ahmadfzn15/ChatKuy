package com.example.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra("requestCode", intent.getIntExtra("requestCode", 0))
            putExtra("title", intent.getStringExtra("title"))
            putExtra("message", intent.getStringExtra("message"))
            putExtra("stop_message", intent.getStringExtra("stop_message"))
            putIntegerArrayListExtra("repeat", intent.getIntegerArrayListExtra("repeat"))
        }
        context.startForegroundService(serviceIntent)
    }
}
