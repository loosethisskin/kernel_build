#!/bin/bash

echo "cp $BUILD_ROOT_DIR/jem/ramdisk.img $TARGET_DIR"
cp $BUILD_ROOT_DIR/jem/ramdisk.img $TARGET_DIR
[ $? -ne 0 ] && echo "Error: failed to copy ramdisk." && exit 1

exit 0
