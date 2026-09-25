################################################################################
#
# chntpw
#
################################################################################

CHNTPW_VERSION = 140201
CHNTPW_SOURCE = chntpw-source-$(CHNTPW_VERSION).zip
CHNTPW_SITE = https://pogostick.net/~pnh/ntpasswd
CHNTPW_LICENSE = GPL-2.0 (chntpw, reged), LGPL-2.1 (ntreg, libsam)
CHNTPW_LICENSE_FILES = GPL.txt LGPL.txt COPYING.txt

CHNTPW_TOOLS = chntpw reged sampasswd samusrgrp

define CHNTPW_EXTRACT_CMDS
	$(UNZIP) -q -d $(@D) $(CHNTPW_DL_DIR)/$(CHNTPW_SOURCE)
	mv $(@D)/chntpw-$(CHNTPW_VERSION)/* $(@D)
	rmdir $(@D)/chntpw-$(CHNTPW_VERSION)
endef

# The upstream Makefile hardwires -m32 and OpenSSL, so the tools are linked
# here directly. The source predates gcc 14's pointer-type errors.
CHNTPW_CFLAGS = $(TARGET_CFLAGS) -I$(@D) -Wno-incompatible-pointer-types

define CHNTPW_BUILD_CMDS
	cd $(@D) && \
	$(TARGET_CC) $(CHNTPW_CFLAGS) -o chntpw chntpw.c ntreg.c edlib.c libsam.c && \
	$(TARGET_CC) $(CHNTPW_CFLAGS) -o reged reged.c ntreg.c edlib.c && \
	$(TARGET_CC) $(CHNTPW_CFLAGS) -o sampasswd sampasswd.c ntreg.c libsam.c && \
	$(TARGET_CC) $(CHNTPW_CFLAGS) -o samusrgrp samusrgrp.c ntreg.c libsam.c
endef

define CHNTPW_INSTALL_TARGET_CMDS
	$(foreach t,$(CHNTPW_TOOLS),
		$(INSTALL) -D -m 0755 $(@D)/$(t) $(TARGET_DIR)/usr/sbin/$(t))
endef

$(eval $(generic-package))
