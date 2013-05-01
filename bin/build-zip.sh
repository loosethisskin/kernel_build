#!/bin/bash

set -a

get_changelog()
{
  echo "Saving changelog..."
  git log --pretty=format:"[%cd] %h - %aN: %s" -n 100 --date=short > $TARGET_DIR/package/changelog.txt
  return $?
}

usage()
{
  echo ""
  echo "Usage: build-zip.sh [options] <device>"
  echo ""
  echo "Options:"
  echo "-d DIRCTORY, --device-dir=DIRECTORY   Directory containing ramdisk, installer and device specific scripts"
  echo "                                      Default is <build_root_dir>/<device_name>"
  echo ""
  echo "Example:"
  echo "build-zip.sh otter"
}

get_opts()
{
  DEVICE_DIR=""
  while [ "$#" -gt 0 ]
  do
    case "${1}" in
      -d | --device-dir* )
          if [ "`echo \"${1}\" |grep '=' |wc -l`" -eq 1 ]; then
            DEVICE_DIR="`echo \"${1}\" | sed -e 's/^[^=]*=//'`"
            shift
          else
            shift
            if [ "$#" -lt 1 ]; then
              echo "missing parameter"
              return 1
            fi
            DEVICE_DIR="$1"
            shift
          fi
          ;;
      -* )
          echo "invalid option \"${1}\""
          exit
          ;;
      * )
          break
          ;;
     esac
  done

  if [ -z "$1" ]; then
    usage
    exit 1
  fi

  DEVICE=$1

  if [ -z "$DEVICE_DIR" ]; then
    DEVICE_DIR=${BUILD_ROOT_DIR}/${DEVICE}
  else
    DEVICE_DIR=`readlink -m $DEVICE_DIR`
  fi

  echo "--------------------------------------------------------------------------------"
  echo "KERNEL_SOURCE_DIR = $KERNEL_SOURCE_DIR"
  echo "BUILD_ROOT_DIR    = $BUILD_ROOT_DIR"
  echo "DEVICE_DIR        = $DEVICE_DIR"
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

echo "Building ramdisk..."
if [ ! -f ${DEVICE_DIR}/make-ramdisk.sh ]; then
  echo "Error: make-ramdisk.sh not found"
  exit 1
fi
${DEVICE_DIR}/make-ramdisk.sh

cd $TARGET_DIR

echo "Building boot image..."
if [ ! -f ${DEVICE_DIR}/make-bootimg.sh ]; then
  echo "Error: make-bootimg.sh not found"
  exit 1
fi
${DEVICE_DIR}/make-bootimg.sh
[ $? -ne 0 ] && echo "Error: failed to make boot image." && exit 1

echo "Building zip file..."

cp -r ${DEVICE_DIR}/installer $TARGET_DIR/package
cp -r $KERNEL_MODULES_INSTALL $TARGET_DIR/package
export zipdir=package
export zipfile="$TARGET_DIR/kernel_${DEVICE}${LOCALVERSION}.zip"

cp -r boot.img $zipdir
[ $? -ne 0 ] && exit 1

get_changelog

cd $zipdir
zip -r $zipfile *
[ $? -ne 0 ] && echo "Error: failed to build zip file." && exit 1

echo "Package complete: $zipfile"
