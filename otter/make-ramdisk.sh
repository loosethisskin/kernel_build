#!/bin/bash

cp -r $BUILD_ROOT_DIR/$DEVICE/ramdisk $TARGET_DIR/ramdisk
[ $? -ne 0 ] && echo "Error: failed to copy ramdisk." && exit 1

cd $TARGET_DIR/ramdisk

# make sure all directories are created because git doesn't save empty directories
mkdir -p data dev proc sbin sys system
chmod 750 init*
chmod 750 sbin/adbd
chmod 644 default.prop
chmod 640 fstab.$DEVICE
chmod 644 ueventd*
find . | cpio -o -H newc | gzip > ../ramdisk.cpio.gz
