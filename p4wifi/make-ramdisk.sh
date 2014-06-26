#!/bin/bash

cp -r $BUILD_ROOT_DIR/$DEVICE/ramdisk $TARGET_DIR/ramdisk
[ $? -ne 0 ] && echo "Error: failed to copy ramdisk." && exit 1

cd $TARGET_DIR/ramdisk

rm fstab.p3*
if [ "$F2FS_BUILD" == true ]; then
  echo cp $BUILD_ROOT_DIR/$DEVICE/ramdisk/fstab.p3-f2fs fstab.p3
  cp $BUILD_ROOT_DIR/$DEVICE/ramdisk/fstab.p3-f2fs fstab.p3
else
  echo cp $BUILD_ROOT_DIR/$DEVICE/ramdisk/fstab.p3 fstab.p3
  cp $BUILD_ROOT_DIR/$DEVICE/ramdisk/fstab.p3 fstab.p3
fi

# make sure all directories are created because git doesn't save empty directories
mkdir -p data dev proc sbin sys system
chmod 750 init*
chmod 750 sbin/adbd
chmod 750 sbin/healthd
chmod 644 default.prop
chmod 640 fstab.p3
chmod 644 ueventd*
chmod 644 property_contexts file_contexts seapp_contexts sepolicy
chmod 644 lpm.rc
find . | cpio -o -H newc | gzip > ../ramdisk.cpio.gz
