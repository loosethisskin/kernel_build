#!/bin/bash

build_kernel()
{
  echo ""
  echo "Building kernel ..."
  echo ""

  make O=$KERNEL_OUT ARCH=arm distclean
  make O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $CCOMPILER" ${DEFCONFIG}
  make -j$dop O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $CCOMPILER" zImage
}

build_modules()
{
  echo ""
  echo "Building modules ..."
  echo ""

  KERNEL_MODULES_INSTALL=$KERNEL_OUT/rootfs/system
  KERNEL_MODULES_OUT=$KERNEL_MODULES_INSTALL/lib/modules

  make -j$dop O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $CCOMPILER" modules
  make -j$dop O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $CCOMPILER" INSTALL_MOD_PATH=$KERNEL_MODULES_INSTALL modules_install

  mdpath=`find $KERNEL_MODULES_OUT -type f -name modules.order`;
  if [ "$mdpath" != "" ]; then
    mpath=`dirname $mdpath`
    ko=`find $mpath/kernel -type f -name *.ko`
    for i in $ko
    do
      echo "$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $i"
      $TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $i
      echo "mv $i $KERNEL_MODULES_OUT"
      mv $i $KERNEL_MODULES_OUT
    done;
  fi
  rm -rf $mpath
  # delete TARGET_KERNEL_MODULES
  cd $KERNEL_MODULES_OUT
  for i in cfg80211.ko compat.ko mac80211.ko wl12xx.ko wl12xx_sdio.ko wl12xx_spi.ko
  do
    if [ -f $i ]; then
      echo "rm $i"
      rm $i
    fi
  done
  cd - > /dev/null
}

################################################################################
# main
################################################################################

KERNEL_SOURCE_DIR="$PWD"
SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`dirname $0`
BUILD_ROOT_DIR=`readlink -m $SCRIPT_DIR/..`

echo "--------------------------------------------------------------------------------"
echo KERNEL_SOURCE_DIR=$KERNEL_SOURCE_DIR
echo SCRIPT_NAME=$SCRIPT_NAME
echo SCRIPT_DIR=$SCRIPT_DIR
echo BUILD_ROOT_DIR=$BUILD_ROOT_DIR
echo "--------------------------------------------------------------------------------"

if [ -z "$3" ]; then
  echo "usage: build.sh <device> <defconfig> <toolchaindir> [jobs]"
  echo "example: build.sh otter otter_android_defconfig /u01/dev/android/git/toolchains/linaro/linaro-4.7"
  exit 1
fi
dop="$4"
if [ -z "$dop" ]; then
  dop=`cat /proc/cpuinfo| grep processor | wc -l`
fi

DEVICE=$1
DEFCONFIG=$2
TOOLCHAIN_DIR=$3

v_toolchain=`basename $TOOLCHAIN_DIR`
v_gcc=gcc-`gcc --version |head -1 |awk '{ print $NF }'`

export PATH=$TOOLCHAIN_DIR/bin:$BUILD_ROOT_DIR/bin:$PATH
export CCOMPILER="$TOOLCHAIN_DIR/bin/arm-eabi-"
export CCACHE=$BUILD_ROOT_DIR/bin/ccache

if [ ! "$(ccache -s|grep -E 'max cache size'|awk '{print $4}')" = "10.0" ]; then
  ccache -M 10G
fi

LOGFILE=build_kernel_${DEVICE}${LOCALVERSION}_${v_toolchain}_${v_gcc}.log
rm -f $LOGFILE
echo "TOOLCHAIN = $TOOLCHAIN_DIR" | tee -a $LOGFILE
gcc --version | tee -a $LOGFILE

echo "Cleaning up..."
KERNEL_OUT=$KERNEL_SOURCE_DIR/out
rm -rf $KERNEL_OUT
[ $? -ne 0 ] && exit 1
mkdir -p $KERNEL_OUT
[ $? -ne 0 ] && exit 1

START=$(date +%s)

build_kernel 2>&1 | tee -a $LOGFILE

build_modules 2>&1 | tee -a $LOGFILE

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Time to compile: " >> $LOGFILE
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN >> $LOGFILE
printf "%d sec(s)\n" $E_SEC >> $LOGFILE

grep "Time to compile" $LOGFILE
