# EMOTION Player – FFmpeg (LGPL) corresponding source

This repository contains the **complete corresponding source code** of the LGPL-licensed FFmpeg libraries
that are shipped with the Android app **EMOTION Player**, together with the build scripts and licence texts
needed to rebuild and replace them. It does **not** contain, and does not need to contain, the source code
of the EMOTION Player app itself: the app uses these libraries only at run time through separate shared
libraries (dynamic linking).

*Deutsch: siehe unten.*

## What is shipped in the app

| File in the APK (`lib/<abi>/`) | Origin | Licence |
|---|---|---|
| `libavcodec.so`, `libavutil.so`, `libswresample.so` | FFmpeg, unmodified, see `FFMPEG_COMMIT.txt` (branch `release/6.0`) | LGPL-2.1-or-later (`COPYING.LGPLv2.1`); one file derived from musl (MIT), see `NOTICE.txt` |
| `libffmpegJNI.so` | AndroidX Media3 `decoder_ffmpeg` JNI wrapper (`media3-decoder-ffmpeg/ffmpeg_jni.cc`, commit in `ANDROIDX_MEDIA_COMMIT.txt`) | Apache-2.0 |

ABIs: `armeabi-v7a`, `arm64-v8a`, `x86_64`; Android API level 24.
FFmpeg is configured **without** `--enable-gpl`, `--enable-nonfree` and `--enable-version3`
(`CONFIG_GPL 0`, `CONFIG_NONFREE 0`, `CONFIG_VERSION3 0`); only the audio decoders
`mp3 mp2 ac3 eac3 dca truehd mlp` are enabled. Exact configure line and SHA-256 of the shipped
binaries: `build/BUILD_PROVENANCE.txt`.

## Contents

| Path | Content |
|---|---|
| `ffmpeg/ffmpeg-<commit>.tar.xz` | complete FFmpeg source of the exact commit used |
| `media3-decoder-ffmpeg/` | JNI wrapper source and the Java classes of AndroidX Media3 `decoder_ffmpeg` (Apache-2.0) |
| `build/build.sh` | rebuilds all four libraries for all three ABIs (produced the shipped binaries) |
| `build/CMakeLists.shared.txt` | CMake file of the JNI wrapper (modified from AndroidX Media3: FFmpeg linked as shared libraries) |
| `build/BUILD_PROVENANCE.txt` | commits, NDK version, configure flags, SHA-256 of the shipped files |
| `COPYING.LGPLv2.1`, `FFmpeg-LICENSE.md`, `NOTICE.txt`, `media3-decoder-ffmpeg/LICENSE-Apache-2.0.txt` | licence texts and notices |
| `WRITTEN_OFFER.md` | written offer for the source code (LGPL-2.1 section 6(c)) |

## Building

Requirements: Linux x86_64, Android NDK **r27c**, `make`, `cmake` ≥ 3.21, `tar`, `xz`.

```sh
build/build.sh /path/to/android-ndk-r27c out
```

The shipped libraries were produced by exactly this script. With Android NDK r27c the result in
`out/<abi>/` is **bit-identical** to the shipped files (compare with the SHA-256 values in
`build/BUILD_PROVENANCE.txt`); the script uses fixed internal paths, so the location of the repository and
of the NDK does not matter. Verified on 2026-10-18 with two independent builds.

## Replacing the libraries (your right under the LGPL)

You may modify FFmpeg and use your modified version with the app:

1. Build your modified libraries with `build/build.sh` (keep the library names / SONAMEs and an ABI-compatible FFmpeg version).
2. Obtain the app's APK(s) from your device (`adb shell pm path <package>`, `adb pull …`).
3. Replace `lib/<abi>/libavcodec.so` (and/or `libavutil.so`, `libswresample.so`) in the APK, remove the old
   signature (`META-INF/*.SF|*.RSA|*.MF`), run `zipalign -p 16`, sign with your own key (`apksigner sign`).
   For split APKs sign all splits with the same key and install with `adb install-multiple`.
4. Uninstall the store version and install your build (Android does not allow an update with a different signature).

The app does not verify or block replaced libraries.

---

## Deutsch

Dieses Repository enthält den **vollständigen Quellcode** der mit der Android-App **EMOTION Player**
ausgelieferten FFmpeg-Bibliotheken (LGPL-2.1-or-later) sowie Build-Skripte und Lizenztexte, um sie neu zu
bauen und in der App zu ersetzen. Der Quellcode der App selbst ist nicht enthalten und nicht erforderlich,
da die App die Bibliotheken nur zur Laufzeit als getrennte Shared Libraries verwendet.
Bauen: `build/build.sh <Pfad-zum-NDK-r27c> out`. Austausch: siehe „Replacing the libraries“ oben.
Schriftliches Angebot: `WRITTEN_OFFER.md`.
