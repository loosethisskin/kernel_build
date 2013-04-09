#!/bin/bash

set -a

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

if [ -z "$1" ]; then
  echo "usage: build-zip.sh <device>"
  exit 1
fi

DEVICE=$1

export PATH=$BUILD_ROOT_DIR/bin:$PATH

KERNEL_OUT=$KERNEL_SOURCE_DIR/out
KERNEL_MODULES_INSTALL=$KERNEL_OUT/rootfs/system

TARGET_DIR=$KERNEL_OUT/target
#rm -rf $TARGET_DIR
mkdir -p $TARGET_DIR
cd $TARGET_DIR
rm -rf `ls |grep -v system`

if [ ! -f $KERNEL_OUT/arch/arm/boot/zImage ]; then
  echo "Error: zImage not found."
  exit 1
fi
cp $KERNEL_OUT/arch/arm/boot/zImage $TARGET_DIR
[ $? -ne 0 ] && echo "Error: failed to copy zImage." && exit 1

cp -r $BUILD_ROOT_DIR/$DEVICE/ramdisk $TARGET_DIR/ramdisk
[ $? -ne 0 ] && echo "Error: failed to copy ramdisk." && exit 1

cd $TARGET_DIR

echo "Building ramdisk..."
if [ ! -f ${BUILD_ROOT_DIR}/${DEVICE}/make-ramdisk.sh ]; then
  echo "Error: ${DEVICE}/make-ramdisk.sh not found"
  exit 1
fi
${BUILD_ROOT_DIR}/${DEVICE}/make-ramdisk.sh

cd $TARGET_DIR

echo "Building boot image..."
if [ ! -f ${BUILD_ROOT_DIR}/${DEVICE}/make-bootimg.sh ]; then
  echo "Error: ${DEVICE}/make-bootimg.sh not found"
  exit 1
fi
${BUILD_ROOT_DIR}/${DEVICE}/make-bootimg.sh
[ $? -ne 0 ] && echo "Error: failed to make boot image." && exit 1

echo "Building zip file..."

cp -r $BUILD_ROOT_DIR/$DEVICE/installer $TARGET_DIR/package
cp -r $KERNEL_MODULES_INSTALL $TARGET_DIR/package
export zipdir=package
export zipfile="$TARGET_DIR/kernel_${DEVICE}${LOCALVERSION}.zip"

cp -r boot.img $zipdir
cd $zipdir
zip -r $zipfile *
[ $? -ne 0 ] && echo "Error: failed to build zip file." && exit 1

echo "Package complete: $zipfile"
