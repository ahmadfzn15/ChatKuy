package com.example.app

import android.app.Service
import android.content.Intent
import android.os.*
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SpeechRecognitionService : Service(), RecognitionListener {
    private lateinit var speechRecognizer: SpeechRecognizer
    private var methodChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private var stopMessage: String? = null
    private var isListening = false
    private val retryDelay: Long = 1000 // Delay before retrying listening

    override fun onCreate() {
        super.onCreate()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(this)

        val flutterEngine: FlutterEngine? = FlutterEngineCache.getInstance().get("my_engine_id")
        if (flutterEngine != null) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.app/alarm")
        } else {
            Log.e("SpeechRecognitionService", "Flutter engine is null")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        stopMessage = intent?.getStringExtra("stop_message")
        if (!isListening) {
            startListening()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun startListening() {
        if (!isListening) {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "id-ID")
            }
            speechRecognizer.startListening(intent)
            isListening = true
        }
    }

    override fun onReadyForSpeech(params: Bundle?) {
        Log.d("SpeechRecognitionService", "Ready for speech")
    }

    override fun onBeginningOfSpeech() {
        Log.d("SpeechRecognitionService", "Speech started")
    }

    override fun onRmsChanged(rmsdB: Float) {
        Log.d("SpeechRecognitionService", "RMS changed: $rmsdB")
    }

    override fun onBufferReceived(buffer: ByteArray?) {
        Log.d("SpeechRecognitionService", "Buffer received")
    }

    override fun onEndOfSpeech() {
        Log.d("SpeechRecognitionService", "Speech ended")
        isListening = false
        handler.postDelayed({ startListening() }, retryDelay)
    }

    override fun onError(error: Int) {
        Log.d("SpeechRecognitionService", "Error: $error")
        isListening = false
        val delay = when (error) {
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> retryDelay * 2
            else -> retryDelay
        }
        handler.postDelayed({ startListening() }, delay)
    }

    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        matches?.forEach { result ->
            Log.d("SpeechRecognitionService", "Result: $result")
            methodChannel?.invokeMethod("onSpeechResult", result)
            stopMessage?.let {
                if (result.contains(it, ignoreCase = true)) {
                    val alarmServiceIntent = Intent(this, AlarmService::class.java)
                    stopService(alarmServiceIntent)
                    stopSelf()
                    Log.d("SpeechRecognitionService", "Alarm Stopped")
                }
            }
        }
        isListening = false
        handler.postDelayed({ startListening() }, retryDelay)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isListening) {
            speechRecognizer.stopListening()
        }
        speechRecognizer.destroy()
        Log.d("SpeechRecognitionService", "Service Destroyed")
    }

    override fun onPartialResults(partialResults: Bundle?) {
        Log.d("SpeechRecognitionService", "Partial results received")
    }

    override fun onEvent(eventType: Int, params: Bundle?) {
        Log.d("SpeechRecognitionService", "Event received: $eventType")
    }
}
