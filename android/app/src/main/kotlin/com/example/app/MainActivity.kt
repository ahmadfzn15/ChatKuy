package com.example.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.*
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app/alarm"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scheduleAlarm") {
                val requestCode = call.argument<Int>("requestCode")!!
                val hour = call.argument<Int>("hour")!!
                val minute = call.argument<Int>("minute")!!
                val title = call.argument<String>("title")!!
                val message = call.argument<String>("message")!!
                val stopMessage = call.argument<String>("stop_message")!!
                val repeat = call.argument<List<Int>>("repeat")!!

                scheduleAlarm(context, requestCode, hour, minute, title, message, stopMessage, repeat)
                result.success(null)
            } else if (call.method == "record") {
                val message = call.argument<String>("stop_message")!!
                record(context, message)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun scheduleAlarm(context: Context, requestCode: Int, hour: Int, minute: Int, title: String, message: String, stopMessage: String, repeat: List<Int>) {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, hour)
        calendar.set(Calendar.MINUTE, minute)
        calendar.set(Calendar.SECOND, 0)
        if (calendar.timeInMillis <= System.currentTimeMillis()) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("requestCode", requestCode)
            putExtra("title", title)
            putExtra("message", message)
            putExtra("stop_message", stopMessage)
            putIntegerArrayListExtra("repeat", ArrayList(repeat))
        }
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
    }

    private fun record(context: Context, message: String) {
        val speechIntent = Intent(this, SpeechRecognitionService::class.java).apply {
            putExtra("stop_message", message)
        }

        startService(speechIntent)
    }
}
