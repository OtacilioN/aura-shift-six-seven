# Room creates generated database implementations reflectively. Older Room
# versions bundled transitively by Google Mobile Ads do not preserve their
# constructors and DAO members when R8 optimizes a release build.
-keep class * extends androidx.room.RoomDatabase { *; }
