package com.example.app

import android.app.Service
import android.content.Intent
import android.media.AudioFormat
import android.media.MediaRecorder
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
    private var isListening: Boolean = false

    override fun onCreate() {
        super.onCreate()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(this)

        val flutterEngine: FlutterEngine? = FlutterEngineCache.getInstance().get("my_engine_id")
        if (flutterEngine != null) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.app/alarm")
        } else {
            Log.e("SpeechRecogService", "Flutter engine is null")
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

    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {
        isListening = false
        handler.postDelayed({ startListening() }, 1000)
    }

    override fun onError(error: Int) {
        Log.d("SpeechRecognition", "Error: $error")
        when (error) {
            SpeechRecognizer.ERROR_NO_MATCH -> {
                Log.d("SpeechRecognition", "No speech input")
            }
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                Log.d("SpeechRecognition", "Speech timeout")
            }
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                Log.d("SpeechRecognition", "Recognizer busy")
            }
            else -> {
                Log.d("SpeechRecognition", "Unknown error")
            }
        }
        isListening = false
        handler.postDelayed({ startListening() }, 500)
    }

    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        matches?.forEach { result ->
            Log.d("SpeechRecognition", "Result: $result")
            methodChannel?.invokeMethod("onSpeechResult", result)
            stopMessage?.let {
                if (result.contains(it, ignoreCase = true)) {
                    Log.d("SpeechRecognition", "Stop message found: $result")
                    stopListeningAndShutdown()
                    Log.d("SpeechRecognition", "Alarm Stopped")
                    return@forEach
                }
            }
        }

        isListening = false
        handler.postDelayed({ startListening() }, 150)
    }

    fun stopListeningAndShutdown() {
        isListening = false
        val alarmServiceIntent = Intent(this, AlarmService::class.java)
        stopService(alarmServiceIntent)
        stopSelf()
        speechRecognizer.destroy()
    }
        
    override fun onDestroy() {
        super.onDestroy()
        stopListeningAndShutdown()
    }

    override fun onPartialResults(partialResults: Bundle?) {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
}