package com.forroemmilao.radiofem

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import com.forroemmilao.radiofem.ui.RadioFemRoot

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AppContent()
        }
    }
}

@Composable
private fun AppContent() {
    RadioFemRoot()
}
