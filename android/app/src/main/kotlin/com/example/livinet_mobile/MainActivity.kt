package com.example.livinet_mobile

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Switch from LaunchTheme to NormalTheme after Flutter is attached
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
    }
}
