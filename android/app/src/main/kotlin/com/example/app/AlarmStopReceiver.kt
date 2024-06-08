package com.example.app

import android.content.*

class AlarmStopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val stopIntent = Intent(context, AlarmService::class.java)
        context?.stopService(stopIntent)
    }
}
