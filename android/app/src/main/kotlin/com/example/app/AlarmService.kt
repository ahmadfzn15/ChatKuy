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

class AlarmService : Service(), TextToSpeech.OnInitListener {
    private val CHANNEL_ID = "AlarmChannel"
    private lateinit var textToSpeech: TextToSpeech
    private var messageToSpeak: String? = null
    private var stopMessage: String? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isTTSInitialized: Boolean = false
    private var shouldLoop: Boolean = true

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        textToSpeech = TextToSpeech(this, this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val requestCode = intent?.getIntExtra("requestCode", 0) ?: 0
        val title = intent?.getStringExtra("title") ?: "Alarm"
        val message = intent?.getStringExtra("message") ?: "Ini adalah alarm yang dijadwalkan Anda."
        messageToSpeak = message
        stopMessage = intent?.getStringExtra("stop_message")

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, requestCode, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.launch_background)
            .setContentIntent(pendingIntent)
            .build()

        startForeground(1, notification)

        val repeatDays = intent?.getIntegerArrayListExtra("repeat")
        if (repeatDays != null) {
            scheduleNextAlarm(this, repeatDays, title, message, requestCode, intent.getIntExtra("hour", 0), intent.getIntExtra("minute", 0))
            saveAlarm(this, intent.getIntExtra("hour", 0), intent.getIntExtra("minute", 0), title, message, stopMessage ?: "", repeatDays, requestCode)
        }

        startSpeechRecognition()

        return START_STICKY
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTTSInitialized = true
            textToSpeech.language = Locale("id", "ID")
            loopMessage()
        } else {
            Log.e("TextToSpeech", "Initialization failed")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        handler.removeCallbacksAndMessages(null)
        if (::textToSpeech.isInitialized) {
            textToSpeech.stop()
            textToSpeech.shutdown()
        }
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
        val speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale("id", "ID"))
        }
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}

            override fun onError(error: Int) {
                handler.postDelayed({ startSpeechRecognition() }, 3000)
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null) {
                    val recognizedText = matches[0]
                    if (recognizedText.equals(stopMessage, ignoreCase = true)) {
                        shouldLoop = false
                        stopAlarm()
                    } else {
                        startSpeechRecognition()
                    }
                } else {
                    startSpeechRecognition()
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        speechRecognizer.startListening(recognizerIntent)
    }

    private fun loopMessage() {
        if (shouldLoop && isTTSInitialized) {
            val words = messageToSpeak?.split(" ")?.size ?: 0
            val wordsPerMinute = 150.0
            val millisecondsPerWord = (60000 / wordsPerMinute).toLong()
            val estimatedDuration = words * millisecondsPerWord

            textToSpeech.speak(messageToSpeak, TextToSpeech.QUEUE_FLUSH, null, null)

            handler.postDelayed({
                if (shouldLoop) {
                    handler.postDelayed({ loopMessage() }, 3000)
                }
            }, estimatedDuration)
        }
    }

    private fun stopAlarm() {
        stopForeground(true)
        stopSelf()
    }
}
