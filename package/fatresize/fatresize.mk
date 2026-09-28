################################################################################
#
# fatresize
#
################################################################################

FATRESIZE_VERSION = 1.1.0
FATRESIZE_SITE = $(call github,ya-mouse,fatresize,v$(FATRESIZE_VERSION))
FATRESIZE_LICENSE = GPL-3.0+
FATRESIZE_LICENSE_FILES = COPYING
# The GitHub archive carries configure.ac but no configure.
FATRESIZE_AUTORECONF = YES
FATRESIZE_DEPENDENCIES = parted

$(eval $(autotools-package))
