package com.forroemmilao.radiofemwatchbridge

data class BridgeResponse(
    val ok: Boolean,
    val message: String,
    val volume: Float,
    val isPlaying: Boolean,
)

data class BridgeStatus(
    val bridgeRunning: Boolean = false,
    val isPlaying: Boolean = false,
    val volume: Float = 1.0f,
    val lastMessage: String = "Ponte desligada",
)

object BridgeConfig {
    const val streamUrl = "https://radio.forroemmilao.com/listen/radiofem/android.mp3"
    const val bridgeHost = "127.0.0.1"
    const val bridgePort = 43871
    const val bridgeKey = "radiofem-watch-bridge-v1"
}
