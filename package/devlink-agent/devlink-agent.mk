################################################################################
#
# devlink-agent
#
################################################################################

# Pinned to a devlink commit. To build from a working tree instead, put
#   DEVLINK_AGENT_OVERRIDE_SRCDIR = /path/to/devlink
# in build/<image>/local.mk.
DEVLINK_AGENT_VERSION = 27f0ebce9039d568d8b9bd4ff6d0dc44d2f10205
DEVLINK_AGENT_SITE = https://git.airies.net/vifair22/devlink.git
DEVLINK_AGENT_SITE_METHOD = git
DEVLINK_AGENT_LICENSE = GPL-3.0
DEVLINK_AGENT_LICENSE_FILES = LICENSE

# The toolchain wrapper supplies -march, so CC is all the agent's Makefile
# needs, bar one flag. Buildroot builds musl toolchains for i386 without SSP
# (package/musl/Config.in: "SSP broken on i386/ppc"), and a static link with
# -fstack-protector then asks for a libssp that does not exist. HARDENING
# drops it and keeps stack-clash protection, which needs no runtime support.
DEVLINK_AGENT_HARDENING = \
	$(if $(BR2_TOOLCHAIN_HAS_SSP),-fstack-protector-strong) -fstack-clash-protection

define DEVLINK_AGENT_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) agent-linux CC="$(TARGET_CC)" \
		HARDENING="$(DEVLINK_AGENT_HARDENING)"
endef

define DEVLINK_AGENT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/bin/devlink-agent \
		$(TARGET_DIR)/usr/sbin/devlink-agent
endef

$(eval $(generic-package))
