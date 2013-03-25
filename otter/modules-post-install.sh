#!/bin/bash

# delete WLAN modules built from hardware/ti/wlan (TARGET_KERNEL_MODULES)

echo "Deleting WLAN modules built from hardware/ti/wlan..."

cd $KERNEL_MODULES_OUT
for i in cfg80211.ko compat.ko mac80211.ko wl12xx.ko wl12xx_sdio.ko wl12xx_spi.ko
do
  if [ -f $i ]; then
    echo "rm $i"
    rm $i
  fi
done
cd - > /dev/null
