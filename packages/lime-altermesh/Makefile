#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-altermesh
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=AlterMesh metapackage using LiMe codebase
  CATEGORY:=LiMe
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  URL:=http://libremesh.org
  DEPENDS:=+lime-system +lime-proto-batadv +reghack \
           +watchping +batman-adv-auto-gw-mode \
           +dnsmasq-dhcpv6 +dnsmasq-lease-share \
           +luci-app-batman-adv +luci-app-openairview \
           +luci-mod-status +luci-mod-lime-basic-ssl \
           +libremap-agent +luci-lib-libremap-wireless \
           +luci-lib-libremap-location +luci-lib-libremap-system
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Metapackage depending on all the required to run an altermesh-style node
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
