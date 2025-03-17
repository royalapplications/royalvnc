package com.example.royalvncandroidtest

import java.lang.ref.*
import android.app.*
import android.os.*
import android.util.*
import androidx.activity.compose.*
import androidx.activity.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.input.*
import com.example.royalvncandroidtest.ui.theme.*
import com.royalapps.royalvnc.*

class MainActivity :
    ComponentActivity(),
    VncLoggerDelegate,
    VncConnectionDelegate
{
    private var _user = ""
    private var _pass = ""

    private var _port: Short = 5900

    private var _image: MutableState<ImageBitmap?> = mutableStateOf(null)

    private val _logTag = "RVNC"

    private var _logger = VncLogger(WeakReference(this))
    private var _settings: VncSettings? = null
    private var _connection: VncConnection? = null

    private var _isConnected = mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val context = this

        enableEdgeToEdge()

        setContent {
            var hostname by remember { mutableStateOf("") }
            var username by remember { mutableStateOf("") }
            var password by remember { mutableStateOf("") }

            RoyalVNCAndroidTestTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Column(
                        modifier = Modifier.padding(innerPadding)
                    ) {
                        PersistentTextField(
                            context,
                            key = "Hostname",
                            label = "Hostname",
                            onValueChange = { hostname = it },
                            keyboardAutoCorrect = false,
                            keyboardCapitalization = KeyboardCapitalization.None
                        )

                        PersistentTextField(
                            context,
                            key = "Username",
                            label = "Username",
                            onValueChange = { username = it },
                            keyboardAutoCorrect = false,
                            keyboardCapitalization = KeyboardCapitalization.None
                        )

                        PersistentTextField(
                            context,
                            key = "Password",
                            label = "Password",
                            onValueChange = { password = it },
                            isPassword = true,
                            keyboardAutoCorrect = false,
                            keyboardCapitalization = KeyboardCapitalization.None
                        )

                        Button(
                            onClick = {
                                connect(
                                    hostname,
                                    _port,
                                    username,
                                    password
                                )
                            },
                        ) {
                            Text(if (_isConnected.value) "Disconnect" else "Connect")
                        }

                        _image.value?.let {
                            Image(
                                bitmap = it,
                                contentDescription = "Remote Screen"
                            )
                        }
                    }
                }
            }
        }
    }

    fun connect(
        hostname: String,
        port: Short,
        username: String,
        password: String
    ) {
        _user = username
        _pass = password

        _connection?.let {
            it.disconnect()

            return
        }

        val settings = VncSettings(
            true,
            hostname,
            port,
            true,
            true,
            false,
            VncInputMode.FORWARDKEYBOARDSHORTCUTSEVENIFINUSELOCALLY,
            false,
            VncColorDepth.BIT24
        )

        val connection = VncConnection(
            settings,
            _logger
        )

        this._settings = settings
        this._connection = connection

        connection.setDelegate(WeakReference(this))
        connection.connect()
    }

    override fun onDestroy() {
        super.onDestroy()

        _connection?.setDelegate(null)
        _connection?.close()
        _connection = null

        _settings?.close()
        _settings = null

        _logger.close()
    }

    // VncLoggerDelegate Implementation
    override fun log(
        logger: VncLogger,
        logLevel: VncLogLevel,
        message: String
    ) {
        when (logLevel) {
            VncLogLevel.INFO -> Log.i(_logTag, message)
            VncLogLevel.WARNING -> Log.w(_logTag, message)
            VncLogLevel.ERROR -> Log.e(_logTag, message)
            VncLogLevel.DEBUG -> Log.d(_logTag, message)
        }
    }

    // VncConnectionDelegate Implementation
    override fun connectionStateDidChange(
        connection: VncConnection,
        connectionState: VncConnectionState
    ) {
        val connectionStatus = connectionState.status

        val connectionStatusStr = when (connectionStatus) {
            VncConnectionStatus.DISCONNECTED -> "Disconnected"
            VncConnectionStatus.CONNECTING -> "Connecting"
            VncConnectionStatus.CONNECTED -> "Connected"
            VncConnectionStatus.DISCONNECTING -> "Disconnecting"
        }

        val errorDescription = connectionState.errorDescription

        Log.d(_logTag, "connectionStateDidChange (connectionStatus: $connectionStatus; connectionStatusStr: $connectionStatusStr; errorDescription: $errorDescription)")

        runOnUiThread {
            _isConnected.value = connectionStatus == VncConnectionStatus.CONNECTING || connectionStatus == VncConnectionStatus.CONNECTED || connectionStatus == VncConnectionStatus.DISCONNECTING

            if (connectionState.shouldDisplayToUser) {
                AlertDialog.Builder(this)
                    .setTitle("Error")
                    .setMessage(errorDescription)
                    .setPositiveButton(android.R.string.ok) { dialog, which ->

                    }
                    .show()
            }

            if (connectionStatus == VncConnectionStatus.DISCONNECTED) {
                _image.value = null

                _connection?.close()
                _connection = null

                _settings?.close()
                _settings = null
            }
        }
    }

    override fun authenticate(
        connection: VncConnection,
        authenticationRequest: VncAuthenticationRequest
    ) {
        Log.d(_logTag, "authenticate (authenticationType: ${authenticationRequest.authenticationType}; requiresUsername: ${authenticationRequest.authenticationType.requiresUsername}; requiresPassword: ${authenticationRequest.authenticationType.requiresPassword})")

        if (authenticationRequest.requiresUsername) {
            authenticationRequest.completeWithUsernameAndPassword(
                _user,
                _pass
            )
        } else {
            authenticationRequest.completeWithPassword(
                _pass
            )
        }
    }

    override fun didCreateFramebuffer(
        connection: VncConnection,
        framebuffer: VncFramebuffer
    ) {
        Log.d(_logTag, "didCreateFramebuffer (width: ${framebuffer.width}; height: ${framebuffer.height})")
    }

    override fun didResizeFramebuffer(
        connection: VncConnection,
        framebuffer: VncFramebuffer
    ) {
        Log.d(_logTag, "didResizeFramebuffer (width: ${framebuffer.width}; height: ${framebuffer.height})")
    }

    override fun didUpdateFramebuffer(
        connection: VncConnection,
        framebuffer: VncFramebuffer,
        x: Short,
        y: Short,
        width: Short,
        height: Short
    ) {
        Log.d(_logTag, "didUpdateFramebuffer (x: $x; y: $y; width: $width; height: $height)")

        val bitmap = framebuffer.bitmap

        runOnUiThread {
            _image.value = bitmap.asImageBitmap()
        }
    }

    override fun didUpdateCursor(
        connection: VncConnection,
        cursor: VncCursor
    ) {
        Log.d(_logTag, "didUpdateCursor (width: ${cursor.width}; height: ${cursor.height})")
    }
}