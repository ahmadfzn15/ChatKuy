package com.example.app

import android.content.BroadcastReceiver
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import java.util.*

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            resetAlarms(context)
        }
    }

    private fun resetAlarms(context: Context) {
        val sharedPreferences = context.getSharedPreferences("AlarmPrefs", Context.MODE_PRIVATE)
        val alarmsArray = JSONArray(sharedPreferences.getString("alarms", "[]"))

        for (i in 0 until alarmsArray.length()) {
            val alarmObject = alarmsArray.getJSONObject(i)
            val requestCode = alarmObject.getInt("requestCode")
            val hour = alarmObject.getInt("hour")
            val minute = alarmObject.getInt("minute")
            val title = alarmObject.getString("title")
            val message = alarmObject.getString("message")
            val stopMessage = alarmObject.getString("stopMessage")
            val repeatDaysArray = alarmObject.getJSONArray("repeat")

            val repeatDays = ArrayList<Int>()
            for (j in 0 until repeatDaysArray.length()) {
                repeatDays.add(repeatDaysArray.getInt(j))
            }

            val alarmServiceIntent = Intent(context, AlarmService::class.java).apply {
                putExtra("title", title)
                putExtra("message", message)
                putExtra("stop_message", stopMessage)
                putIntegerArrayListExtra("repeat", repeatDays)
                putExtra("requestCode", requestCode)
                putExtra("hour", hour)
                putExtra("minute", minute)
            }
            context.startForegroundService(alarmServiceIntent)
        }
    }
}
