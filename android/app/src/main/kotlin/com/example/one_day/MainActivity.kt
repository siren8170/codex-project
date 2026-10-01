package com.example.one_day

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// 외부 패키지 없이 Android 기본 API로 마이크 권한, 녹음, 재생, 앱 내부 저장소, 내보내기를 제공한다.
class MainActivity : FlutterActivity() {
    private var recorder: MediaRecorder? = null
    private var outputPath: String? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var player: MediaPlayer? = null
    private var pendingExport: Pair<String, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestPermission(result)
                    "recordingsDirectory" -> {
                        // 앱 내부 저장소: 앱을 삭제하기 전까지 유지되고 다른 앱이 접근할 수 없다.
                        val dir = File(filesDir, "recordings")
                        dir.mkdirs()
                        result.success(dir.absolutePath)
                    }
                    "start" -> start(call.argument<String>("path"), result)
                    "stop" -> stop(result)
                    "play" -> play(call.argument<String>("path"), result)
                    "stopPlayback" -> {
                        releasePlayer()
                        result.success(null)
                    }
                    "playbackStatus" -> playbackStatus(result)
                    "export" -> export(
                        call.argument<String>("path"),
                        call.argument<String>("fileName"),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingPermission != null) {
            result.error("PERMISSION_PENDING", "권한 요청이 이미 진행 중입니다.", null)
            return
        }
        pendingPermission = result
        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermission?.success(granted)
        pendingPermission = null
    }

    private fun start(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("INVALID_PATH", "저장 경로가 없습니다.", null)
            return
        }
        if (recorder != null) {
            result.error("ALREADY_RECORDING", "이미 녹음 중입니다.", null)
            return
        }
        val newRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        try {
            newRecorder.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioEncodingBitRate(128000)
                setOutputFile(path)
                prepare()
                start()
            }
            recorder = newRecorder
            outputPath = path
            result.success(null)
        } catch (e: Exception) {
            newRecorder.release()
            File(path).delete()
            result.error("START_FAILED", e.message, null)
        }
    }

    private fun stop(result: MethodChannel.Result) {
        val current = recorder
        val path = outputPath
        if (current == null || path == null) {
            result.error("NOT_RECORDING", "녹음 중이 아닙니다.", null)
            return
        }
        recorder = null
        outputPath = null
        try {
            current.stop()
            result.success(path)
        } catch (e: RuntimeException) {
            // 녹음이 너무 짧으면 유효한 오디오가 만들어지지 않는다. 깨진 파일만 정리한다.
            File(path).delete()
            result.error("STOP_FAILED", "녹음이 너무 짧아 저장하지 못했습니다.", null)
        } finally {
            current.release()
        }
    }

    private fun play(path: String?, result: MethodChannel.Result) {
        if (path == null || !File(path).exists()) {
            result.error("NOT_FOUND", "녹음 파일이 없습니다.", null)
            return
        }
        releasePlayer()
        val newPlayer = MediaPlayer()
        try {
            newPlayer.setDataSource(path)
            newPlayer.prepare()
            newPlayer.start()
            player = newPlayer
            result.success(newPlayer.duration)
        } catch (e: Exception) {
            newPlayer.release()
            result.error("PLAY_FAILED", e.message, null)
        }
    }

    private fun playbackStatus(result: MethodChannel.Result) {
        val current = player
        if (current == null) {
            result.success(mapOf("position" to 0, "duration" to 0, "playing" to false))
            return
        }
        result.success(
            mapOf(
                "position" to current.currentPosition,
                "duration" to current.duration,
                "playing" to current.isPlaying,
            ),
        )
    }

    private fun releasePlayer() {
        player?.release()
        player = null
    }

    /// 시스템 "다른 이름으로 저장" 창(파일 앱)을 다운로드 폴더에서 연다.
    private fun export(path: String?, fileName: String?, result: MethodChannel.Result) {
        if (path == null || fileName == null || !File(path).exists()) {
            result.error("NOT_FOUND", "녹음 파일이 없습니다.", null)
            return
        }
        if (pendingExport != null) {
            result.error("EXPORT_PENDING", "내보내기가 이미 진행 중입니다.", null)
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/mp4"
            putExtra(Intent.EXTRA_TITLE, fileName)
            putExtra(
                DocumentsContract.EXTRA_INITIAL_URI,
                DocumentsContract.buildDocumentUri(
                    "com.android.externalstorage.documents",
                    "primary:Download",
                ),
            )
        }
        pendingExport = path to result
        @Suppress("DEPRECATION")
        startActivityForResult(intent, EXPORT_REQUEST)
    }

    @Deprecated("FlutterActivity는 아직 이 콜백으로 결과를 전달한다.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != EXPORT_REQUEST) return
        val (path, result) = pendingExport ?: return
        pendingExport = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(false)
            return
        }
        try {
            val output = contentResolver.openOutputStream(uri)
                ?: throw IllegalStateException("저장 위치를 열 수 없습니다.")
            output.use { out -> File(path).inputStream().use { it.copyTo(out) } }
            result.success(true)
        } catch (e: Exception) {
            result.error("EXPORT_FAILED", e.message, null)
        }
    }

    override fun onDestroy() {
        recorder?.release()
        recorder = null
        releasePlayer()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "one_day/audio"
        private const val PERMISSION_REQUEST = 1001
        private const val EXPORT_REQUEST = 1002
    }
}
