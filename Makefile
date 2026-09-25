# devlink-rescue: build the images with the pinned Buildroot.
#
# make classic          kernel and initramfs -> build/classic/images/
# make classic-menuconfig   change the classic config, then savedefconfig
# make qemu-classic     boot it in QEMU with the agent on a pty
#
# Buildroot's own tree stays clean: every build lives under build/<image>/.

BR       := $(CURDIR)/buildroot
BUILD    := $(CURDIR)/build
BR_MAKE   = $(MAKE) -C $(BR) O=$(BUILD)/$(1) BR2_EXTERNAL=$(CURDIR)

.PHONY: classic classic-config classic-menuconfig qemu-classic clean

$(BUILD)/classic/.config: configs/classic_defconfig
	$(call BR_MAKE,classic) classic_defconfig

classic-config: $(BUILD)/classic/.config

classic: $(BUILD)/classic/.config
	$(call BR_MAKE,classic)

classic-menuconfig: $(BUILD)/classic/.config
	$(call BR_MAKE,classic) menuconfig
	$(call BR_MAKE,classic) savedefconfig BR2_DEFCONFIG=$(CURDIR)/configs/classic_defconfig

qemu-classic:
	tools/qemu-classic.sh

clean:
	rm -rf $(BUILD)
