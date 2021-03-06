
# newifi-d2路由器的dts


```
/*包含头文件*/
#include "mt7621.dtsi"
//板子级别
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

//根节点
/ {
	compatible = "d-team,newifi-d2", "mediatek,mt7621-soc";//compatible是系统识别该机器的标识
/*tree中的 compatible 第一个""指定确切的设备，第二个""兼容的其他设备 */
	model = "Newifi-D2";		//是板的ID，类型为字符串，它的描述的是板子的型号或者芯片平台的型号
//别名节点
	aliases {
		led-boot = &led_power_blue;
		led-failsafe = &led_power_blue;
		led-running = &led_power_blue;
		led-upgrade = &led_power_blue;
		label-mac-device = &gmac0;
	};
//可选节点并不代表真正的设备，而是作为固件和操作系统之间传递数据的地方，如启动参数。
	chosen {
		bootargs = "console=ttyS0,115200";
	};
//newifi-d2 一共七个灯。低电平有效。
	leds {
		compatible = "gpio-leds";

		power-amber {
			label = "amber:power";	/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 6 GPIO_ACTIVE_LOW>;
		};
	
		led_power_blue: power-blue {
			label = "blue:power";	/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 15 GPIO_ACTIVE_LOW>;
		};
	
		internet-amber {
			label = "amber:internet";	/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 4 GPIO_ACTIVE_LOW>;
		};
	
		internet-blue {
			label = "blue:internet";	/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 13 GPIO_ACTIVE_LOW>;
		};
	
		wlan2g {
			label = "blue:wlan2g";		/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 14 GPIO_ACTIVE_LOW>;
		};
	
		wlan5g {
			label = "blue:wlan5g";		/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 16 GPIO_ACTIVE_LOW>;
		};
	
		usb {
			label = "blue:usb";		/*led灯的标识，会体现在/sys/class/leds目录中*/
			gpios = <&gpio 10 GPIO_ACTIVE_LOW>;
			trigger-sources = <&xhci_ehci_port1>, <&ehci_port2>;
			linux,default-trigger = "usbport";
		};
	};
	
	keys {
		compatible = "gpio-keys";
	
		reset {
			label = "reset";
			gpios = <&gpio 3 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;	 
/*当按下reset按键后，向内核发出的code；用于input_event上报的code代码
具体含义见input.h:比如这里的 KEY_RESTART 就对应 0x198 ；而在gpio-button-hotplug.c中，有BH_MAP(KEY_RESTART,	"reset"),*/
		};
	
		wps {
			label = "wps";
			gpios = <&gpio 7 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_WPS_BUTTON>;
		};
	};
	
	gpio_export {
		compatible = "gpio-export";
		#size-cells = <0>;
	
		power_usb3 {
			gpio-export,name = "power_usb3";
			gpio-export,output = <1>;
			gpios = <&gpio 11 GPIO_ACTIVE_HIGH>;
		};
	};
};
//spi flash  相关以及分区
/*
cat /pro/mtd
mtd0: 00030000 00010000 "u-boot"
mtd1: 00010000 00010000 "u-boot-env"
mtd2: 00010000 00010000 "factory"
mtd3: 00fb0000 00010000 "firmware"
mtd4: 00185d72 00010000 "kernel"
mtd5: 00e2a28e 00010000 "rootfs"
mtd6: 00740000 00010000 "rootfs_data"
一共32m


*/
&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <45000000>;
		broken-flash-reset;
	
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;
	
			partition@0 {
				label = "u-boot";
				reg = <0x0 0x30000>;
				read-only;
			};
	
			partition@30000 {
				label = "u-boot-env";
				reg = <0x30000 0x10000>;
				read-only;
			};
	
			factory: partition@40000 {
				label = "factory";
				reg = <0x40000 0x10000>;
				read-only;
			};
	
			partition@50000 {
				compatible = "denx,uimage";
				label = "firmware";
				reg = <0x50000 0x1fb0000>;
			};
		};
	};
};

&pcie {
	status = "okay";
};

&pcie0 {
	mt76@0,0 {
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x8000>;
		ieee80211-freq-limit = <5000000 6000000>;
	};
};

&pcie1 {
	mt76@0,0 {
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x0000>;
	};
};

&gmac0 {
	mtd-mac-address = <&factory 0xe000>; /*wifi的MAC地址，读取起始位置*/
};

&switch0 {
	ports {
		port@0 {
			status = "okay";
			label = "lan4";
		};

		port@1 {
			status = "okay";
			label = "lan3";
		};
	
		port@2 {
			status = "okay";
			label = "lan2";
		};
	
		port@3 {
			status = "okay";
			label = "lan1";
		};
	
		port@4 {
			status = "okay";
			label = "wan";
			mtd-mac-address = <&factory 0xe006>;
		};
	};
};

&state_default {
	gpio {
		groups = "i2c", "jtag", "uart2", "uart3";
		function = "gpio";
	};
};

```