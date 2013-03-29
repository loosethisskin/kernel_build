#!/bin/bash

set -a

if [ -z "$CM_ROOT" ]; then
  CM_ROOT=/u01/dev/android/sgt7/cm10.1
fi
echo CM_ROOT=$CM_ROOT
COMMON_FOLDER=$CM_ROOT/device/amazon/omap4-common
TARGET_KERNEL_SOURCE=$KERNEL_SOURCE_DIR

echo ""
echo "Building WLAN modules"
echo ""
make clean -C $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx
[ $? -ne 0 ] && exit 1
make -j8 -C $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx KERNEL_DIR=$KERNEL_OUT KLIB=$KERNEL_OUT KLIB_BUILD=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $CCOMPILER"
[ $? -ne 0 ] && exit 1
for i in $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/compat/compat.ko \
         $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/net/mac80211/mac80211.ko \
         $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/net/wireless/cfg80211.ko \
         $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/drivers/net/wireless/wl12xx/wl12xx.ko \
         $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/drivers/net/wireless/wl12xx/wl12xx_spi.ko \
         $CM_ROOT/hardware/ti/wlan/mac80211/compat_wl12xx/drivers/net/wireless/wl12xx/wl12xx_sdio.ko
do
  echo "mv $i $KERNEL_MODULES_OUT"
  mv $i $KERNEL_MODULES_OUT
  [ $? -ne 0 ] && exit 1
done
for i in cfg80211.ko \
         compat.ko \
         mac80211.ko \
         wl12xx.ko \
         wl12xx_sdio.ko \
         wl12xx_spi.ko
do
  echo "$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/$i"
  $TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/$i
  [ $? -ne 0 ] && exit 1
done

echo ""
echo "Building SGX modules"
echo ""
export OUT=$KERNEL_OUT/modules/sgx
make clean -C $COMMON_FOLDER/pvr-source/eurasiacon/build/linux2/omap4430_android
[ $? -ne 0 ] && exit 1
cp $TARGET_KERNEL_SOURCE/drivers/video/omap2/omapfb/omapfb.h $KERNEL_OUT/drivers/video/omap2/omapfb/omapfb.h
[ $? -ne 0 ] && exit 1
make -j8 -C $COMMON_FOLDER/pvr-source/eurasiacon/build/linux2/omap4430_android ARCH=arm KERNEL_CROSS_COMPILE="$CCACHE $CCOMPILER" CROSS_COMPILE="$CCACHE $CCOMPILER" KERNELDIR=$KERNEL_OUT TARGET_PRODUCT="blaze_tablet" BUILD=release TARGET_SGX=540 PLATFORM_VERSION=4.0
[ $? -ne 0 ] && exit 1
mv $OUT/target/kbuild/pvrsrvkm_sgx540_120.ko $KERNEL_MODULES_OUT
[ $? -ne 0 ] && exit 1
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/pvrsrvkm_sgx540_120.ko
[ $? -ne 0 ] && exit 1

exit 0
