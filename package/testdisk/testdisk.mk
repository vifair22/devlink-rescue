################################################################################
#
# testdisk
#
################################################################################

TESTDISK_VERSION = 7.2
TESTDISK_SOURCE = testdisk-$(TESTDISK_VERSION).tar.bz2
TESTDISK_SITE = https://www.cgsecurity.org
TESTDISK_LICENSE = GPL-2.0+
TESTDISK_LICENSE_FILES = COPYING
TESTDISK_DEPENDENCIES = ncurses e2fsprogs ntfs-3g zlib util-linux

# Text interface only. ext2 support through e2fsprogs' libext2fs, NTFS
# through ntfs-3g (both already in the image); no Qt front end, no EWF
# images, and no libjpeg, which only lets PhotoRec check recovered JPEGs.
TESTDISK_CONF_OPTS = \
	--disable-qt \
	--with-ncurses \
	--with-ext2fs \
	--with-ntfs3g \
	--without-ntfs \
	--without-ewf \
	--without-jpeg \
	--without-iconv

# configure turns on -fstack-protector-strong whenever the compiler accepts
# it, and the link then asks for libssp, which musl on i386 does not have
# (see devlink-agent.mk). Off only where the toolchain has no SSP.
TESTDISK_CONF_OPTS += $(if $(BR2_TOOLCHAIN_HAS_SSP),,--disable-stack-protector)

$(eval $(autotools-package))
