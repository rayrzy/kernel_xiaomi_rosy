#!/bin/bash
#
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0
ZIPNAME="Ryūsei-rosy-$(date '+%Y%m%d-%H%M').zip"
GCC64_DIR="$HOME/tc/gcc-aarch64"
GCC32_DIR="$HOME/tc/gcc-arm"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="rosy-perf_defconfig"

export PATH="${GCC64_DIR}/bin:${GCC32_DIR}/bin:/usr/bin:${PATH}"

if ! [ -d "$GCC64_DIR" ]; then
echo "aarch64-linux-android-4.9 not found! Cloning to $GCC64_DIR..."
if ! git clone -q https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 --depth=1 $GCC64_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC32_DIR" ]; then
echo "arm-linux-androideabi-4.9 not found! Cloning to $GCC32_DIR..."
if ! git clone -q https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-19.1 --depth=1 $GCC32_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out

echo -e "\nStarting compilation...\n"
export KBUILD_BUILD_USER="rzy"
export KBUILD_BUILD_HOST="Turu"
export TZ=Asia/Jakarta
make O=out ARCH=arm64 $DEFCONFIG
make -j$(nproc --all) O=out CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi-

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -q https://github.com/rayrzy/AnyKernel3 -b master; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
curl -T $ZIPNAME oshi.at; echo
else
echo -e "\nCompilation failed!"
exit 1
fi
