#!/bin/bash

set -a

build_kernel_and_modules()
{
  # run device specific kernel build script if one exists
  if [ -f ${DEVICE_DIR}/build-kernel.sh ]; then
    echo "Running ${DEVICE_DIR}/build-kernel.sh..."
    ${DEVICE_DIR}/build-kernel.sh
    [ $? -ne 0 ] && return 1
    return 0
  fi

  echo ""
  echo "Building kernel ..."
  echo ""

  make O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $ARM_EABI_TOOLCHAIN/arm-eabi-" distclean
  [ $? -ne 0 ] && return 1
  make O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $ARM_EABI_TOOLCHAIN/arm-eabi-" ${DEFCONFIG}
  [ $? -ne 0 ] && return 1
  make -j$JOBS O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $ARM_EABI_TOOLCHAIN/arm-eabi-" zImage
  [ $? -ne 0 ] && return 1

  # run device specific modules build script if one exists
  if [ -f ${DEVICE_DIR}/build-modules.sh ]; then
    echo ""
    echo "Running ${DEVICE_DIR}/build-modules.sh..."
    echo ""
    ${DEVICE_DIR}/build_modules.sh
    [ $? -ne 0 ] && return 1
    return 0
  fi

  echo ""
  echo "Building modules ..."
  echo ""

  KERNEL_MODULES_INSTALL=$KERNEL_OUT/modules/kernel
  KERNEL_MODULES_OUT=$KERNEL_OUT/rootfs/system/lib/modules
  mkdir -p $KERNEL_MODULES_OUT

  make -j$JOBS O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $ARM_EABI_TOOLCHAIN/arm-eabi-" modules
  [ $? -ne 0 ] && return 1
  make -j$JOBS O=$KERNEL_OUT ARCH=arm CROSS_COMPILE="$CCACHE $ARM_EABI_TOOLCHAIN/arm-eabi-" INSTALL_MOD_PATH=$KERNEL_MODULES_INSTALL modules_install
  [ $? -ne 0 ] && return 1

  mdpath=`find $KERNEL_MODULES_INSTALL -type f -name modules.order`;
  if [ "$mdpath" != "" ]; then
    mpath=`dirname $mdpath`
    ko=`find $mpath/kernel -type f -name *.ko`
    for i in $ko
    do
      echo "$TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $i"
      $TOOLCHAIN_DIR/bin/arm-eabi-strip --strip-unneeded $i
      [ $? -ne 0 ] && return 1
      echo "mv $i $KERNEL_MODULES_OUT"
      mv $i $KERNEL_MODULES_OUT
      [ $? -ne 0 ] && return 1
    done;
  fi
  #rm -rf $mpath

  # run device specific post modules script if one exists
  if [ -f ${DEVICE_DIR}/modules-post-install.sh ]; then
    echo ""
    echo "Running modules-post-install.sh..."
    echo ""
    ${DEVICE_DIR}/modules-post-install.sh
    [ $? -ne 0 ] && return 1
    return 0
  fi
}

run_build()
{
  # need this wrapper function because tee'ing the logfile screws up the exit codes
  build_kernel_and_modules
  if [ $? -ne 0 ]; then
    echo ""
    echo '***** ERROR: Build failed -- check the logs *****'
    echo ""
    return 1
  fi
  echo ""
  echo 'Build successful.'
  echo ""
  return 0
}

usage()
{
  echo ""
  echo "Usage: build.sh [options] <device> <defconfig> <toolchain>"
  echo ""
  echo "Options:"
  echo "-j N, --jobs=N                        Number of jobs"
  echo "                                      Default is number or processors"
  echo "-d DIRCTORY, --device-dir=DIRECTORY   Directory containing ramdisk, installer and device specific scripts"
  echo "                                      Default is <build_root_dir>/<device_name>"
  echo ""
  echo "Example:"
  echo "build.sh -j 4 otter otter_android_defconfig /u01/dev/android/git/toolchains/linaro/linaro-4.7"
}

get_opts()
{
  DEVICE_DIR=""
  JOBS=""
  while [ "$#" -gt 0 ]
  do
    case "${1}" in
      -j | --jobs* )
          if [ "`echo \"${1}\" |grep '=' |wc -l`" -eq 1 ]; then
            JOBS="`echo \"${1}\" | sed -e 's/^[^=]*=//'`"
            shift
          else
            shift
            if [ "$#" -lt 1 ]; then
              echo "missing parameter"
              usage
              return 1
            fi
            JOBS="$1"
            shift
          fi
          ;;
      -d | --device-dir* )
          if [ "`echo \"${1}\" |grep '=' |wc -l`" -eq 1 ]; then
            DEVICE_DIR="`echo \"${1}\" | sed -e 's/^[^=]*=//'`"
            shift
          else
            shift
            if [ "$#" -lt 1 ]; then
              echo "missing parameter"
              usage
              return 1
            fi
            DEVICE_DIR="$1"
            shift
          fi
          ;;
      -* )
          echo "invalid option \"${1}\""
          usage
          exit
          ;;
      * )
          break
          ;;
     esac
  done

  if [ -z "$3" ]; then
    usage
    exit 1
  fi

  DEVICE=$1
  DEFCONFIG=$2
  TOOLCHAIN_DIR=$3

  if [ -z "$DEVICE_DIR" ]; then
    DEVICE_DIR=${BUILD_ROOT_DIR}/${DEVICE}
  else
    DEVICE_DIR=`readlink -m $DEVICE_DIR`
  fi
  [ -z "$JOBS" ] && JOBS=`cat /proc/cpuinfo| grep processor | wc -l`

  echo "--------------------------------------------------------------------------------"
  echo "KERNEL_SOURCE_DIR = $KERNEL_SOURCE_DIR"
  echo "BUILD_ROOT_DIR    = $BUILD_ROOT_DIR"
  echo "DEVICE_DIR        = $DEVICE_DIR"
  echo "JOBS              = $JOBS"
  echo "--------------------------------------------------------------------------------"

}

################################################################################
# main
################################################################################

KERNEL_SOURCE_DIR="$PWD"
SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`dirname $0`
BUILD_ROOT_DIR=`readlink -m $SCRIPT_DIR/..`

get_opts $*

v_toolchain=`basename $TOOLCHAIN_DIR`
v_gcc=gcc-`gcc --version |head -1 |awk '{ print $NF }'`

export PATH=$TOOLCHAIN_DIR/bin:$BUILD_ROOT_DIR/bin:$PATH
export ARM_EABI_TOOLCHAIN="$TOOLCHAIN_DIR/bin"
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

run_build 2>&1 | tee -a $LOGFILE

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Time to compile: " >> $LOGFILE
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN >> $LOGFILE
printf "%d sec(s)\n" $E_SEC >> $LOGFILE

grep "Time to compile" $LOGFILE
