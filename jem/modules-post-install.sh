#!/bin/bash

set -a

if [ -z "$CM_ROOT" ]; then
  CM_ROOT=/u01/dev/android/sgt7/cm10.1
fi
echo CM_ROOT=$CM_ROOT
COMMON_FOLDER=$CM_ROOT/device/amazon/omap4-common
TARGET_KERNEL_SOURCE=$KERNEL_SOURCE_DIR

echo ""
echo "Building SGX modules"
echo ""
export OUT=$KERNEL_OUT/modules/sgx
make clean -C $COMMON_FOLDER/pvr-source/eurasiacon/build/linux2/omap4430_android
[ $? -ne 0 ] && exit 1
cp $TARGET_KERNEL_SOURCE/drivers/video/omap2/omapfb/omapfb.h $KERNEL_OUT/drivers/video/omap2/omapfb/omapfb.h
[ $? -ne 0 ] && exit 1
make -j8 -C $COMMON_FOLDER/pvr-source/eurasiacon/build/linux2/omap4430_android ARCH=arm KERNEL_CROSS_COMPILE="$CCACHE $CCOMPILER" CROSS_COMPILE="$CCACHE $CCOMPILER" KERNELDIR=$KERNEL_OUT TARGET_PRODUCT="blaze_tablet" BUILD=release TARGET_SGX=544sc PLATFORM_VERSION=4.0
[ $? -ne 0 ] && exit 1
mv $OUT/target/kbuild/pvrsrvkm_sgx544_112.ko $KERNEL_MODULES_OUT
[ $? -ne 0 ] && exit 1
$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $KERNEL_MODULES_OUT/pvrsrvkm_sgx544_112.ko
[ $? -ne 0 ] && exit 1

exit 0
