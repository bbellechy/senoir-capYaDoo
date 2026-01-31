# ===== Flutter Local Notifications =====
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ===== Gson / TypeToken fix =====
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.** { *; }
