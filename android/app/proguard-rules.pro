# Japanese Study — aturan R8/ProGuard untuk build release (minify aktif).
#
# flutter_local_notifications v19 menjadwalkan notifikasi via
# androidx.work.WorkManager + Room. Tanpa keep eksplisit, R8 menghapus /
# mengaburkan class database sehingga aplikasi CRASH saat start
# (Failed to create an instance of androidx.work.impl.WorkDatabase).

# --- WorkManager ---
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.work.CoroutineWorker { *; }
-dontwarn androidx.work.**

# --- Room (dipakai WorkManager) ---
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Database class * { *; }
-keep @androidx.room.Dao class * { *; }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.room.**
-dontwarn androidx.sqlite.**
-dontwarn androidx.arch.core.**

# --- Play Core splitinstall (direferensi Flutter embedding, tak dipakai) ---
-dontwarn com.google.android.play.core.**

# --- Flutter / Firebase (jaga-jaga; consumer-rules biasanya cukup) ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
