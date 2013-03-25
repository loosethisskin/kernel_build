#!/bin/bash

mkbootimg --kernel zImage --base 0x10000000 --ramdisk ramdisk.cpio.gz --output boot.img
exit $?
