// android/app/src/main/kotlin/com/rfivesix/hypertrack/MainActivity.kt

package com.rfivesix.hypertrack

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant

class MainActivity: FlutterActivity() {
    private val channelName = "hypertrack.health/steps"
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val requiredPermissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
    )

    private val permissionLauncher = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { _: Set<String> ->
        val result = pendingPermissionResult ?: return@registerForActivityResult
        pendingPermissionResult = null
        CoroutineScope(Dispatchers.IO).launch {
            val granted = hasAllPermissions()
            withContext(Dispatchers.Main) {
                result.success(granted)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailability" -> handleAvailability(result)
                "requestPermissions" -> handleRequestPermissions(result)
                "readStepSegments" -> handleReadSegments(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleAvailability(result: MethodChannel.Result) {
        val status = HealthConnectClient.getSdkStatus(this)
        result.success(status == HealthConnectClient.SDK_AVAILABLE)
    }

    private fun handleRequestPermissions(result: MethodChannel.Result) {
        val status = HealthConnectClient.getSdkStatus(this)
        if (status != HealthConnectClient.SDK_AVAILABLE) {
            result.error("not_available", "Health Connect not available", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            val alreadyGranted = hasAllPermissions()
            if (alreadyGranted) {
                withContext(Dispatchers.Main) { result.success(true) }
                return@launch
            }

            withContext(Dispatchers.Main) {
                pendingPermissionResult = result
                permissionLauncher.launch(requiredPermissions)
            }
        }
    }

    private fun handleReadSegments(call: MethodCall, result: MethodChannel.Result) {
        val status = HealthConnectClient.getSdkStatus(this)
        if (status != HealthConnectClient.SDK_AVAILABLE) {
            result.error("not_available", "Health Connect not available", null)
            return
        }

        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
        val fromIso = args["fromUtcIso"] as? String
        val toIso = args["toUtcIso"] as? String
        if (fromIso == null || toIso == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            val hasPermission = hasAllPermissions()
            if (!hasPermission) {
                withContext(Dispatchers.Main) {
                    result.error("permission_denied", "Permissions not granted", null)
                }
                return@launch
            }

            try {
                val client = HealthConnectClient.getOrCreate(this@MainActivity)
                val from = Instant.parse(fromIso)
                val to = Instant.parse(toIso)
                val response = client.readRecords(
                    ReadRecordsRequest(
                        recordType = StepsRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(from, to)
                    )
                )

                val payload = response.records.map { record ->
                    mapOf(
                        "startAtUtcIso" to record.startTime.toString(),
                        "endAtUtcIso" to record.endTime.toString(),
                        "stepCount" to record.count.toInt(),
                        "sourceId" to record.metadata.dataOrigin.packageName,
                        "nativeId" to record.metadata.id
                    )
                }
                withContext(Dispatchers.Main) {
                    result.success(payload)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("permission_denied", e.message, null)
                }
            }
        }
    }

    private suspend fun hasAllPermissions(): Boolean {
        val status = HealthConnectClient.getSdkStatus(this)
        if (status != HealthConnectClient.SDK_AVAILABLE) return false
        val granted = HealthConnectClient.getOrCreate(this)
            .permissionController
            .getGrantedPermissions()
        return granted.containsAll(requiredPermissions)
    }
}
