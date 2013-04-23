ifeq ($(strip $(CM_ROOT)),)
$(error CM_ROOT is not set)
endif

COMMON_FOLDER := $(CM_ROOT)/device/amazon/omap4-common
TARGET_KERNEL_SOURCE := $(KERNEL_SOURCE_DIR)
SGX_OUT := $(KERNEL_OUT)/modules/sgx

SGX_MODULES:
	make clean OUT=$(SGX_OUT) -C $(COMMON_FOLDER)/pvr-source/eurasiacon/build/linux2/omap4430_android
	cp $(TARGET_KERNEL_SOURCE)/drivers/video/omap2/omapfb/omapfb.h $(KERNEL_OUT)/drivers/video/omap2/omapfb/omapfb.h
	make -j8 OUT=$(SGX_OUT) -C $(COMMON_FOLDER)/pvr-source/eurasiacon/build/linux2/omap4430_android ARCH=arm KERNEL_CROSS_COMPILE=$(ARM_EABI_TOOLCHAIN)/arm-eabi- CROSS_COMPILE=$(ARM_EABI_TOOLCHAIN)/arm-eabi- KERNELDIR=$(KERNEL_OUT) TARGET_PRODUCT="blaze_tablet" BUILD=release TARGET_SGX=544sc PLATFORM_VERSION=4.0
	mv $(SGX_OUT)/target/kbuild/pvrsrvkm_sgx544_112.ko $(KERNEL_MODULES_OUT)
	$(ARM_EABI_TOOLCHAIN)/arm-eabi-strip --strip-unneeded $(KERNEL_MODULES_OUT)/pvrsrvkm_sgx544_112.ko
