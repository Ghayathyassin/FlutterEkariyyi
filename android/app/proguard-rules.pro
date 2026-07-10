# R8 / ProGuard keep rules for release builds.
# Firebase (core/messaging) and most plugins ship their own consumer rules that
# AGP applies automatically; these cover the reflection-based bits that don't.

# flutter_local_notifications — uses Gson internally (TypeConverters), which R8
# would otherwise strip.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-dontwarn com.google.gson.**

# Keep attributes needed by reflection-based (de)serialization and stack traces.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable
