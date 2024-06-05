package com.example.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.intent.action.BOOT_COMPLETED") {
            val sharedPreferences = context.getSharedPreferences("AlarmPrefs", Context.MODE_PRIVATE)
            val time = sharedPreferences.getLong("alarm_time", 0)
            val title = sharedPreferences.getString("alarm_title", "Alarm")
            val message = sharedPreferences.getString("alarm_message", "This is your scheduled alarm.")

            if (time > 0) {
                val mainActivity = MainActivity()
                mainActivity.scheduleAlarm(context, time, title ?: "Alarm", message ?: "This is your scheduled alarm.")
            }
        }
    }
}
