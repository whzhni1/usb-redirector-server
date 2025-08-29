# Copyright (C) 2008-2021 SimplyCore LLC
# GPLv2 License, see /LICENSE

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=usb-redirector-server
PKG_VERSION:=3.9.8
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

### ===== 内核模块部分 =====
define KernelPackage/usb-redirector-server
  SUBMENU:=USB Support
  TITLE:=USB Redirector Server kernel module
  DEPENDS:=kmod-usb-core @USB_SUPPORT
  MAINTAINER:=IncentivesPro <support@incentivespro.com>
  URL:=http://www.incentivespro.com
  VERSION:=$(LINUX_VERSION)-$(PKG_VERSION)-$(BOARD)
  FILES:=$(PKG_BUILD_DIR)/src/tusbd/tusbd.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,60,tusbd)
endef

define KernelPackage/usb-redirector-server/description
This package contains a Linux kernel module for the USB Redirector server.
endef

### ===== 用户态程序部分 =====
define Package/usb-redirector-server
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=USB Redirector Server user-space tools
  DEPENDS:=+kmod-usb-redirector-server +librt +libstdcpp +libpthread
  MAINTAINER:=IncentivesPro <support@incentivespro.com>
  URL:=http://www.incentivespro.com
endef

define Package/usb-redirector-server/description
User-space daemon, configuration utility, configuration files and startup scripts for USB Redirector Server.
endef

define Package/usb-redirector-server/conffiles
/etc/usbsrvd.conf
endef

### ===== 准备源码 =====
define Build/Prepare
    mkdir -p $(PKG_BUILD_DIR)
    $(CP) -r ./src $(PKG_BUILD_DIR)/
endef

### ===== 编译阶段 =====
define Build/Compile
    # 1. 编译内核模块
    $(MAKE) -C "$(LINUX_DIR)" M="$(PKG_BUILD_DIR)/src/tusbd" \
        ARCH="$(LINUX_KARCH)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        CC="$(TARGET_CC)" \
        CPP="$(TARGET_CC)" \
        LD="$(TARGET_CROSS)ld" \
        STUB=y VHCI=n \
        EXTRA_CFLAGS="-D_USBD_USE_EHCI_FIX_ -D_USBD_ENABLE_STUB_" \
        modules

    # 2. 编译用户态程序（示例假设 usbsrv 源码在 src/usbsrv，usbsrvd 源码在 src/usbsrvd）
    $(TARGET_CC) $(TARGET_CFLAGS) -o $(PKG_BUILD_DIR)/usbsrv $(PKG_BUILD_DIR)/src/usbsrv/*.c $(TARGET_LDFLAGS) -lpthread -lrt
    $(TARGET_CC) $(TARGET_CFLAGS) -o $(PKG_BUILD_DIR)/usbsrvd-srv $(PKG_BUILD_DIR)/src/usbsrvd/*.c $(TARGET_LDFLAGS) -lpthread -lrt
endef

### ===== 安装阶段 =====
define Package/usb-redirector-server/install
    $(INSTALL_DIR) $(1)/usr/bin
    $(INSTALL_BIN) $(PKG_BUILD_DIR)/usbsrv $(1)/usr/bin/
    $(INSTALL_DIR) $(1)/usr/sbin
    $(INSTALL_BIN) $(PKG_BUILD_DIR)/usbsrvd-srv $(1)/usr/sbin/usbsrvd
    $(INSTALL_DIR) $(1)/etc
    $(INSTALL_CONF) ./files/usbsrvd.conf $(1)/etc/usbsrvd.conf
    $(INSTALL_DIR) $(1)/etc/init.d
    $(INSTALL_BIN) ./files/usbsrvd.init $(1)/etc/init.d/usbsrvd
endef

### ===== 安装脚本 =====
define Package/usb-redirector-server/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
  insmod tusbd.ko
  /etc/rc.common /etc/init.d/usbsrvd enable
  /etc/init.d/usbsrvd start
fi
endef

define Package/usb-redirector-server/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
  /etc/init.d/usbsrvd stop
  rmmod tusbd.ko
fi
endef

### ===== 注册包 =====
$(eval $(call KernelPackage,usb-redirector-server))
$(eval $(call BuildPackage,usb-redirector-server))
