>/etc/config/network     // 网络配置，包含桥接、接口、路由配置
>/etc/config/wireless    // 无限设置和wifi网络定义
>/etc/config/dhcp        // dnsmasq软件包配置，包含dhcp和dns设置

### [/etc/config/network](https://openwrt.org/start?id=docs/guide-user/base-system/basic-networking)

/etc/config/network配置文件示例如下(也可以是使用`uci show network`查看uci形式的内容)：

`interface`是逻辑网络如：wan、lan、loopback。`device`是实际网络设备，可能是物理的也可能是虚拟的，处于数据链路层。

针对每个网络接口的配置都有一个类型为 interface 这样的 section，每个 interface 要么直接指向一个以太网/WIFI 设备（eth0、wlan0）或者包括多个设备的桥接。

由于device属于L2层的概念，如果用户对一个网络设备配置属于L3或更高层协议的属性， 则要直接对interface进行操作，进而间接作用于device。因此一个interface必须绑定到一个device上 。



```shell
#使用以下命令可以查看本路由器的网络接口，有哪些物理接口哪些是虚拟接口。
#eth0是一块物理网卡。eth0.1 eth0.2都是从此设备上虚拟出来的。
#eth0.1 是vlan1分出的lan口。
#eth0.2 是vlan分出的wan口。
#ls /sys/class/net/
#br-lan -> ../../devices/virtual/net/br-lan
#eth0 -> ../../devices/platform/1e100000.ethernet/net/eth0
#eth0.1 -> ../../devices/virtual/net/eth0.1
#eth0.2 -> ../../devices/virtual/net/eth0.2
#lo -> ../../devices/virtual/net/lo
#sit0 -> ../../devices/virtual/net/sit0
#wlan0 -> ../../devices/platform/1e140000.pcie/pci0000:00/0000:00:01.0/0000:02:00.0/net/wlan0
#wlan1 -> ../../devices/platform/1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/net/wlan1


#interface section 声明逻辑网络服务：ip地址设置、别名、路由、物理接口名称和启动防火墙规则的容器，在openwrt中起着核心作用。
config interface 'loopback'		#逻辑接口的名称
        option ifname 'lo'		#与本section逻辑接口关联的物理接口名称，虚拟设备，回环网
        option proto 'static'	#静态配置，需要同时配置ip与子网掩码
        option ipaddr '127.0.0.1'	#静态ip地址
        option netmask '255.0.0.0'	#子网掩码

#globals section包含独立于接口的选项，这些选项会影响全局网络配置。
config globals 'globals'
        option ula_prefix 'fdf5:e6a8:1c8d::/48' 	#ipv6的前缀

#ifname 指明了 Linux 网络设备名称。如果想桥接一个或多个设备，可以将 ifname 设置成一个 list，并且添加一个 option type 'bridge'
config interface 'lan'			#逻辑接口lan
        option type 'bridge'	#桥接方式
        option ifname 'eth0.1 ra0 rai0'  #与lan接口关联的三个网络设备,eth0.1是vlan分出的lan口，ra0与rai0是两个无线设备分别对应2.4G与5G。
        option proto 'static'	#静态配置，必须要同时配置ip与子网掩码， gateway 和 dns 是可选的。可以设置多个 dns，以空格分隔。
        option ipaddr '192.168.1.1'		#静态ip地址
        option netmask '255.255.255.0'	#子网掩码
        option ip6assign '60'			#将给定长度的前缀委托给此接口

#以下三个device，属于br-lan,br-lan = eth0.1 + rai0 + ra0，即将有线LAN口和无线网统一划分为 LAN，便于管理！使用brctl show 可查看。
config device 'lan_eth0_1_dev'
        option name 'eth0.1'
        option macaddr '20:76:93:51:0f:53'

config device 'lan_ra0_dev'
        option name 'ra0'
        option macaddr '20:76:93:51:0f:53'

config device 'lan_rai0_dev'
        option name 'rai0'
        option macaddr '20:76:93:51:0f:53'

config interface 'wan'			#逻辑接口wan	
        option ifname 'eth0.2'	#由下面vlan分出的wan口
        option proto 'dhcp'		#dhcp动态分配，只接受两个 option，分别是 ipaddr（想从 DHCP 服务器申请的 IP 地址）和 hostname（用于标识客户端 hostname），并且这两个 option 都是可选的。

#为eth0.2分配mac地址
config device 'wan_eth0_2_dev'
        option name 'eth0.2'
        option macaddr '20:76:93:51:0f:55'
#添加wan口ipv6的dhcp分配
config interface 'wan6'
        option ifname 'eth0.2'
        option proto 'dhcpv6'

config switch
        option name 'switch0'
        option reset '1'
        option enable_vlan '1'		#使能VLAN，即虚拟局域网

config switch_vlan
        option device 'switch0'
        option vlan '1'				#配置第一组VLAN，默认为eth0.1,对应的端口为0,1,2,3。四个LAN口
        option ports '0 1 2 3 6t'

config switch_vlan
        option device 'switch0'
        option vlan '2'			 	#配置第二组VLAN，默认为eth0.2,对应的端口为4。路由器中的WAN口。
        option ports '4 6t'
        
#option ports '0 1 2 3 6t'表示从端口 0，1，2，3 离开的帧将被解除 VLAN 标签，而从端口 6 离开的帧将被打上 VLAN 标签。端口6是CPU(eth0)详情往下看
```



```sh
root@OpenWrt:/# brctl show
bridge name     bridge id               STP enabled     interfaces
br-lan          7fff.207693510f53       no              wlan0
                                                        wlan1
                                                        eth0.1
#要查看接口列表，请输入以下内容： 
ubus list network.interface.*
#要查看有关特定接口（UCI名称而不是物理接口）的所有信息，请输入：
ifstatus lan
```

**路由器的最小网络配置至少包括两个接口(lan和wan)和一个switch。**

### [/etc/config/wireless](https://openwrt.org/docs/guide-user/network/wifi/basic)

> Wi-Fi信道宽度是频率范围，即信号传输数据的宽度。一般来说，信道宽度越大，通过信号传输的数据越多。g干扰也越大。默认情况下，2.4 GHz频率使用20 MHz信道宽度。

```shell
# wifi-device(描述wifi物理设备) 与 wifi-iface(基于物理设备的无线网络接口)是成对出现的
#新三路由器有两个无线设备分别为2.4G与5G。

#定义第一个无线设备名字在wifi-iface中使用
config wifi-device 'radio0'
        option type 'mac80211'	#type在上电期间首次引导时确定，通常不需要改变。在brcm47xx平台是`Broadcom`，其他平台是`mac80211`
        option channel '11'		#指定要使用的无线信道。“自动”默认为最低可用频道
        option hwmode '11g'		#选择要使用的无线协议，可能的值为11b，11g(2.4g)和11a(5g)。
        option path '1e140000.pcie/pci0000:00/0000:00:01.0/0000:02:00.0' 
        option htmode 'HT20'	#指定802.11n(2.4or5)和802.11ac(5g)模式下的信道宽度。
        option country 'US'

config wifi-iface 'default_radio0'
        option device 'radio0'	#基于物理radio0,定义无线网络
        option network 'lan'	#划分为/etc/config/network中的lan接口
        option mode 'ap'		#选择无线网络接口控制器的操作模式。可能的值有ap，sta，adhoc，wds，monitor，mesh
        option ssid 'OpenWrt_2.4G'
        option encryption 'none'#无线加密方法。可能的值为：none，wep，psk，psk2
        option disabled '0'

config wifi-device 'radio1'
        option type 'mac80211'
        option channel '36'
        option hwmode '11a'
        option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
        option htmode 'VHT80'	#VHT80甚高吞吐量80MHz，支持802.11ac。(20,40,80,160)
        option country 'US'

config wifi-iface 'default_radio1'
        option device 'radio1'
        option network 'lan'
        option mode 'ap'
        option ssid 'OpenWrt_5G'
        option encryption 'none'
        option disabled '0'
```



### [/etc/config/dhcp](https://openwrt.org/docs/guide-user/base-system/dhcp)

openwrt 使用同一个程序 dnsmasq 来实现 DHCP 服务器和 DNS 服务器。

```shell
config dnsmasq
#这四个选项保证了本地域名的请求，不会转发到上游域名解析服务器上。
        option domainneeded '1'	#
        option boguspriv '1'
        option localise_queries '1'
        option expandhosts '1'
        
        option filterwin2k '0'		#不要转发公共名称服务器无法响应的请求。如果需要解析SRV记录或使用SIP电话，请确保禁用该功能。    

        option rebind_protection '1'	#通过丢弃上游RFC1918响应来启用DNS重新绑定攻击保护
        option rebind_localhost '1'		#允许上游127.0.0.0/8响应（基于DNS的黑名单服务所需）仅在启用重新绑定保护时生效

        #local和domain选项使得dnsmasq使用/etc/hosts文件里的条目定义来提供解析，如果DHCP配置了lan的域，那么获得地址的客户机也可以通过主机名解析。
        option local '/lan/'
        option domain 'lan'

        option nonegcache '0'	#禁止缓存否定的“没有这样的域”响应
        option authoritative '1'	#选项保证了路由器成为本网络上的唯一一台DHCP服务器；客户机可以更快的获取IP地址的配置。
        option readethers '1'	#从“/etc/ethers”读取静态租约条目，在SIGHUP上重新读取

        option leasefile '/tmp/dhcp.leases'	#用于保存租约内容，这样如果dnsmasq如果重启的话就可以根据该文件重新维护租约信息。
        option resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'	#定义了dnsmasq使用的文件，该文件用于找到上游服务器，通常由WAN DHCP客户端和PPP客户端创建。
        option nonwildcard '1'	#只绑定已配置的接口地址，而不是通配符地址。
        option localservice '1'	#仅接受来自地址位于本地子网（即服务器上存在接口的子网）的主机的DNS查询。
        option filter_aaaa '1'

config dhcp 'lan'
        option interface 'lan'	#指定了DHCP服务器的服务接口“lan”
        option start '100'		#start：100 是客户端分配的IP地址起点 
        option limit '150'		#limit: 150 总共可以分配150个IP 地址
        option leasetime '12h'	#12h 表示客户端得到的地址租约时间为 12 小时
        option dhcpv6 'server'
        option ra 'server'
        option ra_slaac '1'
        list ra_flags 'managed-config'
        list ra_flags 'other-config'

config dhcp 'wan'
        option interface 'wan'
        option ignore '1'

config odhcpd 'odhcpd'
        option maindhcp '0'
        option leasefile '/tmp/hosts/odhcpd'
        option leasetrigger '/usr/sbin/odhcpd-update'
        option loglevel '4'

config srvhost
        option srv '_vlmcs._tcp'
        option target 'OpenWrt'
        option port '1688'
        option class '0'
        option weight '100'

```

### 总结

Linux 的网络接口(Network Interfaces)分为两种:

* 物理网络接口 : `eth0`, `eth8`, `radio0`, `wlan19`  这些符号总是代表着真实存在的网络设备 .当设备驱动加载到内核，这些网络接口就可以使用了。
* 虚拟网络接口： `lo`, `eth0:1`, `eth0.1`, `vlan2`, `br0`, `pppoe-dsl`, `gre0`, `sit0` `tun0`, `imq0`, `teql0`, .. 这些都是不真实存在物理网络设备的虚拟的网络接口 ，需要链接到物理网络设备才可以使用。增加了系统的灵活性。

[switch 交换机手册](https://oldwiki.archive.openwrt.org/zh-cn/doc/uci/network/switch)重点知识，需要慢慢领悟。

 [VLAN](https://openwrt.org/zh/docs/guide-user/network/vlan/switch_configuration)是**V**irtual **L**ocal **A**rea **N**etwork（即：虚拟局域网）。 它是物理网络交换设备在OSI第2层(即：数据链路层)上的虚拟隔断。 

>它是一种无需配置完整的子网和路由却能隔离即便使用了同一个物理网络客户端的方法，工作原理是在网络流量中添加一个标签（VLAN ID）并使用这个标签来决定流量路径进而将客户端分隔在不同VLAN中。要使用VLAN，您需要至少2个支持VLAN功能的设备（任何路由都需要至少2端），通常为高级路由器、任何运行OpenWrt的设备、任何自响应的PC，或者单板电脑。(Windows，MacOS，Linux和BSDs均支持VLAN)
>
>OpenWrt支持 [IEEE 802.1Q](https://en.wikipedia.org/wiki/IEEE_802.1Q) 和 [IEEE 802.1ad](https://en.wikipedia.org/wiki/IEEE_802.1ad) VLAN标准。
>
>许多多端口嵌入式设备都包含支持VLAN的交换机（比如：所有带WAN口的路由器都包含支持VLAN的交换机），单端口设备和每个端口都有以太网控制器的设备（例如PC开发板或一般大多数PC硬件）则由操作系统驱动程序管理VLAN。

####  通过多数OpenWrt路由器默认方案来解释VLAN

 许多现成路由器中一个常见默认VLAN配置是LAN↔WAN隔离，此类设备上的OpenWrt默认配置通常会反映出厂配置：仅有一个网络接口（eth0），因此启用不同的VLAN将支持VLAN的5口交换机虚拟隔离出LAN和WAN网络。 

| VLAN ID | 传入: 硬件交换机 ↑↓ eth0 驱动 | xx     | xx     | xx     | xx     | xx     |
| ------- | ----------------------------- | ------ | ------ | ------ | ------ | ------ |
|         | CPU (eth0)                    | LAN 1  | LAN 2  | LAN 3  | LAN4   | WAN    |
| 1       | 已标记                        | 未标记 | 未标记 | 未标记 | 未标记 | 禁用   |
| 2       | 已标记                        | 禁用   | 禁用   | 禁用   | 禁用   | 未标记 |

xx为：（传出: 硬件交换机 ↑↓ 物理端口）

示例中，LAN口的VLAN ID是1，而WAN的VLAN ID则是2. 注意：“传入”和“传出”及类似术语是指到达交换机物理端口（或内部CPU端口）的网络流量，而不是指已经进入交换机的流量。

- **已标记** 的CPU (eth0)意味着被本例中的1，2两个VLAN ID使用作为“已标记数据”发送到CPU。请记住：您只能将“已标记”数据发送到已配置能正确处理VLAN的设备。
- **未标记** 意味着交换机上这的这些接口仅接受不带任何VLAN ID的传入流量（比如正常的以太网流量），交换机将丢弃这些接口传出流量的VLAN ID。每个端口仅能在一个VLAN ID下标识为“未标记”。
- **禁用** 意味着，在此VLAN ID下该端口将不允许流量“传入”和“传出”。

路由器CPU通过上方配置的标签信息就知道数据是否来自VLAN1(LAN)或VLAN2(WAN)并进行相应地处理。使用默认配置时，CPU只接收和生成“已标记”的数据（因为没有其他方式告诉CPU这是什么那又是什么）。CPU作为单端口设备使用驱动级VLAN管理。

请注意，本例中的WAN和LAN的VLAN ID如何没有共用任何外部端口。对于任何跨越WAN和LAN边界的数据，它都必须通过eth0上的CPU（路由器和防火墙将在此处过滤数据）。如上所述，没有什么能够阻止VLAN完全绕开CPU。

 `ls -l /sys/class/net`来确认设备是否集成支持VLAN的硬件交换机。

不同的路由器具有不同的交换机布局， 

 如果有3个真正的网络端口：eth0，eth1和eth2。 每一个都指向了一个单独的不具有交换机的物理网络插孔。如要使用VLAN，您就需要基于VLAN配置使用操作系统软件 。如果仅有1个真正的网络端口：eth0。它的5个物理网络插孔属于一个支持VLAN的交换机，在此示例中，该交换机划为由交换机硬件管理eth0.1和eth0.2两个VLAN 。



理解交换机的基础概念。
VLAN是在以太网数据包上加4字节标记，叫TAG，属于一个VLAN的所有端口可以二层互通；不同VLAN的端口实现二层隔离。不同VLAN端口互通需要三层交换或路由。
一个端口不属于某个VLAN，就是关——是关闭的意思
一个端口属于某个VLAN，就是关联/不关联。这里又两层意思——  一是这个端口属于这个VLAN，接受的数据全部要加上TAG，然后发送给CPU处理；二是发送数据是否加TAG，关联：发送数据加TAG；不关联：发送数据不加TAG。
所以，如果一个端口接电脑，最好用不关联，否则需要在电脑网卡上配置VLAN号。如果一个端口接交换机，组成复杂网络，需要设置关联，加上TAG。


关联/不关联是对发送数据说的。关联：发送数据加TAG；不关联，发送数据不加TAG。所以，如果接口接电脑等终端设备，一律不关联；如果是接交换机，组大型网络，可能需要关联，设置VLAN。



