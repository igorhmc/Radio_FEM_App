package com.forroemmilao.radiofemwatchbridge

import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.URI
import java.nio.charset.StandardCharsets
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.json.JSONObject

class LocalHttpBridgeServer(
    private val statusProvider: () -> BridgeStatus,
    private val commandHandler: (String) -> BridgeResponse,
) {
    private val executor: ExecutorService = Executors.newCachedThreadPool()
    @Volatile
    private var serverSocket: ServerSocket? = null

    fun start() {
        if (serverSocket != null) {
            return
        }

        val socket = ServerSocket()
        socket.reuseAddress = true
        socket.bind(
            InetSocketAddress(
                InetAddress.getByName(BridgeConfig.bridgeHost),
                BridgeConfig.bridgePort,
            ),
        )
        serverSocket = socket

        executor.execute {
            while (!socket.isClosed) {
                val client = runCatching { socket.accept() }.getOrNull() ?: break
                executor.execute {
                    handleClient(client)
                }
            }
        }
    }

    fun stop() {
        serverSocket?.close()
        serverSocket = null
        executor.shutdownNow()
    }

    private fun handleClient(socket: Socket) {
        socket.use { client ->
            val reader = BufferedReader(InputStreamReader(client.getInputStream()))
            val requestLine = reader.readLine() ?: return
            var line: String?
            do {
                line = reader.readLine()
            } while (!line.isNullOrEmpty())

            val parts = requestLine.split(" ")
            val method = parts.getOrNull(0).orEmpty()
            val target = parts.getOrNull(1).orEmpty()
            val uri = URI("http://${BridgeConfig.bridgeHost}$target")

            val response = route(method, uri)
            writeResponse(client, response.statusCode, response.body)
        }
    }

    private fun route(method: String, uri: URI): HttpResponse {
        if (method != "GET") {
            return HttpResponse(405, jsonBody(false, "Only GET is supported"))
        }

        if (!isAuthorized(uri)) {
            return HttpResponse(401, jsonBody(false, "Invalid bridge key"))
        }

        return when {
            uri.path == "/status" -> {
                val status = statusProvider()
                HttpResponse(
                    200,
                    JSONObject()
                        .put("ok", true)
                        .put("bridgeRunning", status.bridgeRunning)
                        .put("isPlaying", status.isPlaying)
                        .put("volume", status.volume.toDouble())
                        .put("message", status.lastMessage)
                        .toString(),
                )
            }
            uri.path.startsWith("/command/") -> {
                val command = uri.path.removePrefix("/command/").trim()
                if (command.isEmpty()) {
                    HttpResponse(404, jsonBody(false, "Missing command"))
                } else {
                    val result = commandHandler(command)
                    HttpResponse(
                        if (result.ok) 200 else 400,
                        JSONObject()
                            .put("ok", result.ok)
                            .put("message", result.message)
                            .put("volume", result.volume.toDouble())
                            .put("isPlaying", result.isPlaying)
                            .toString(),
                    )
                }
            }
            else -> HttpResponse(404, jsonBody(false, "Unknown route"))
        }
    }

    private fun isAuthorized(uri: URI): Boolean {
        val query = uri.rawQuery.orEmpty()
        val params = query
            .split("&")
            .filter { it.contains("=") }
            .associate {
                val pair = it.split("=", limit = 2)
                pair[0] to pair[1]
            }
        return params["key"] == BridgeConfig.bridgeKey
    }

    private fun writeResponse(socket: Socket, statusCode: Int, body: String) {
        val payload = body.toByteArray(StandardCharsets.UTF_8)
        val statusText = when (statusCode) {
            200 -> "OK"
            400 -> "Bad Request"
            401 -> "Unauthorized"
            404 -> "Not Found"
            405 -> "Method Not Allowed"
            else -> "Internal Server Error"
        }
        val headers = buildString {
            append("HTTP/1.1 $statusCode $statusText\r\n")
            append("Content-Type: application/json; charset=utf-8\r\n")
            append("Cache-Control: no-store\r\n")
            append("Connection: close\r\n")
            append("Content-Length: ${payload.size}\r\n")
            append("\r\n")
        }
        socket.getOutputStream().use { output ->
            output.write(headers.toByteArray(StandardCharsets.UTF_8))
            output.write(payload)
            output.flush()
        }
    }

    private fun jsonBody(ok: Boolean, message: String): String =
        JSONObject().put("ok", ok).put("message", message).toString()
}

private data class HttpResponse(
    val statusCode: Int,
    val body: String,
)
