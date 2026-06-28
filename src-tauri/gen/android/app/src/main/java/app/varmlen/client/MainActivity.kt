package app.varmlen.client

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.enableEdgeToEdge

class MainActivity : TauriActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)
    // The foreground-service notice ("VPN active" + Disconnect) needs this on
    // Android 13+. A visible FGS notification also helps OEMs not kill it.
    if (Build.VERSION.SDK_INT >= 33 &&
      checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
    ) {
      try {
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
      } catch (_: Throwable) {}
    }
  }
}
