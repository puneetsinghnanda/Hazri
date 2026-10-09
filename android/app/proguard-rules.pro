# Keep the local-notifications plugin's models, which are used reflectively
# when a scheduled notification is restored after a reboot.
-keep class com.dexterous.** { *; }

# Drift/sqlite3 load their native library by name.
-keep class org.sqlite.** { *; }

# Flutter's own deferred-components hooks, absent in a plain app build.
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# flutter_local_notifications stores each scheduled reminder as Gson JSON and
# reads it back in ScheduledNotificationReceiver when the alarm fires, using a
# TypeToken subclass. R8 (full mode since AGP 8) strips the generic signature
# unless told not to, the read throws inside the receiver, and the reminder is
# never shown: zonedSchedule succeeds, pendingNotificationRequests() looks
# healthy, and nothing ever arrives in a release build. These are Gson's own
# rules, as the plugin's README requires for release builds.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
