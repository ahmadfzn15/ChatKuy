package com.example.app

import android.app.*
import android.content.*
import android.os.*
import android.speech.*
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.*
import java.util.*
import io.flutter.plugin.common.MethodChannel

class AlarmService : Service(), TextToSpeech.OnInitListener {
    private val CHANNEL_ID = "AlarmChannel"
    private lateinit var textToSpeech: TextToSpeech
    private var messageToSpeak: String? = null
    private var stopMessage: String? = null
    private lateinit var methodChannel: MethodChannel
    private val handler = Handler(Looper.getMainLooper())
    private var isTTSInitialized: Boolean = false
    private var shouldLoop: Boolean = true
    private var isListening: Boolean = false
    private lateinit var speechIntent: Intent

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        textToSpeech = TextToSpeech(this, this)
        speechIntent = Intent(this, SpeechRecognitionService::class.java)
        Log.d("AlarmService", "Service Created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val requestCode = intent?.getIntExtra("requestCode", 0) ?: 0
        val title = intent?.getStringExtra("title") ?: "Alarm"
        val message = intent?.getStringExtra("message") ?: "Ini adalah alarm yang dijadwalkan Anda."
        messageToSpeak = message
        stopMessage = intent?.getStringExtra("stop_message")

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, requestCode, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        val stopIntent = Intent(this, AlarmStopReceiver::class.java)
        val stopPendingIntent = PendingIntent.getBroadcast(this, requestCode, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.launch_background)
            .setContentIntent(pendingIntent)
            .addAction(0, "Stop", stopPendingIntent)
            .build()

        startForeground(1, notification)
        Log.d("AlarmService", "Notification started")

        val repeatDays = intent?.getIntegerArrayListExtra("repeat")
        if (repeatDays != null) {
            scheduleNextAlarm(this, repeatDays, title, message, requestCode, intent.getIntExtra("hour", 0), intent.getIntExtra("minute", 0))
            saveAlarm(this, intent.getIntExtra("hour", 0), intent.getIntExtra("minute", 0), title, message, stopMessage ?: "", repeatDays, requestCode)
        }

        startSpeechRecognition()
        loopMessage()
        startVibration()
        return START_STICKY
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTTSInitialized = true
            textToSpeech.language = Locale("id", "ID")
            Log.d("AlarmService", "TTS Initialized")
            if (shouldLoop) loopMessage()
        } else {
            Log.e("TextToSpeech", "Initialization failed")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        handler.removeCallbacksAndMessages(null)
        Log.d("AlarmService", "Service Destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun scheduleNextAlarm(context: Context, repeatDays: ArrayList<Int>, title: String, message: String, requestCode: Int, hour: Int, minute: Int) {
        val nextAlarmTime = getNextAlarmTime(repeatDays, hour, minute)

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("message", message)
            putExtra("stop_message", stopMessage)
            putIntegerArrayListExtra("repeat", repeatDays)
            putExtra("requestCode", requestCode)
            putExtra("hour", hour)
            putExtra("minute", minute)
        }
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextAlarmTime, pendingIntent)
    }

    private fun saveAlarm(context: Context, hour: Int, minute: Int, title: String, message: String, stopMessage: String, repeatDays: ArrayList<Int>, requestCode: Int) {
        val sharedPreferences = context.getSharedPreferences("AlarmPrefs", Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()

        val alarmsArray = JSONArray(sharedPreferences.getString("alarms", "[]"))
        val alarmObject = JSONObject().apply {
            put("hour", hour)
            put("minute", minute)
            put("title", title)
            put("message", message)
            put("stopMessage", stopMessage)
            put("repeat", JSONArray(repeatDays))
            put("requestCode", requestCode)
        }
        alarmsArray.put(alarmObject)

        editor.putString("alarms", alarmsArray.toString())
        editor.apply()
    }

    private fun getNextAlarmTime(repeatDays: ArrayList<Int>, hour: Int, minute: Int): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        val currentDay = calendar.get(Calendar.DAY_OF_WEEK)

        while (!repeatDays.contains(currentDay)) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }

        return calendar.timeInMillis
    }

    private fun startSpeechRecognition() {
        if (isListening) {
            stopService(speechIntent)
            isListening = false
        }
        speechIntent.putExtra("stop_message", stopMessage)
        startService(speechIntent)
        isListening = true
    }

    private fun loopMessage() {
        if (shouldLoop && isTTSInitialized) {
            val words = messageToSpeak?.split(" ")?.size ?: 0
            val wordsPerMinute = 150.0
            val millisecondsPerWord = (60000 / wordsPerMinute).toLong()
            val estimatedDuration = words * millisecondsPerWord

            textToSpeech.speak(messageToSpeak, TextToSpeech.QUEUE_FLUSH, null, null)

            handler.postDelayed({
                startSpeechRecognition()
                handler.postDelayed({
                    stopService(speechIntent)
                    loopMessage()
                }, 4000)
            }, estimatedDuration)
        }
    }

    private fun startVibration() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        val vibrationPattern = longArrayOf(0, 500, 1000)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val vibrationEffect = VibrationEffect.createWaveform(vibrationPattern, 0)
            vibrator.vibrate(vibrationEffect)
        } else {
            vibrator.vibrate(vibrationPattern, 0)
        }
    }

    private fun stopVibration() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        vibrator.cancel()
    }

    private fun stopAlarm() {
        shouldLoop = false
        if (::textToSpeech.isInitialized) {
            textToSpeech.stop()
            textToSpeech.shutdown()
        }
        stopForeground(true)
        stopSelf()
        stopVibration()
    }
}
