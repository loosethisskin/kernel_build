#!/bin/bash

cp -r ${DEVICE_DIR}/ramdisk $TARGET_DIR/ramdisk
[ $? -ne 0 ] && echo "Error: failed to copy ramdisk." && exit 1

cd $TARGET_DIR/ramdisk

# make sure all directories are created because git doesn't save empty directories
mkdir -p data dev proc sbin sys system
chmod 750 init*
chmod 750 sbin/adbd
chmod 750 sbin/healthd
chmod 644 default.prop
chmod 644 sepolicy *_contexts
chmod 640 fstab.*
chmod 644 ueventd*
chmod 750 charger_otterx
chmod 644 res/images/charger/*
find . | cpio -o -H newc | gzip > ../ramdisk.cpio.gz
