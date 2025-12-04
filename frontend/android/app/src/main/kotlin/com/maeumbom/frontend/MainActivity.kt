package com.maeumbom.frontend

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Log
import android.content.pm.PackageManager
import android.util.Base64
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 💡 앱 실행 시 키 해시를 로그로 출력하는 코드
        try {
            val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            info.signatures?.let { signatures ->
                for (signature in signatures) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val hashKey = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                    Log.d("HASH_KEY_CHECK", "🔥🔥🔥 실제 적용된 키 해시: $hashKey")
                }
            }
        } catch (e: Exception) {
            Log.e("HASH_KEY_CHECK", "키 해시 로드 실패", e)
        }
    }
}
