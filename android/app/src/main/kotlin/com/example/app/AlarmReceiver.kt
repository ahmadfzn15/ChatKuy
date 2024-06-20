package com.example.app

import android.content.*
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Alarm received")
        val serviceIntent =
                Intent(context, AlarmService::class.java).apply {
                    putExtra("title", intent.getStringExtra("title"))
                    putExtra("message", intent.getStringExtra("message"))
                    putExtra("stop_message", intent.getStringExtra("stop_message"))
                    putIntegerArrayListExtra("repeat", intent.getIntegerArrayListExtra("repeat"))
                    putExtra("requestCode", intent.getIntExtra("requestCode", 0))
                    putExtra("hour", intent.getIntExtra("hour", 0))
                    putExtra("minute", intent.getIntExtra("minute", 0))
                }
        context.startForegroundService(serviceIntent)
    }
}
