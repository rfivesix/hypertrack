// android/app/src/main/kotlin/com/rfivesix/hypertrack/MainActivity.kt

package com.rfivesix.hypertrack

import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant

class MainActivity : FlutterFragmentActivity() {
    private val healthChannelName = "hypertrack.health/steps"
    private val storageChannelName = "hypertrack.storage/saf"
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingDirectoryPickerResult: MethodChannel.Result? = null
    private val requiredPermissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
    )

    private val permissionLauncher = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract(),
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

    private val directoryPickerLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocumentTree(),
    ) { uri: Uri? ->
        val result = pendingDirectoryPickerResult ?: return@registerForActivityResult
        pendingDirectoryPickerResult = null
        if (uri == null) {
            result.success(null)
            return@registerForActivityResult
        }
        try {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: Exception) {
            // Persistable permission is best-effort (some providers may reject it).
        }
        result.success(
            mapOf(
                "treeUri" to uri.toString(),
                "displayPath" to treeUriToDisplayPath(uri),
            ),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            healthChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailability" -> handleAvailability(result)
                "requestPermissions" -> handleRequestPermissions(result)
                "readStepSegments" -> handleReadSegments(call, result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            storageChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> handlePickDirectory(result)
                "writeTextFileToTree" -> handleWriteTextFileToTree(call, result)
                "pruneAutoBackupsInTree" -> handlePruneAutoBackupsInTree(call, result)
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
                val allRecords = mutableListOf<StepsRecord>()
                var pageToken: String? = null
                do {
                    val response = client.readRecords(
                        ReadRecordsRequest(
                            recordType = StepsRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(from, to),
                            pageToken = pageToken,
                        ),
                    )
                    allRecords.addAll(response.records)
                    pageToken = response.pageToken
                } while (pageToken != null)

                val payload = allRecords.map { record ->
                    mapOf(
                        "startAtUtcIso" to record.startTime.toString(),
                        "endAtUtcIso" to record.endTime.toString(),
                        "stepCount" to record.count.toInt(),
                        "sourceId" to record.metadata.dataOrigin.packageName,
                        "nativeId" to record.metadata.id,
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

    private fun handlePickDirectory(result: MethodChannel.Result) {
        if (pendingDirectoryPickerResult != null) {
            result.error("busy", "Directory picker already active", null)
            return
        }
        pendingDirectoryPickerResult = result
        directoryPickerLauncher.launch(null)
    }

    private fun handleWriteTextFileToTree(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
        val treeUriRaw = args["treeUri"] as? String
        val fileName = args["fileName"] as? String
        val content = args["content"] as? String
        val mimeType = (args["mimeType"] as? String) ?: "application/json"

        if (treeUriRaw.isNullOrBlank() || fileName.isNullOrBlank() || content == null) {
            result.error("invalid_args", "treeUri, fileName and content are required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val treeUri = Uri.parse(treeUriRaw)
                val root = DocumentFile.fromTreeUri(this@MainActivity, treeUri)
                    ?: throw IllegalStateException("Tree URI is not accessible")
                if (!root.canWrite()) {
                    throw IllegalStateException("Selected folder is not writable")
                }

                root.findFile(fileName)?.delete()
                val created = root.createFile(mimeType, fileName)
                    ?: throw IllegalStateException("Unable to create file in selected folder")

                contentResolver.openOutputStream(created.uri, "wt").use { out ->
                    if (out == null) {
                        throw IllegalStateException("Unable to open output stream")
                    }
                    out.write(content.toByteArray(Charsets.UTF_8))
                    out.flush()
                }

                val displayPath = "${treeUriToDisplayPath(treeUri)}/$fileName"
                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "documentUri" to created.uri.toString(),
                            "displayPath" to displayPath,
                        ),
                    )
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("write_failed", e.message, null)
                }
            }
        }
    }

    private fun handlePruneAutoBackupsInTree(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
        val treeUriRaw = args["treeUri"] as? String
        val filePrefix = (args["filePrefix"] as? String) ?: "hypertrack_auto"
        val retention = (args["retention"] as? Int) ?: 7

        if (treeUriRaw.isNullOrBlank()) {
            result.error("invalid_args", "treeUri is required", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val treeUri = Uri.parse(treeUriRaw)
                val root = DocumentFile.fromTreeUri(this@MainActivity, treeUri)
                    ?: throw IllegalStateException("Tree URI is not accessible")

                val files = mutableListOf<DocumentFile>()
                for (file in root.listFiles()) {
                    if (file.isFile && (file.name?.startsWith(filePrefix) == true)) {
                        files.add(file)
                    }
                }
                files.sortByDescending { file: DocumentFile -> file.lastModified() }

                if (files.size > retention) {
                    for (index in retention until files.size) {
                        runCatching { files[index].delete() }
                    }
                }

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("prune_failed", e.message, null)
                }
            }
        }
    }

    private fun treeUriToDisplayPath(uri: Uri): String {
        return try {
            val docId = DocumentsContract.getTreeDocumentId(uri)
            if (docId.startsWith("primary:")) {
                val relative = docId.removePrefix("primary:")
                if (relative.isBlank()) "/storage/emulated/0"
                else "/storage/emulated/0/$relative"
            } else {
                docId
            }
        } catch (_: Exception) {
            uri.toString()
        }
    }
}
