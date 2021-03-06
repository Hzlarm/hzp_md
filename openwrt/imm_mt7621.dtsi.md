# mt7621.dtsi

> `*.dtsi` 文件作用：由于一个SOC可能有多个不同的电路板，而每个电路板拥有一个` *.dts`。这些dts势必会存在许多共同部分，为了减少代码的冗余，设备树将这些共同部分提炼保存在`*.dtsi` 文件中，供不同的dts共同使用。`*.dtsi` 的使用方法，类似于C语言的头文件，在dts文件中需要进行`include *.dtsi`文件。当然，dtsi本身也支持include 另一个dtsi文件。

[DTS解释参考](https://blog.csdn.net/hzlarm/article/details/115416191)

soc级的dtsi，简单了解一下大致内容。适用于所有的基于mt7621的设备。
主要描述：CPU的数量和类别、内存基地址和大小、总线和桥、外设连接、中断控制器和中断使用情况、GPIO控制器和GPIO使用情况、Clock控制器和Clock使用情况 。

```
/dts-v1/;	//dts版本
//soc级别
/*包含头文件
build_dir/target-mipsel_24kc_musl/linux-ramips_mt76x8/linux-4.14.149/include/dt-bindings/
一些宏定义
*/
#include <dt-bindings/interrupt-controller/mips-gic.h>
#include <dt-bindings/clock/mt7621-clk.h>
#include <dt-bindings/gpio/gpio.h>

//根节点
/ {
/*  一个子节点的 reg 属性需要父节点的#address-cells和#size-cells值 
	reg = <address1 length1 [address2 length2] [address3 length3] ... >
*/
	#address-cells = <1>;
	#size-cells = <1>;
	compatible = "mediatek,mt7621-soc"; //compatible是系统识别该机器的标识
/*tree中的 compatible 第一个""指定确切的设备，第二个""兼容的其他设备 */

	cpus {
		// address-cells 为1，size-cells 为0，这意味着子 reg 值是一个uint32，不包含大小字段的地址。
		#address-cells = <1>;
		#size-cells = <0>;
	
		cpu@0 {
			device_type = "cpu";
			compatible = "mips,mips1004Kc";
			reg = <0>;
		};
	
		cpu@1 {
			device_type = "cpu";
			compatible = "mips,mips1004Kc";
			reg = <1>;
		};
	};
	
	cpuintc: cpuintc {
		#address-cells = <0>;
		#interrupt-cells = <1>;	//这是中断控制器节点的属性。它声明了中断控制器的中断说明符有多少个cell（类似#address-cells和#size-cells）
		interrupt-controller;	//一个空的属性定义该节点为接收中断信号的设备
		compatible = "mti,cpu-interrupt-controller";
	};
//别名节点
	aliases {
		serial0 = &uartlite;
	};
//可选节点并不代表真正的设备，而是作为固件和操作系统之间传递数据的地方，如启动参数。
	chosen {
		bootargs = "console=ttyS0,57600";
	};

	pll: pll {
		compatible = "mediatek,mt7621-pll", "syscon";
	
		#clock-cells = <1>;	//具有多个时钟输出的节点通常为1
		clock-output-names = "cpu", "bus";	// clk provider 输出多路clock的名称
	};
	
	sysclock: sysclock {
		#clock-cells = <0>;	//具有单个时钟输出的节点 为0
		compatible = "fixed-clock";
	
		/* FIXME: there should be way to detect this */
		clock-frequency = <50000000>; //用于设置clock输出的时钟频率；
	};
//寄存器映射位置
	palmbus: palmbus@1E000000 {
		compatible = "palmbus";
		reg = <0x1E000000 0x100000>;
		ranges = <0x0 0x1E000000 0x0FFFFF>;

		#address-cells = <1>;
		#size-cells = <1>;
//System Control 0x1E000000 - 0x1E0000FF
		sysc: sysc@0 {
			compatible = "mtk,mt7621-sysc";
			reg = <0x0 0x100>;
		};
//Timer 0x1E000100 - 0x1E0001FF
		wdt: wdt@100 {
			compatible = "mediatek,mt7621-wdt";
			reg = <0x100 0x100>;
		};
//gpio 1E000600 - 1E0006FF
		gpio: gpio@600 {
			#gpio-cells = <2>;		//表示这个控制器下每一个引脚要用2个32位的数(cell)来描述。
			#interrupt-cells = <2>;
			compatible = "mediatek,mt7621-gpio";
			gpio-controller;		//表示这个节点是一个GPIO Controller，它下面有很多引脚。
			interrupt-controller;	//定义该节点为接收中断信号的设备
			reg = <0x600 0x100>;
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <GIC_SHARED 12 IRQ_TYPE_LEVEL_HIGH>;	//中断等级。包含中断说明符列表，对应于该设备上的每个中断输出信号。
		};
//I2C Controller 1E000900 - 1E0009FF
		i2c: i2c@900 {
			compatible = "mediatek,mt7621-i2c";
			reg = <0x900 0x100>;

			clocks = <&sysclock>;	//指定时钟
	
			resets = <&rstctrl 16>; //指定复位单元和复位说明符(指示哪个外设复位)。
			reset-names = "i2c";
	
			#address-cells = <1>;
			#size-cells = <0>;
	
			status = "disabled";
	
			pinctrl-names = "default";	//引脚配置名称(引脚默认状态)，属性值可以为"default"或"sleep"。
			pinctrl-0 = <&i2c_pins>;	//引脚引用列表
		};
//I2S Controller 1E000A00 - 1E000AFF
		i2s: i2s@a00 {
			compatible = "mediatek,mt7621-i2s";
			reg = <0xa00 0x100>;

			clocks = <&sysclock>;
	
			resets = <&rstctrl 17>;
			reset-names = "i2s";
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <GIC_SHARED 16 IRQ_TYPE_LEVEL_HIGH>;
//I2S具有一个DMA读通道和一个DMA写通道的设备
			txdma-req = <2>;
			rxdma-req = <3>;
/* dmas 	一个或多个DMA描述符 <dma控制器描述符	DMA控制器特定信息的phandle引用的节点中的属性。这通常包含DMA请求行号或通道号，但是可以包含配置通道所需的任何数据。>
dma-names 	为dmas属性中的每个DMA说明符包含一个标识符字符串。可以使用的特定字符串在DMA客户机设备的绑定中定义。*/
			dmas = <&gdma 4>,
				<&gdma 6>;
			dma-names = "tx", "rx";

			status = "disabled";
		};
//System Tick Counter 1E000500 - 1E00050F
		systick: systick@500 {
			compatible = "ralink,mt7621-systick", "ralink,cevt-systick";
			reg = <0x500 0x10>;

			resets = <&rstctrl 28>;
			reset-names = "intc";
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <GIC_SHARED 5 IRQ_TYPE_LEVEL_HIGH>;
		};
//Memory Controller 1E005000 - 1E005FFF
		memc: memc@5000 {
			compatible = "mtk,mt7621-memc";
			reg = <0x5000 0x1000>;
		};
//CM_CPC  1FBF0000 - 1FBF7FFF  这里有问题啊 为啥不减去 1E000000
		cpc: cpc@1fbf0000 {
			compatible = "mtk,mt7621-cpc";
			reg = <0x1fbf0000 0x8000>;
		};
//CM_GCR  1FBF8000 - 1FBFFFFF
		mc: mc@1fbf8000 {
			compatible = "mtk,mt7621-mc";
			reg = <0x1fbf8000 0x8000>;
		};
//UARTLITE 1 1E000C00 - 1E000CFF
		uartlite: uartlite@c00 {
			compatible = "ns16550a";
			reg = <0xc00 0x100>;

			clock-frequency = <50000000>;
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <GIC_SHARED 26 IRQ_TYPE_LEVEL_HIGH>;
	
			reg-shift = <2>;
			reg-io-width = <4>;
			no-loopback-test;
		};
//UARTLITE 2 1E000D00 - 1E000DFF
		uartlite2: uartlite2@d00 {
			compatible = "ns16550a";
			reg = <0xd00 0x100>;

			clock-frequency = <50000000>;
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <GIC_SHARED 27 IRQ_TYPE_LEVEL_HIGH>;
	
			reg-shift = <2>;	
			reg-io-width = <4>; 
	
			pinctrl-names = "default"; //引脚配置名称(引脚默认状态)，属性值可以为"default"或"sleep"。
			pinctrl-0 = <&uart2_pins>; //引脚引用列表
	
			status = "disabled";
		};
//UARTLITE 3 1E000E00 - 1E000EFF
		uartlite3: uartlite3@e00 {
			compatible = "ns16550a";
			reg = <0xe00 0x100>;

			clock-frequency = <50000000>;
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <GIC_SHARED 28 IRQ_TYPE_LEVEL_HIGH>;
	
			reg-shift = <2>;
			reg-io-width = <4>;
	
			pinctrl-names = "default"; //引脚配置名称(引脚默认状态)，属性值可以为"default"或"sleep"。
			pinctrl-0 = <&uart3_pins>; //引脚引用列表
	
			status = "disabled";
		};
//SPI CSR  1E000B00 - 1E000BFF
		spi0: spi@b00 {
			status = "disabled";

			compatible = "ralink,mt7621-spi";
			reg = <0xb00 0x100>;
	
			clocks = <&pll MT7621_CLK_BUS>;
	
			resets = <&rstctrl 18>;
			reset-names = "spi";
	
			#address-cells = <1>;
			#size-cells = <0>;
	
			pinctrl-names = "default";
			pinctrl-0 = <&spi_pins>;
		};
//Generic DMA 1E002800 - 1E002FFF
		gdma: gdma@2800 {
			compatible = "ralink,rt3883-gdma";
			reg = <0x2800 0x800>;

			resets = <&rstctrl 14>;
			reset-names = "dma";
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <0 13 4>;
	
			#dma-cells = <1>;		//DMA特定信息的个数
			#dma-channels = <16>;	//控制器支持的DMA信道数
			#dma-requests = <16>;	//控制器支持的DMA请求信号数量
	
			status = "disabled";
		};
//HS DMA  1E007000 - 1E007FFF
		hsdma: hsdma@7000 {
			compatible = "mediatek,mt7621-hsdma";
			reg = <0x7000 0x1000>;

			resets = <&rstctrl 5>;
			reset-names = "hsdma";
	
			interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
			interrupts = <0 11 4>;
	
			#dma-cells = <1>;		//DMA特定信息的个数
			#dma-channels = <1>;	//控制器支持的DMA信道数
			#dma-requests = <1>;	//控制器支持的DMA请求信号数量
	
			status = "disabled";
		};
	};
/* drivers/pinctrl/pinctrl-rt2880.c  rt2880_pmx_group_enable函数最后一行加入
dev_info(p->dev, "%s(%d),%s(%d)\t\t= %x\n", p->groups[group].name, group, p->func[func]->name, func, mode); 复用管脚的配置
dts文件中的pinctrl关键词表 。pin 的命名遵循IC spec上的命名，以每个pin默认的功能命名，但实际使用中各个pin的功能会随着配置发生变化。

设定设备的功能复用需要了解两个概念，一个是function，另外一个是pin group。function是功能抽象，对应一个HW逻辑block，
例如SPI0.虽然给定了具体的function name，我们并不能确定其使用的pins的情况。例如为了设计灵活，芯片内部的SPI0的功能引出到pin group{C6，C7，C8，C9}，
也可能引出的另外一个pin group{C22.C23，C24，C25}，但毫无疑问，这两个pin group不能同时active，毕竟芯片内部的SPI0的逻辑功能电路只有一个，
因此只有给出function selector以及function的pin group selector才能进行function mux 的设定。
*/
	pinctrl: pinctrl {
		compatible = "ralink,rt2880-pinmux";
		pinctrl-names = "default";
		pinctrl-0 = <&state_default>;

		state_default: pinctrl0 {
		};
	
		i2c_pins: i2c_pins {
			i2c_pins {
				groups = "i2c";
				function = "i2c";
			};
		};
	
		spi_pins: spi_pins {
			spi_pins {
				groups = "spi";
				function = "spi";
			};
		};
	
		uart1_pins: uart1 {
			uart1 {
				groups = "uart1";
				function = "uart1";
			};
		};
	
		uart2_pins: uart2 {
			uart2 {
				groups = "uart2";
				function = "uart2";
			};
		};
	
		uart3_pins: uart3 {
			uart3 {
				groups = "uart3";
				function = "uart3";
			};
		};
	
		rgmii1_pins: rgmii1 {
			rgmii1 {
				groups = "rgmii1";
				function = "rgmii1";
			};
		};
	
		rgmii2_pins: rgmii2 {
			rgmii2 {
				groups = "rgmii2";
				function = "rgmii2";
			};
		};
	
		mdio_pins: mdio {
			mdio {
				groups = "mdio";
				function = "mdio";
			};
		};
	
		pcie_pins: pcie {
			pcie {
				groups = "pcie";
				function = "gpio";
			};
		};
	
		nand_pins: nand {
			spi-nand {
				groups = "spi";
				function = "nand1";
			};
	
			sdhci-nand {
				groups = "sdhci";
				function = "nand2";
			};
		};
	
		sdhci_pins: sdhci {
			sdhci {
				groups = "sdhci";
				function = "sdhci";
			};
		};
	};
	
	rstctrl: rstctrl {
		compatible = "ralink,rt2880-reset";
		#reset-cells = <1>;
	};
	
	clkctrl: clkctrl {
		compatible = "ralink,rt2880-clock";
		#clock-cells = <1>;
	};
//SDXC 1E130000 - 1E137FFF
	sdhci: sdhci@1E130000 {
		status = "disabled";

		compatible = "ralink,mt7620-sdhci";
		reg = <0x1E130000 0x4000>;
	
		interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
		interrupts = <GIC_SHARED 20 IRQ_TYPE_LEVEL_HIGH>;
	
		pinctrl-names = "default";
		pinctrl-0 = <&sdhci_pins>;
	};
	
	xhci: xhci@1E1C0000 {
		#address-cells = <1>;
		#size-cells = <0>;
	
		compatible = "mediatek,mt8173-xhci";
		reg = <0x1e1c0000 0x1000
		       0x1e1d0700 0x0100>;
		reg-names = "mac", "ippc";
	
		clocks = <&sysclock>;
		clock-names = "sys_ck";
	
		interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
		interrupts = <GIC_SHARED 22 IRQ_TYPE_LEVEL_HIGH>;
	
		/*
		 * Port 1 of both hubs is one usb slot and referenced here.
		 * The binding doesn't allow to address individual hubs.
		 * hub 1 - port 1 is ehci and ohci, hub 2 - port 1 is xhci.
		 */
		xhci_ehci_port1: port@1 {
			reg = <1>;
			#trigger-source-cells = <0>;
		};
	
		/*
		 * Only the second usb hub has a second port. That port serves
		 * ehci and ohci.
		 */
		ehci_port2: port@2 {
			reg = <2>;
			#trigger-source-cells = <0>;
		};
	};
//CM_GIC 1FBC0000 - 1FBDFFFF
	gic: interrupt-controller@1fbc0000 {
		compatible = "mti,gic";
		reg = <0x1fbc0000 0x2000>;

		interrupt-controller;
		#interrupt-cells = <3>;
	
		mti,reserved-cpu-vectors = <7>;
	
		timer {
			compatible = "mti,gic-timer";
			interrupts = <GIC_LOCAL 1 IRQ_TYPE_NONE>;
			clocks = <&pll MT7621_CLK_CPU>;
		};
	};
	
	nficlock: nficlock {
		#clock-cells = <0>;
		compatible = "fixed-clock";
	
		clock-frequency = <125000000>;
	};
//NAND Controller *(actually 1K in Module) 		1E003000 - 1E0037FF
//NAND_ECC Controller *(actually 3K in module)	1E003800 - 1E003FFF
	nand: nand@1e003000 {
		status = "disabled";

		compatible = "mediatek,mt7621-nfc";
		reg = <0x1e003000 0x800
			0x1e003800 0x800>;
		reg-names = "nfi", "ecc";
	
		clocks = <&nficlock>;
		clock-names = "nfi_clk";
	};
//Crypto Engine 1E004000 - 1E004FFF
	crypto@1e004000 {
		compatible = "mediatek,mtk-eip93";
		reg = <0x1e004000 0x1000>;

		interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
		interrupts = <GIC_SHARED 19 IRQ_TYPE_LEVEL_HIGH>;
	};
//SYSCTL  1E000000 - 1E0000FF
	ethsys: syscon@1e000000 {
		compatible = "mediatek,mt7621-ethsys",
			     "syscon";
		reg = <0x1e000000 0x1000>;
		#clock-cells = <1>;
	};
//Frame Engine (FE SRAM: 0x1E108000~0x1E10DFFF) 1E100000 - 1E10DFFF
	ethernet: ethernet@1e100000 {
		compatible = "mediatek,mt7621-eth";
		reg = <0x1e100000 0x10000>;

		clocks = <&sysclock>;
		clock-names = "ethif";
	
		#address-cells = <1>;
		#size-cells = <0>;
	
		resets = <&rstctrl 6 &rstctrl 23>;
		reset-names = "fe", "eth";
	
		interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
		interrupts = <GIC_SHARED 3 IRQ_TYPE_LEVEL_HIGH>;
	
		mediatek,ethsys = <&ethsys>;
	
		pinctrl-names = "default";
		pinctrl-0 = <&rgmii1_pins &mdio_pins>;
	
		gmac0: mac@0 {
			compatible = "mediatek,eth-mac";
			reg = <0>;
			phy-mode = "rgmii";
	
			fixed-link {
				speed = <1000>;
				full-duplex;
				pause;
			};
		};
	
		gmac1: mac@1 {
			compatible = "mediatek,eth-mac";
			reg = <1>;
			status = "disabled";
			phy-mode = "rgmii-rxid";
		};
	
		mdio: mdio-bus {
			#address-cells = <1>;
			#size-cells = <0>;
	
			switch0: switch@1f {
				compatible = "mediatek,mt7621";
				#address-cells = <1>;
				#size-cells = <0>;
				reg = <0x1f>;
				mediatek,mcm;
				resets = <&rstctrl 2>;
				reset-names = "mcm";
	
				ports {
					#address-cells = <1>;
					#size-cells = <0>;
					reg = <0>;
	
					port@0 {
						status = "disabled";
						reg = <0>;
						label = "lan0";
					};
	
					port@1 {
						status = "disabled";
						reg = <1>;
						label = "lan1";
					};
	
					port@2 {
						status = "disabled";
						reg = <2>;
						label = "lan2";
					};
	
					port@3 {
						status = "disabled";
						reg = <3>;
						label = "lan3";
					};
	
					port@4 {
						status = "disabled";
						reg = <4>;
						label = "lan4";
					};
	
					port@6 {
						reg = <6>;
						label = "cpu";
						ethernet = <&gmac0>;
						phy-mode = "rgmii";
	
						fixed-link {
							speed = <1000>;
							full-duplex;
						};
					};
				};
			};
		};
	};
//Ethernet GMAC  1E110000 - 1E117FFF 32K
	gsw: gsw@1e110000 {
		compatible = "mediatek,mt7621-gsw";
		reg = <0x1e110000 0x8000>;
		interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
		interrupts = <GIC_SHARED 23 IRQ_TYPE_LEVEL_HIGH>;
	};
//PCI Express 1E140000 - 1E17FFFF 256K
	pcie: pcie@1e140000 {
		compatible = "mediatek,mt7621-pci";
		reg = <0x1e140000 0x100     /* host-pci bridge registers */
			0x1e142000 0x100    /* pcie port 0 RC control registers */
			0x1e143000 0x100    /* pcie port 1 RC control registers */
			0x1e144000 0x100>;  /* pcie port 2 RC control registers */
		#address-cells = <3>;
		#size-cells = <2>;

		pinctrl-names = "default";
		pinctrl-0 = <&pcie_pins>;
	
		device_type = "pci";
	
		bus-range = <0 255>;
		ranges = <
			0x02000000 0 0x00000000 0x60000000 0 0x10000000 /* pci memory */
			0x01000000 0 0x00000000 0x1e160000 0 0x00010000 /* io space */
		>;
	
		interrupt-parent = <&gic>; //当上级发生中断时才来查询是否是该中断。
		interrupts = <GIC_SHARED 4 IRQ_TYPE_LEVEL_HIGH
				GIC_SHARED 24 IRQ_TYPE_LEVEL_HIGH
				GIC_SHARED 25 IRQ_TYPE_LEVEL_HIGH>;
	
		status = "disabled";
	
		resets = <&rstctrl 24 &rstctrl 25 &rstctrl 26>;
		reset-names = "pcie0", "pcie1", "pcie2";
		clocks = <&clkctrl 24 &clkctrl 25 &clkctrl 26>;
		clock-names = "pcie0", "pcie1", "pcie2";
		phys = <&pcie0_phy 1>, <&pcie2_phy 0>;
		phy-names = "pcie-phy0", "pcie-phy2";
	
		reset-gpios = <&gpio 19 GPIO_ACTIVE_LOW>;
	
		pcie0: pcie@0,0 {
			reg = <0x0000 0 0 0 0>;
			#address-cells = <3>;
			#size-cells = <2>;
			ranges;
			bus-range = <0x00 0xff>;
		};
	
		pcie1: pcie@1,0 {
			reg = <0x0800 0 0 0 0>;
			#address-cells = <3>;
			#size-cells = <2>;
			ranges;
			bus-range = <0x00 0xff>;
		};
	
		pcie2: pcie@2,0 {
			reg = <0x1000 0 0 0 0>;
			#address-cells = <3>;
			#size-cells = <2>;
			ranges;
			bus-range = <0x00 0xff>;
		};
	};
	
	pcie0_phy: pcie-phy@1e149000 {
		compatible = "mediatek,mt7621-pci-phy";
		reg = <0x1e149000 0x0700>;
		#phy-cells = <1>;
	};
	
	pcie2_phy: pcie-phy@1e14a000 {
		compatible = "mediatek,mt7621-pci-phy";
		reg = <0x1e14a000 0x0700>;
		#phy-cells = <1>;
	};
};

```