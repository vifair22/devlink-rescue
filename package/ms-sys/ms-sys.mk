################################################################################
#
# ms-sys
#
################################################################################

MS_SYS_VERSION = 2.8.0
MS_SYS_SITE = https://downloads.sourceforge.net/project/ms-sys/ms-sys%20stable/$(MS_SYS_VERSION)
MS_SYS_LICENSE = GPL-2.0+
MS_SYS_LICENSE_FILES = COPYING

# Only the binary: its translations need msgfmt on the host and nobody reads
# them over a serial line. CC and CFLAGS go in through the environment, since
# the Makefile appends its own flags to CFLAGS with += and a command-line
# assignment would replace them.
define MS_SYS_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" $(MAKE) build/bin/ms-sys
endef

define MS_SYS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/bin/ms-sys $(TARGET_DIR)/usr/sbin/ms-sys
endef

$(eval $(generic-package))
