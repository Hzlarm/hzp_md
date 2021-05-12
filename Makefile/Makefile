#+libevent2 +libevent2-openssl +libevent2-pthreads +mqtt-ssl 

include $(TOPDIR)/rules.mk

PKG_NAME:=pubmsg-g1-d-orange
PKG_VERSION:=1.0

MAINTAINER:=Minew
PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

#+libreadline +libncurses +jansson +libjson-c 
#+libdmalloc +libtcmalloc +libjemalloc +libjemalloc +libptmalloc2 +jansson +libfreetype 
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/$(PKG_NAME)
  CATEGORY:=thingoo
  TITLE:=thingoo main project $(PKG_NAME)
  DEPENDS:=+libpthread  +libmosquitto +liburcu  +libcurl +libuci  +libudev-fbsd +kmod-drv_regopt +liblzo 
endef

define Package/$(PKG_NAME)/description
  $(PKG_NAME) by minew
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/*    $(PKG_BUILD_DIR)/ -rf
	$(CP) ./files/*  $(PKG_BUILD_DIR)/ -rf
endef



define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pubmsg     $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/bin/autopubmsg     $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d 
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/etc/init.d/pubmsg $(1)/etc/init.d 
endef


 	
define Package/$(PKG_NAME)/postinst
	#!/bin/sh  
        # check if we are on real system  
       if [ -z "$${IPKG_INSTROOT}" ]; then    
               echo "Enabling rc.d symlink for pubmsg" 
              chmod 777 /etc/init.d/pubmsg
             /etc/init.d/pubmsg enable  
       fi  
      exit 0
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh  
        # check if we are on real system  
       if [ -z "$${IPKG_INSTROOT}" ]; then    
               echo "Removing rc.d symlink for pubMessage"    
                /etc/init.d/pubmsg disable  
        fi  
        exit 0 
endef


$(eval $(call BuildPackage,$(PKG_NAME)))

