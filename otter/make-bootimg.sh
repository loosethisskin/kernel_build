#!/bin/bash

mkbootimg --kernel zImage --cmdline 'mem=512M console=null androidboot.selinux=permissive' --base 0x80000000 --pagesize 4096 --ramdisk ramdisk.cpio.gz --output boot.img

exit $?
