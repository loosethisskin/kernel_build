#!/bin/bash

set -a

if [ -z "$CM_ROOT" ]; then
  CM_ROOT=/u01/dev/android/sgt7/cm10.1
fi
echo CM_ROOT=$CM_ROOT
COMMON_FOLDER=$CM_ROOT/device/amazon/omap4-common
TARGET_KERNEL_SOURCE=$KERNEL_SOURCE_DIR

echo "Building WLAN modules"
set -v
make clean -C $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx
make -j8 -C $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx KERNEL_DIR=$KERNEL_OUT KLIB=$KERNEL_OUT KLIB_BUILD=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $CCOMPILER"
mv $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/compat/compat.ko $KERNEL_MODULES_OUT
mv $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/net/mac80211/mac80211.ko $KERNEL_MODULES_OUT
mv $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/net/wireless/cfg80211.ko $KERNEL_MODULES_OUT
mv $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/drivers/net/wireless/wl12xx/wl12xx.ko $KERNEL_MODULES_OUT
mv $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/drivers/net/wireless/wl12xx/wl12xx_spi.ko $KERNEL_MODULES_OUT
mv $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/drivers/net/wireless/wl12xx/wl12xx_sdio.ko $KERNEL_MODULES_OUT
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/cfg80211.ko
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/compat.ko
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/mac80211.ko
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/wl12xx.ko
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/wl12xx_sdio.ko
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/wl12xx_spi.ko
set +v

echo "Building SGX modules"
export OUT=$KERNEL_OUT/modules/sgx
set -v
make clean -C $COMMON_FOLDER/pvr-source/eurasiacon/build/linux2/omap4430_android
cp $TARGET_KERNEL_SOURCE/drivers/video/omap2/omapfb/omapfb.h $KERNEL_OUT/drivers/video/omap2/omapfb/omapfb.h
make -j8 -C $COMMON_FOLDER/pvr-source/eurasiacon/build/linux2/omap4430_android ARCH=arm KERNEL_CROSS_COMPILE="$CCACHE $CCOMPILER" CROSS_COMPILE="$CCACHE $CCOMPILER" KERNELDIR=$KERNEL_OUT TARGET_PRODUCT="blaze_tablet" BUILD=release TARGET_SGX=540 PLATFORM_VERSION=4.0
mv $OUT/target/kbuild/pvrsrvkm_sgx540_120.ko $KERNEL_MODULES_OUT
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/pvrsrvkm_sgx540_120.ko
set +v
