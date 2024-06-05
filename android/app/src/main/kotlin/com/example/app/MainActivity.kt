package com.example.app

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import android.app.PendingIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/alarm"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scheduleAlarm") {
                val time = call.argument<Long>("time")!!
                val title = call.argument<String>("title")!!
                val message = call.argument<String>("message")!!
                scheduleAlarm(this, time, title, message)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)
    }

    public fun scheduleAlarm(context: Context, timeInMillis: Long, title: String, message: String) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("message", message)
        }
        val pendingIntent = PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeInMillis, pendingIntent)
    }
}
