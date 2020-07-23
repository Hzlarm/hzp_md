### How to add a profile for a new device at openwrt 


- /target/linux/<arch_name>/dts/
  - Create THINGOO-G1.dtsi

  - Create THINOOG-G1-B.dts

  - Create THINGOO-G1-C.dts

  - Create THINGOO-G1-D.dts

- /target/linux/<arch_name>/image/
  - Edit mt76x8.mk

    ```shell
    define Device/thingoo-g1-b
      DTS := THINGOO-G1-B
      IMAGE_SIZE := $(ralink_default_fw_size_16M)
      DEVICE_TITLE := Thingoo G1-B
      DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci
    endef
    TARGET_DEVICES += thingoo-g1-b
    
    define Device/thingoo-g1-c
      DTS := THINGOO-G1-C
      IMAGE_SIZE := $(ralink_default_fw_size_16M)
      DEVICE_TITLE := Thingoo G1-C
      DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci
    endef
    TARGET_DEVICES += thingoo-g1-c
    
    define Device/thingoo-g1-d
      DTS := THINGOO-G1-C-ESL
      IMAGE_SIZE := $(ralink_default_fw_size_16M)
      DEVICE_TITLE := Thingoo G1-D
      DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci
    endef
    TARGET_DEVICES += thingoo-g1-d
    ```

    

- /target/linux/<arch_name>/base-files/sbin/..

  This folder contains files and folders that will be integrated in the firmware's /sbin/ folder,usually common <arch_name> sbin scripts an tools.

  

- /target/linux/<arch_name>/base-files/etc/..

  This folder contains files and folders that will be integrated in the firmware's /etc folder.

  These are its subfolders and files:

  - ...board.d/ scripts for defining device-specific default hardware,like leds and network interfaces.
  - ...hotplug.d/ scripts for defining device-specific actions to be done automatically on hotplugging of devices
  - ...init.d/ scripts for defining device-specific actions to be done automatically on boot
  - ...uci-defaults/ files for defining device-specific uci configuration defaults
  - ...diag.sh defines what is the led to use for error codes for each board





- /target/linux/<arch_name>/base-files/lib/

  This folder contains files and folders that will be integrated in the firmware's /lib folder.

  These are its subfolders an files:

  <arch_name>.sh : human-readable full board name associated to script-safe board name

  preinit/ : common <arch_name> preinit startup scripts

  upgrade/ common <arch_name> upgrade scripts

  

  

    - vi target/linux/ramips/base-files/etc/board.d/01_leds
		nothing to add

    - vi target/linux/ramips/base-files/etc/board.d/02_network
		在ramips_setup_macs()函数添加thingoo-g1-c
		在ramips_setup_interfaces() 函数添加thingoo-g1-c
    
    - vi target/linux/ramips/base-files/lib/ramips.sh
        add:
        ```shell
        *"THINGOO-G1-B")
        name="thingoo-g1-b"
        ;;
        *"THINGOO-G1-C")
        name="thingoo-g1-c"
        ;;
        *"THINGOO-G1-D")
        name="thingoo-G1-D"
        ;;
        ```
    
    - vi target/linux/ramips/base-files/lib/upgrade/platform.sh
  
    	add：

    	thingoo-g1-b
  
    	thingoo-g1-c
  
    	thingoo-g1-d

  

## 改变/etc/config/network的默认值

vi package/base-files/files/bin/config_generate 

```shell
#create by minew

generate_wan_dhcp_network() {
    uci -q batch <<EOF
delete network.lan.ifname
delete network.wan
set network.wan='interface'
set network.wan.ifname='eth0'
set network.wan.proto='dhcp'
EOF
}
```


## 改变/etc/config/system 的默认值

vi package/base-files/files/bin/config_generate 
修改lan ip为192.168.99.1

set system.@system[-1].hostname='Thingoo'


## 改变/etc/config/wireless 的默认值

vi package/kernel/mac80211/files/lib/wifi/mac80211.sh


## 改变/etc/config/firewall 的默认值
   vi ./package/network/config/firewall/files/firewall.config


## package/base-files/files/etc/banner

## /etc/config/system

package/base-files/files/bin/config_generate +250



## sysupgrade
vi package/base-files/files/sbin/sysupgrade
修改
```shell
add_conffiles() {
	local file="$1"
	( find $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' \
		/etc/sysupgrade.conf /lib/upgrade/keep.d/* 2>/dev/null) \
		\( -type f -o -type l \) $find_filter 2>/dev/null;
	  list_changed_conffiles ) | sort -u > "$file"
	return 0
}
```

-->

```shell
add_conffiles() {
	local file="$1"
	( find $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' \
		/etc/sysupgrade.conf 2>/dev/null) \
		\( -type f -o -type l \) $find_filter 2>/dev/null;
	   ) | sort -u > "$file"
	return 0
}
```

在 vi package/base-files/files/etc/sysupgrade.conf 添加要保存的配置文件

```
/etc/config/pubmsg
/etc/config/dpubmsg
/etc/config/network
/etc/config/wireless
/etc/config/system
/etc/ssl/gw/
/etc/ssl/gw_wifi_outer/
/etc/ssl/gw_wifi_inner/
```

## uhttpd
打补丁


## use ntpclient instead

1.vi package/utils/busybox/Makefile
注释掉了sysntpd和ntpd-hotplug

2.vi package/base-files/files/etc/init.d/sysfixtime
添加启动时间的修正

##  增加控制登录密码
  vi package/base-files/files/bin/config_generate 
  将ttylogin修改成1

## mt76

I suppose I can just do this in my build script to always use the latest mt76 driver:

DATE=`date +%y-%m-%d`

sed -i s/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=master/ package/kernel/mt76/Makefile

sed -i s/PKG_SOURCE_DATE:=.*/PKG_SOURCE_DATE:=$DATE/ package/kernel/mt76/Makefile  

https://github.com/openwrt/mt76/issues/137

https://openwrt.org/docs/guide-user/network/wifi/ap_sta

  

  




