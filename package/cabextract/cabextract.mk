################################################################################
#
# cabextract
#
################################################################################

# Carries its own copy of libmspack, so it needs no other package.
CABEXTRACT_VERSION = 1.11
CABEXTRACT_SITE = https://www.cabextract.org.uk
CABEXTRACT_LICENSE = GPL-3.0+
CABEXTRACT_LICENSE_FILES = COPYING

$(eval $(autotools-package))
