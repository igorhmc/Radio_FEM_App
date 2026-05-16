package com.forroemmilao.radiofem

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import com.ryanheise.audioservice.AudioServiceFragmentActivity

class MainActivity : AudioServiceFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
