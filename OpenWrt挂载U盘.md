**添加USB支持**

`Kernel modules —> USB Support —> <*> kmod-usb-core.  `##默认已经选了

`Kernel modules —> USB Support —> <*> kmod-usb-ohci.`  ##默认已选 old  usb1.0
`可选//Kernel modules —> USB Support —> <*> kmod-usb-uhci.`  ## 这里没有选择
>OHCI、UHCI都是USB1.1的接口标准，而EHCI是对应USB2.0的接口标准，最新的xHCI是USB3.0的接口标准。
>1. OHCI（Open Host Controller Interface）是支持USB1.1的标准，但它不仅仅是针对USB，还支持其他的一些接口，比如它还支持Apple的火线（Firewire，IEEE 1394）接口。与UHCI相比，OHCI的硬件复杂，硬件做的事情更多，所以实现对应的软件驱动的任务，就相对较简单。主要用于非x86的USB，如扩展卡、嵌入式开发板的USB主控。
>2. UHCI（Universal Host Controller Interface），是Intel主导的对USB1.0、1.1的接口标准，与OHCI不兼容。UHCI的软件驱动的任务重，需要做得比较复杂，但可以使用较便宜、较简单的硬件的USB控制器。Intel和VIA使用UHCI，而其余的硬件提供商使用OHCI。
>3. EHCI（Enhanced Host Controller Interface），是Intel主导的USB2.0的接口标准。EHCI仅提供USB2.0的高速功能，而依靠UHCI或OHCI来提供对全速（full-speed）或低速（low-speed）设备的支持。
>4. xHCI（eXtensible Host Controller Interface），是最新最火的USB3.0的接口标准，它在速度、节能、虚拟化等方面都比前面3中有了较大的提高。xHCI支持所有种类速度的USB设备（USB 3.0 SuperSpeed, USB 2.0 Low-, Full-, and High-speed, USB 1.1 Low- and Full-speed）。xHCI的目的是为了替换前面3中（UHCI/OHCI/EHCI）。

`Kernel modules —> USB Support —> <*> kmod-usb-storage.` 
官方提示必需的 …USB大容量存储设备的内核支持。

`Kernel modules —> USB Support —> <*> kmod-usb-storage-extras.`##可选 …内核支持更多驱动程序，例如SmartMedia读卡器。

`Kernel modules —> USB Support —> <*> kmod-usb2. ` ##默认已经选了 usb2.0

`可选// Kernel modules —> USB Support —> <*> kmod-usb3`  #如果设备不支持3.0不需要


**添加SCSI支持**
`Kernel modules —> Block Devices —> <*>kmod-scsi-core`  ##默认已经选了 ，任何大容量存储都是通用SCSI设备。

**添加USB挂载**
`Base system —> <*>block-mount`
如果使用fstab UCI配置或luci安装，必需推荐 …用于安装和检查块设备（文件系统和交换）和热插拔功能（插入设备时识别）的脚本。

**添加文件系统支持**
`Kernel modules —> Filesystems —> <*> kmod-fs-ext4` (移动硬盘EXT4格式选择)
`Kernel modules —> Filesystems —> <*> kmod-fs-vfat`(FAT16 / FAT32 格式 选择) 
~~`Kernel modules —> Filesystems —> <*> kmod-fs-ntfs `~~(NTFS 格式 选择)
`Utilities -> Filesystems -> <*> ntfs-3g` (挂载ntfs读写)
==如果选择 kmod-fs-ntfs挂载ntfs格式会变成只读，两个都选mount的时候需要-t ntfs-3g指定，否则会默认挂载ntfs只读。所以最好只添加ntfs-3g==
>FAT32格式，这种格式是Windows系统和Linux系统都支持的，但该格式仅支持32GB的最大分区和4GB单个文件写入
>EXT3格式，Linux系统支持，但该格式Windows不支持，需要安装其它软件才能识别
>NTFS格式的U盘或者硬盘来说，都是使用最广泛的一种。相比之下我们可以对此格式的U盘进行设置权限，并且可以做出FAT32不能实现的功能。在互换性和实用性来说，NTFS远高于FAT3。并且在支持文件上最大可以拓展为256T。看清楚，是256TB！只要是U盘或者硬盘能放得下的文件几乎可以读写


以上基本够用，也可以按照自己需求进行其他添加：

* 串口
		`+kmod-usb-serial +kmod-usb-serial-cp210x   `	 
* 内核模块根据网络活动、USB来驱动LED 
		`+kmod-ledtrig-usbdev  +kmod-ledtrig-netdev `
* exfat，扩展FAT，也称作FAT64	  
		`+kmod-fs-exfat `
* 添加本地语言支持：	
 >Latin1是ISO-8859-1的别名ISO-8859-1编码是单字节编码，向下兼容ASCII，其编码范围是0x00-0xFF，0x00-0x7F之间完全和ASCII一致，0x80-0x9F之间是控制字符，0xA0-0xFF之间是文字符号。cp936表示GBK，cp950表示Big5，cp437表示ASCII.各国编码标准互不兼容，推出统一标准Unicode，UTF-8：针对Unicode的可变长字符编码（多字节串，第一个字节在C0到FD之间，后面的字节在80到BF之间）
 >	`+kmod-nls-base +kmod-nls-cp437 +kmod-nls-iso8859-1 +kmod-nls-utf8 `

* e2fsprogs（也叫做e2fs programs）是一个Ext2（及Ext3/4）文件系统工具集（Ext2 Filesystems Utilities [1]  ），它包含了诸如创建、修复、配置、调试ext2文件系统等的标准工具。	
		`+e2fsprogs `
* Usbutils是Linux下查看USB设备信息的工具。	
		`+usbutils `


#### 热插拔[官方文档](https://openwrt.org/start?id=docs/guide-user/base-system/hotplug)
>当某些 events事件发生时，`Procd（init系统和进程管理守护进程）会执行位于/etc/hotplug.d/中的脚本`，例如当接口启动或关闭时，检测到新的存储驱动器时，或者按下按钮时.
>当使用PPPoE连接或者在不稳定的网络中，或使用硬件按钮时非常有用。
>该功能模块模拟/扩展了已淘汰的Hotplug2软件包的功能。

#### 工作原理
在 `/etc/hotplug.d` 文件夹包含了 block iface, net 和 ntp 等文件夹.
触发事件触发后，Procd将按字母顺序执行该触发器子文件夹中的所有脚本。 这就是为什么大多数脚本都使用数字前缀。
* block  块设备事件（块设备已连接/已断开连接）
* iface  接口事件（当LAN或WAN等接口连接/断开时）
* net  与网络相关的事件
* ntp  时间同步事件（Time step，时间服务器层变化）
* button 按钮事件 (默认不创建, 由 /etc/rc.button 代替)
* usb  类似3g-modem和tty*的USB设备
对于其他类型的触发器，可能（应该）是其他的。他们可以是按钮, 声音设备, 串口和USB串口加密狗。

#### 用法
只需将您的脚本放入正确的hotplug.d子目录中（如果没有），只需创建正确的子目录即可。
#### 提供给脚本的信息/故障排除
当在中执行脚本时/etc/hotplug.d，Procd 通常会以环境变量的形式提供大量信息。
如果要查看它提供了什么环境变量，请编写一个包含以下行的脚本：
`env > /tmp/envs_log.log`
并将其放在您要使用的文件夹中，然后触发连接到该文件夹的事件，然后您可以通过阅读/tmp/envs_log.log文本文件 来查看传递了哪些环境

#### 相关的环境变量
**block 文件夹**

![在这里插入图片描述](https://img-blog.csdnimg.cn/20191112184116666.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2h6bGFybQ==,size_16,color_FFFFFF,t_70)


**iface 文件夹** 

![在这里插入图片描述](https://img-blog.csdnimg.cn/20191112184145994.png)


**ntp 文件夹**

![在这里插入图片描述](https://img-blog.csdnimg.cn/20191112184215679.png)
即使没有NTP同步，也会收到一个定期的热插拔事件，其中stratum=16，开机后大约每11分钟一次


**USB文件夹**

![在这里插入图片描述](https://img-blog.csdnimg.cn/2019111218434757.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2h6bGFybQ==,size_16,color_FFFFFF,t_70)



#### U盘的自动挂载卸载
Hotplug一个常见的实例应用就是U盘或SD卡等外设的自动挂载和卸载功能。所以这里我们主要介绍如何利用hotplug实现U盘，移动硬盘等外设自动挂载的方法和原理。本文中的例子还需要根据实际情况作相应适配。

当然，首先得内核有相应的驱动程序支持才行。当U盘插入后，会产生uevent事件，hotplug收到这个内核广播事件后，根据uevent 事件json格式的附带信息内容，在hotplug.json中进行定位。事件包含的信息一般为如下所示：
`ACTION(add), DEVPATH(devpath), SUBSYSTEM(block), MAJOR(8), MINOR(1), DEVNAME(devname), DEVTYPE(devtype), SEQNUM(865)`
根据上面的信息，就可以在hotplug.json中定位到两个条目，如上面hotplug.json中蓝色显示字段。第一个条目执行的是makedev，该命令会创建设备节点。第二个条目会根据附带信息中的ACTION, DEVPATH, SUBSYSTEM, DEVNAME, DEVTYPE 等变量，调用命令exec去执行hotplug-call脚本。

于是 hotplug-call 会尝试执行 /etc/hotplug.d/block/ 目录下的所有可执行脚本。

所以我们可以在这里放置我们的自动挂载/卸载处理脚本。 例如，编写/etc/hotplug.d/block/30-usbmount,填入以下内容实现U盘自动挂载，卸载：

```shell
#!/bin/sh

[ "$SUBSYSTEM" = block ] || exit0
[ "$DEVTYPE" = partition -a "$ACTION" = add ] && {
    echo "$DEVICENAME" | grep 'sd[a-z][1-9]' || exit 0
    test -d /mnt/$DEVICENAME || mkdir /mnt/$DEVICENAME
    mount  -o iocharset=utf8,rw /dev/$DEVICENAME /mnt/$DEVICENAME
}

[ "$DEVTYPE" = disk -a "$ACTION" = remove ] && {
	b=1
    echo "$DEVICENAME"$b | grep 'sd[a-z][1-9]' || exit 0
    umount/mnt/$DEVICENAME$b && rmdir /mnt/$DEVICENAME$b
}
```