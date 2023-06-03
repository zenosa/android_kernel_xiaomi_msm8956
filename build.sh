#!/bin/bash
#
# Build android kernel using Clang
# Copyright (c) 2023, Benarji Anand <benarji385@gmail.com>

SECONDS=0 # Initial timer starting point
AK3_DIR=${PWD%/*}/AnyKernel3/
GCC64_DIR="$HOME/toolchain/gcc/aarch64-linux-android"
GCC32_DIR="$HOME/toolchain/gcc/arm-eabi"
CLANG_DIR="$HOME/toolchain/clang"
DEVICE="Kenzo"
DEFCONFIG="${DEVICE,}_defconfig"
ZIPNAME="${DEVICE,}-lionus-v4.9-snc-$(date '+%Y%m%d-%H%M').zip"

export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

if ! [ -d "$GCC64_DIR" ]; then
echo "GCC for ARM64 not found! Cloning to $GCC64_DIR..."
if ! git clone --depth=1 https://github.com/kenzokuken/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 $GCC64_DIR; then
echo "Cloning GCC for ARM64  failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC32_DIR" ]; then
echo "GCC for ARM32 not found! Cloning to $GCC32_DIR..."
if ! git clone --depth=1 https://github.com/kenzokuken/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 $GCC32_DIR; then
echo "Cloning GCC for ARM32  failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$CLANG_DIR" ]; then
echo "Clang not found! Cloning to $CLANG_DIR..."
if ! git clone --depth=1 https://github.com/kenzokuken/android_prebuilts_clang_kernel_linux-x86_clang-r416183b $CLANG_DIR; then
echo "Cloning Clang for Linux-x86 failed! Aborting..."
exit 1
fi
fi

clear
# Cleaning up previous build
if [[ $1 = "-c" || $1 = "--clean" ]]; then
echo -e "\n**** Cleaning up build environment ****"
rm -rf out
echo -e "Done"
fi

# Begin kernel compilation process
echo -e "\n**** Starting compilation for $DEVICE ****"
make O=out ARCH=arm64 $DEFCONFIG
make -j$(nproc --all) O=out \
  			   	 ARCH=arm64 \
  			   	 CC=clang \
  			   	 CLANG_TRIPLE=aarch64-linux-gnu- \
  			   	 CROSS_COMPILE=aarch64-linux-android- \
  			   	 CROSS_COMPILE_ARM32=arm-linux-androideabi- \
  			   	 2>&1 | tee kernel.log

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\n**** Kernel compiled succesfully! Zipping up ****"
if ! git clone -q https://github.com/kenzokuken/AnyKernel3 -b ${DEVICE,} $AK3_DIR; then
echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb $AK3_DIR
rm -rf ${PWD%/*}/${DEVICE,}-*zip out/
cd $AK3_DIR
rm -f *zip
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
else
echo -e "\nThe compilation failed!"
fi


