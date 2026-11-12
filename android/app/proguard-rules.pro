# Andy only reads Latin script. The text recognition plugin also references
# the optional Chinese, Devanagari, Japanese and Korean models, which are not
# bundled, so tell the shrinker their absence is expected.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
