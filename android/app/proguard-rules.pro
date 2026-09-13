# Keep the local-notifications plugin's models, which are used reflectively
# when a scheduled notification is restored after a reboot.
-keep class com.dexterous.** { *; }

# Drift/sqlite3 load their native library by name.
-keep class org.sqlite.** { *; }

# Flutter's own deferred-components hooks, absent in a plain app build.
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
