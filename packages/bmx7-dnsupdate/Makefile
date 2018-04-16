#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bmx7-dnsupdate
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=bmx7-dnsupdate
  CATEGORY:=LiMe
  MAINTAINER:=Paul Spooren <spooren@informatik.uni-leipzig.de>
  DEPENDS:=+bmx7 +bmx7-json +dnsmasq +inotifywait
endef

define Build/Compile
endef

define Build/Configure
endef

define Package/$(PKG_NAME)/install
	$(CP) files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

