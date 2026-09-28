################################################################################
#
# falcon-mkstick32
#
################################################################################

# falcon-boot's mkstick for a 32-bit machine's own Linux: what installs falcon
# station-legacy onto a disk from DevLink recovery. Pinned to a falcon-boot
# commit. To build from a working tree instead, put
#   FALCON_MKSTICK32_OVERRIDE_SRCDIR = /path/to/airies-boot
# in build/<image>/local.mk.
FALCON_MKSTICK32_VERSION = 1aa7d1bc3185fa1509f1aa700630c9a4dd59aa4c
FALCON_MKSTICK32_SITE = https://git.airies.net/vifair22/falcon-boot.git
FALCON_MKSTICK32_SITE_METHOD = git
FALCON_MKSTICK32_LICENSE = GPL-3.0
FALCON_MKSTICK32_LICENSE_FILES = LICENSE

# falcon-boot's own mkstick32 rule builds -march=i686 with the stack
# protector, against a glibc multilib. Here the compiler is the image's i586
# musl one, whose wrapper supplies -march, and musl on i386 has no SSP (see
# devlink-agent.mk), so the 32-bit flags are replaced on the command line:
# the same defines and include paths, no -march, no stack protector.
#
# A variable set on make's command line also cancels the rule's
# target-specific `HOST32_CFLAGS += -msse2 -maes` for aesni.o, so that one
# object is built first with the flags added, and the second make finds it
# up to date. crypto.c calls it only on a processor that reports AES-NI.
FALCON_MKSTICK32_CFLAGS = -std=c11 -O2 -D_GNU_SOURCE -fstack-clash-protection \
	-Ifalcon-appliance/src -Ifalcon-cli/src -Ifalcon-core/src -I.
FALCON_MKSTICK32_MAKE = $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
	CC_HOST="$(TARGET_CC)" HOST_LDFLAGS=""

define FALCON_MKSTICK32_BUILD_CMDS
	$(FALCON_MKSTICK32_MAKE) build/obj/host32/falcon-core/src/crypto/aesni.o \
		HOST32_CFLAGS="$(FALCON_MKSTICK32_CFLAGS) -msse2 -maes"
	$(FALCON_MKSTICK32_MAKE) build/bin/falcon-boot-mkstick32 \
		HOST32_CFLAGS="$(FALCON_MKSTICK32_CFLAGS)"
endef

define FALCON_MKSTICK32_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/bin/falcon-boot-mkstick32 \
		$(TARGET_DIR)/usr/sbin/falcon-boot-mkstick32
endef

$(eval $(generic-package))
