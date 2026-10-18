#!/bin/bash
# Rebuilds the FFmpeg audio decoder libraries shipped with EMOTION Player from this repository.
# Usage: build/build.sh <path-to-android-ndk-r27c> [output-dir]
# Host: Linux x86_64 (tested: Ubuntu 24.04 / WSL2) with make, cmake >= 3.21, xz, tar.
# Output: <output-dir>/<abi>/{libavutil,libswresample,libavcodec,libffmpegJNI}.so for
#         armeabi-v7a, arm64-v8a, x86_64 (API level 24). The shipped libraries were produced by
#         exactly this script; with the same NDK the output is bit-identical (fixed paths
#         /tmp/emotion-ffmpeg-build and /tmp/emotion-ffmpeg-ndk are used internally). See README.md, "Replacing the libraries".
set -eu
NDK=${1:?"usage: build.sh <android-ndk-r27c> [output-dir]"}
REPO=$(cd "$(dirname "$0")/.." && pwd)
OUT=$(realpath -m "${2:-$REPO/out}")
# Fixed build directory: FFmpeg embeds its configure line (incl. paths) into the libraries, so a
# fixed path is required for bit-identical output. It is deleted and recreated on every run.
WORK=/tmp/emotion-ffmpeg-build
rm -rf "$WORK"; mkdir -p "$WORK"
PFX="-ffile-prefix-map=$WORK=/build"
# Fixed NDK path as well (the compiler path is part of the embedded configure line).
ln -sfn "$(realpath "$NDK")" /tmp/emotion-ffmpeg-ndk
NDK=/tmp/emotion-ffmpeg-ndk
TC=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
mkdir -p "$OUT"
tar -xJf "$REPO"/ffmpeg/ffmpeg-*.tar.xz -C "$WORK"
SRC=$(ls -d "$WORK"/ffmpeg-*)
# The DTS (dca) decoder is not included since 2026-10-18.
DEC="mp3 mp2 ac3 eac3 truehd mlp"
COMMON="--target-os=android --disable-static --enable-shared --disable-doc --disable-programs --disable-everything
 --disable-avdevice --disable-avformat --disable-swscale --disable-postproc --disable-avfilter --disable-symver
 --enable-swresample --disable-v4l2-m2m --disable-vulkan"
for d in $DEC; do COMMON="$COMMON --enable-decoder=$d"; done

build() { # abi arch cpu triple(api) extra-cflags [extra configure options...]
  local abi=$1 arch=$2 cpu=$3 tri=$4 xcflags=$5; shift 5
  local pre=$WORK/prefix/$abi
  (
    cd "$SRC"
    make distclean > /dev/null 2>&1 || true
    ./configure --prefix="$pre" --libdir="$pre/lib" --incdir="$pre/include" --arch="$arch" --cpu="$cpu" \
      --cross-prefix="$TC/$tri-" --nm="$TC/llvm-nm" --ar="$TC/llvm-ar" --ranlib="$TC/llvm-ranlib" --strip="$TC/llvm-strip" \
      --extra-cflags="$PFX $xcflags" --extra-ldflags="-Wl,-z,max-page-size=16384" $COMMON "$@" > "$WORK/configure-$abi.log"
    grep -E '#define CONFIG_(GPL|NONFREE|VERSION3) ' config.h > "$OUT/config-$abi.txt"
    make -j"$(nproc)" > "$WORK/make-$abi.log" 2>&1
    make install-libs install-headers > /dev/null
  )
}
build armeabi-v7a arm armv7-a armv7a-linux-androideabi24 "-march=armv7-a -mfloat-abi=softfp"
build arm64-v8a aarch64 armv8-a aarch64-linux-android24 ""
build x86_64 x86_64 x86-64 x86_64-linux-android24 "" --disable-asm

J=$WORK/jni; mkdir -p "$J"
cp "$REPO/media3-decoder-ffmpeg/ffmpeg_jni.cc" "$J/"
cp "$REPO/build/CMakeLists.shared.txt" "$J/CMakeLists.txt"
for abi in armeabi-v7a arm64-v8a x86_64; do
  cmake -S "$J" -B "$J/b-$abi" -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=$abi -DANDROID_PLATFORM=android-24 -DCMAKE_BUILD_TYPE=Release -DFFMPEG_PREFIX="$WORK/prefix" \
    -DCMAKE_C_FLAGS="$PFX" -DCMAKE_CXX_FLAGS="$PFX" > /dev/null
  make -C "$J/b-$abi" -j"$(nproc)" > /dev/null
  mkdir -p "$OUT/$abi"
  cp "$J/b-$abi/libffmpegJNI.so" "$WORK/prefix/$abi/lib/libavutil.so" "$WORK/prefix/$abi/lib/libswresample.so" \
     "$WORK/prefix/$abi/lib/libavcodec.so" "$OUT/$abi/"
  for f in "$OUT/$abi"/*.so; do "$TC/llvm-strip" --strip-unneeded "$f"; done
done
rm -rf "$WORK"
echo "Licence configuration (all must be 0):"; cat "$OUT"/config-*.txt | sort | uniq -c
echo "SHA-256:"; (cd "$OUT" && sha256sum */*.so)
