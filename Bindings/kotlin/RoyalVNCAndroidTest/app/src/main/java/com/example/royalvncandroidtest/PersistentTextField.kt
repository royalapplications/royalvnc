package com.example.royalvncandroidtest

import android.content.*
import androidx.compose.foundation.text.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.text.input.*
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

private val Context.dataStore by preferencesDataStore(
    name = "RoyalVNCAndroidTest"
)

private suspend fun saveText(context: Context, key: String, value: String) {
    context.dataStore.edit { preferences ->
        preferences[stringPreferencesKey(key)] = value
    }
}

private fun getText(context: Context, key: String): Flow<String> {
    return context.dataStore.data.map { preferences ->
        preferences[stringPreferencesKey(key)] ?: ""
    }
}

@Composable
fun PersistentTextField(
    context: Context,
    key: String,
    label: String = "",
    onValueChange: ((String) -> Unit)? = null,
    isPassword: Boolean = false,
    keyboardAutoCorrect: Boolean = true,
    keyboardCapitalization: KeyboardCapitalization = KeyboardCapitalization.Unspecified
) {
    val textFlow = remember { getText(context, key) }
    val text by textFlow.collectAsState(initial = "")

    var textState by remember { mutableStateOf(text) }

    LaunchedEffect(text) {
        textState = text

        onValueChange?.invoke(text)
    }

    OutlinedTextField(
        value = textState,
        label = { Text(label) },
        onValueChange = {
            textState = it

            CoroutineScope(Dispatchers.IO).launch {
                saveText(context, key, it)
            }

            onValueChange?.invoke(it)
        },
        visualTransformation = if (isPassword) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = KeyboardOptions(
            keyboardType = if (isPassword) KeyboardType.Password else KeyboardType.Text,
            autoCorrectEnabled = keyboardAutoCorrect,
            capitalization = keyboardCapitalization
        )
    )
}