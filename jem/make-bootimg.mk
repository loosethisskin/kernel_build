DEVICE_FOLDER := $(CM_ROOT)/device/amazon/jem

BOWSER_BOOTLOADER := $(DEVICE_FOLDER)/prebuilt/boot/u-boot.bin
BOWSER_BOOT_CERT_FILE := $(DEVICE_FOLDER)/prebuilt/boot/boot_cert
BOWSER_BOOT_ADDRESS := '\x00\x50\x7c\x80'
BOWSER_STACK_FILE := /tmp/stack.tmp

PRODUCT_OUT := $(TARGET_DIR)
MKBOOTIMG := mkbootimg
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_CMDLINE := mem=1G console=/dev/null rootdelay=2 init=/init androidboot.console=ttyO2 androidboot.hardware=bowser vmalloc=496M
BOARD_KERNEL_BASE := 0x80000000
INTERNAL_BOOTIMAGE_ARGS := --kernel $(PRODUCT_OUT)/zImage --ramdisk $(PRODUCT_OUT)/ramdisk.img --cmdline "$(BOARD_KERNEL_CMDLINE)" --base $(BOARD_KERNEL_BASE) --pagesize $(BOARD_KERNEL_PAGESIZE)
INSTALLED_BOOTIMAGE_TARGET := $(PRODUCT_OUT)/boot.img

define make_stack
  for i in $$(seq 1024) ; do /bin/echo -ne $(BOWSER_BOOT_ADDRESS) >>$(1) ; done
endef

define pretty
  @echo $1
endef

$(INSTALLED_BOOTIMAGE_TARGET):
	$(call pretty,"Making target boot image: $@")
	$(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_ARGS) --output $@.tmp
	cat $(BOWSER_BOOT_CERT_FILE) $@.tmp >$@
	rm -f $@.tmp
	$(call pretty,"Adding kindle specific u-boot for boot.img")
	dd if=$(BOWSER_BOOTLOADER) of=$@ bs=8117072 seek=1 conv=notrunc
	$(call pretty,"Adding kindle specific payload to boot.img")
	rm -f $(BOWSER_STACK_FILE)
	$(call make_stack,$(BOWSER_STACK_FILE))
	dd if=$(BOWSER_STACK_FILE) of=$@ bs=6519488 seek=1 conv=notrunc
	rm -f $(BOWSER_STACK_FILE)
