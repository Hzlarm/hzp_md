# OpenWrt之网络网络配置文件详解

>/etc/config/network     // 网络配置，包含桥接、接口、路由配置
>/etc/config/wireless    // 无限设置和wifi网络定义
>/etc/config/dhcp        // dnsmasq软件包配置，包含dhcp和dns设置

### [/etc/config/network]( https://openwrt.org/start?id=docs/guide-user/base-system/basic-networking )

负责定义交换机VLAN，接口配置和网络路由。 配置完成后通过以下命令之一重新加载生效：

```shell
service network reload
/etc/init.d/network reload
```

/etc/config/network配置文件示例如下(也可以是使用`uci show network`查看uci形式的内容)：

```shell

config interface 'loopback'
        option ifname 'lo'
        option proto 'static'
        option ipaddr '127.0.0.1'
        option netmask '255.0.0.0'

config globals 'globals'
        option ula_prefix 'fdf2:e1cc:4a17::/48'

config interface 'lan'
        option type 'bridge'
        option ifname 'eth0.1 ra0 rai0'
        option proto 'static'
        option ipaddr '192.168.1.1'
        option netmask '255.255.255.0'
        option ip6assign '60'

config device 'lan_eth0_1_dev'
        option name 'eth0.1'
        option macaddr '20:76:93:51:0f:53'

config device 'lan_ra0_dev'
        option name 'ra0'
        option macaddr '20:76:93:51:0f:53'

config device 'lan_rai0_dev'
        option name 'rai0'
        option macaddr '20:76:93:51:0f:53'

config interface 'wan'
        option ifname 'eth0.2'
        option proto 'dhcp'

config device 'wan_eth0_2_dev'
        option name 'eth0.2'
        option macaddr '20:76:93:51:0f:55'

config interface 'wan6'
        option ifname 'eth0.2'
        option proto 'dhcpv6'

config switch
        option name 'switch0'
        option reset '1'
        option enable_vlan '1'

config switch_vlan
        option device 'switch0'
        option vlan '1'
        option ports '0 1 2 3 6t'

config switch_vlan
        option device 'switch0'
        option vlan '2'
        option ports '4 6t'

```



```sh
#要查看接口列表，请输入以下内容： 
ubus list network.interface.*
#要查看有关特定接口（UCI名称而不是物理接口）的所有信息，请输入：
ifstatus lan
```

**路由器的最小网络配置至少包括两个接口(lan和wan)和一个switch。**

#### Globals

globals section包含独立于接口的选项，这些选项会影响全局网络配置。

| Name              | Type            | Required | Default | Description                                                  |
| :---------------- | :-------------- | :------- | :------ | :----------------------------------------------------------- |
| `ula_prefix`      | IPv6-prefix     | no       | (none)  | IPv6 [ULA](https://en.wikipedia.org/wiki/Unique local address)-Prefix for this device |
| `packet_steering` | Packet-Steering | no       | (none)  | Use every cpu to handle packet traffic                       |

#### interface

interface section 声明逻辑网络服务：ip地址设置、别名、路由、物理接口名称和启动防火墙规则的容器，在openwrt中起着核心作用。

一个最小的interface：

```shell
#uci表示
network.wan=interface
network.wan.ifname='eth0.2'
network.wan.proto='dhcp'
#config file表示
config 'interface' 'wan'
        option 'proto' 'dhcp'
        option 'ifname' 'eth0.2'
```

- `wan`  ：是唯一的逻辑接口名称

- `dhcp` ： 指定接口协议

- `eth0.2` : 与本节关联的的物理接口

**注意：**

> linux内核限制了物理接口名称长度为15个字符，包括会自动添加的前缀(如：pppoa-，pppoe-，gre4t-, br-等)，所以逻辑接口名称仅限于9个字符。如果使用vlan表示法(额外需要5个字符)，则接口名称限制为4个字符。
>
> 如果 使用过长的名称将导致无错误提示且接口创建或修改不成功。

##### proto表：

| 协议                | 描述                                                         | 程序                               |
| :------------------ | :----------------------------------------------------------- | :--------------------------------- |
| `static`            | 具有固定地址和网络掩码的静态配置                             | `ip`/`ifconfig`                    |
| `dhcp`              | 地址和网络掩码由DHCP分配                                     | `udhcpc` (Busybox)                 |
| `dhcpv6`            | 地址和网络掩码由DHCPv6分配                                   | `odhcpc6c`                         |
| `ppp`               | PPP协议-拨号调制解调器连接                                   | `pppd`                             |
| `pppoe`             | 以太网上的PPP-DSL宽带连接                                    | `pppd` + `plugin rp-pppoe.so`      |
| `pppoa`             | ATM上的PPP-使用内置调制解调器的DSL连接                       | `pppd` + plugin …                  |
| `3g`                | 使用AT型3G调制解调器的CDMA，UMTS或GPRS连接                   | `comgt`                            |
| `qmi`               | 使用QMI协议的USB调制解调器                                   | `uqmi`                             |
| `ncm`               | 使用NCM协议的USB调制解调器                                   | `comgt-ncm` + ?                    |
| `wwan`              | 具有协议自动检测功能的USB调制解调器                          | `wwan`                             |
| `hnet`              | 自我管理家庭网络（HNCP）                                     | `hnet-full`                        |
| `pptp`              | 通过PPtP VPN连接                                             | ?                                  |
| `6in4`              | IPv6-in-IPv4隧道，用于隧道代理，如HE.net公司                 | ?                                  |
| `aiccu`             | 任何隧道里的任何东西                                         | `aiccu`                            |
| `6to4`              | 无状态IPv6 over IPv4传输                                     | ?                                  |
| `6rd`               | IPv6快速部署                                                 | `6rd`                              |
| `dslite`            | 双栈精简版                                                   | `ds-lite`                          |
| `l2tp`              | L2TP伪线隧道上的PPP                                          | `xl2tpd`                           |
| `relay`             | 中继伪桥                                                     | `relayd`                           |
| `gre`, `gretap`     | GRE over IPv4                                                | `gre` + `kmod-gre`                 |
| `grev6`, `grev6tap` | GRE over IPv6                                                | `gre` + `kmod-gre6`                |
| `vti`               | VTI over IPv4                                                | `vti` + `kmod-ip_vti`              |
| `vtiv6`             | VTI over IPv6                                                | `vti` + `kmod-ip6_vti`             |
| `vxlan`             | 用于第2层虚拟化的VXLAN协议，请参见[此处](https://openwrt.org/docs/guide-user/network/tunneling_interface_protocols)以获取更多信息和配置示例 | `vxlan` + `kmod-vxlan` + `ip-full` |
| `none`              | 未指定的协议，因此所有其他接口设置都将被忽略（例如禁用配置） | -                                  |

> 根据使用的*interface  protocol*，完整的接口声明可能还需要其他几个选项。下面列出了每个协议的相应选项。“必需”列中标记为“是”的选项必须在接口部分定义。如果使用相应的协议，则标记为“否”的选项可以定义，但也可以省略。

> 如果interface section未定义协议(甚至没有设置none)，则其他设置将被完全忽略。如果interface section提到了一个物理网络接口（如eth0），则即使连接了电缆，该接口也将关闭（proto哪怕为“ none”，该接口为打开）。

##### 适用于所有协议类型的其他选项

| 名称                | 类型              | 是否必须 | 默认                                    | 描述                                                         |
| :------------------ | :---------------- | :------- | :-------------------------------------- | :----------------------------------------------------------- |
| `ifname`            | interface name(s) | yes(*)   | *(none)*                                | 物理接口的名称，例如`eth0.1`，`eth2`或`tun0`分配给本节中，如果桥型设置的接口列表。<br/>*（\*）如果仅无线接口引用该网络，或者协议类型为`pptp`，则此选项可能为空或丢失，`pppoa`或者`6in4`*<br/>由于WLAN接口名称可能是动态的或不可预测的，因此[强烈建议](https://forum.openwrt.org/viewtopic.php?pid=203784#p203784)使用以下`network`选项将它们分配给网桥[UCI wireless 配置](https://openwrt.org/docs/guide-user/network/wifi/basic) |
| `type`              | string            | no       | *(none)*                                | 如果设置为“ bridge” ，则会创建一个包含给定*ifname*的bridge，以及使用[UCI wireless配置中](https://openwrt.org/docs/guide-user/network/wifi/basic)的`network`选项分配任何无线网络。 |
| `stp`               | boolean           | no       | `0`                                     | 仅对“ bridge”类型有效，启用生成树协议                        |
| `bridge_empty`      | boolean           | no       | `0`                                     | 仅对“ bridge”类型有效，启用创建空 bridges                    |
| `igmp_snooping`     | boolean           | no       | `0`                                     | 仅对“ bridge”类型有效，设置网桥的multicast_snooping内核设置  |
| `multicast_querier` | boolean           | no       | (takes over the value of igmp_snooping) | 仅对类型“ bridge”有效，设置网桥的multicast_querier内核设置   |
| `macaddr`           | mac address       | no       | *(none)*                                | 覆盖此接口的MAC地址。示例：62:11:22:aa:bb:cc                 |
| `mtu`               | number            | no       | *(none)*                                | 覆盖此接口上的默认MTU                                        |
| `auto`              | boolean           | no       | `0` for proto `none`, else `1`          | 指定是否在启动时启动接口                                     |
| `ipv6`              | boolean           | no       | `1`                                     | 指定在此接口上启用（1）还是禁用（0）IPv6（仅屏障断路器和更高版本） |
| ~~`accept_ra`~~     | ~~boolean~~       | ~~no~~   | ~~`1` for protocol `dhcp`, else `0`~~   | ~~Specifies whether to accept IPv6 Router Advertisements on this interface~~ **deprecated:** |
| ~~`send_rs`~~       | ~~boolean~~       | ~~no~~   | ~~`1` for protocol `static`, else `0`~~ | ~~Specifies whether to send Router Solicitations on this interface~~ **deprecated:** |
| `force_link`        | boolean           | no       | `1` for protocol `static`, else `0`     | 指定是否将IP地址，路由和可选的网关分配给该接口，而不考虑链接是否处于活动状态（'1'）或仅在链接变为活动状态（'0'）之后；设置为“ 1”时，载波侦听事件不会调用热插拔处理程序 |
| `disabled`          | boolean           | no       | `0启用或禁用接口部分                    |                                                              |
| `ip4table`          | string            | no       | *(none)*                                | 该接口路由的IPv4路由表。例如，当proto = dhcp时，dhcp客户端将向该表添加路由 |
| `ip6table`          | string            | no       | *(none)*                                | 该接口路由的IPv6路由表。例如，当proto = dhcp6时，dhcp6客户端将向该表添加路由 |

有关每个WAN协议可用的协议特定选项的文档，请参阅[wan_interface_protocols](https://openwrt.org/docs/guide-user/network/wan/wan_interface_protocols)。

#### switch

```shell
# swconfig list
Found: switch0 - ag71xx-mdio.0

# swconfig dev switch0 show
Global attributes:
	enable_vlan: 1
	enable_mirror_rx: 0
	enable_mirror_tx: 0
	mirror_monitor_port: 0
	mirror_source_port: 0
	arl_age_time: 300
	arl_table: address resolution table
[...]
```

有三种类型的switch相关的配置节中，`switch`，`switch_vlan`，和`switch_port`。

> 并非所有硬件上都提供所有选项。可能会发现一些限制`swconfig dev <dev> help`。进行更改后，检查的输出`swconfig`以确定配置是否已被交换机硬件接受。

##### config switch

| 选项名称              | 类型    | 是否需要 | 默认   | 作用                                                         | 说明                                                       |
| :-------------------- | :------ | :------- | :----- | :----------------------------------------------------------- | :--------------------------------------------------------- |
| `name`                | string  | yes      | (none) | 定义要配置的switch                                           |                                                            |
| `reset`               | `0|1`   |          |        |                                                              |                                                            |
| `enable_vlan`         | `0|1`   |          |        |                                                              |                                                            |
| `enable_mirror_rx`    | `0|1`   | no       | 0      | 将接收到的数据包从`mirror_source_port` 镜像到mirror_monitor_port` |                                                            |
| `enable_mirror_tx`    | `0|1`   | no       | 0      | 将传输的数据包从`mirror_source_port` 镜像到`mirror_monitor_port` |                                                            |
| `mirror_monitor_port` | integer | no       | 0      | Switch port to which packets are mirrored                    |                                                            |
| `mirror_source_port`  | integer | no       | 0      | Switch port from which packets are mirrored                  |                                                            |
| `arl_age_time`        | integer | no       | 300    | 调整地址解析（MAC）表的老化时间（秒）                        | 默认设置可能因硬件而异                                     |
| `igmp_snooping`       | `0|1`   | no       | 0      | 启用IGMP侦听                                                 | 不确定是否可以设置。未知它如何与接口或端口级IGMP侦听交互。 |
| `igmp_v3`             | `0|1`   | no       | 0      |                                                              | 不确定是否可以设置。未知它如何与接口或端口级IGMP侦听交互。 |

##### config switch_vlan

| 选项名称 | 类型    | 是否需要 | 默认   | 作用                                                         | 说明                                                         |
| :------- | :------ | :------- | :----- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| `device` | string  | yes      | (none) | 定义要配置的 switch                                          |                                                              |
| `vlan`   | integer | yes      | (none) | VLAN“表索引”配置                                             | 可能限制为127或其他数字。有关`swconfig dev <dev> help`限制，请参见输出。为VLAN标签和PVID设置默认值。 |
| `vid`    | integer | no       | `vlan` | 使用的VLAN标签号                                             | See the output of `swconfig dev <dev> help` for limit. VLANs 0 and 4095 are often considered “special use”. |
| `ports`  | string  | yes      | (none) | 一串用空格分隔的端口索引，应与VLAN关联。将后缀添加`t`到端口表示应该标记出口数据包，例如`'0 1 3t 5t`“ | 在较早发行版的上下文中，[docs：guide-user：network：switch](https://openwrt.org/docs/guide-user/network/vlan/switch)引用了后缀`*`和`u`，其中引用了某些Broadcom交换机。 |

##### config switch_port

| 选项名称        | 类型    | 是否需要 | 默认          | 作用                                       | 说明                                                         |
| :-------------- | :------ | :------- | :------------ | :----------------------------------------- | :----------------------------------------------------------- |
| `device`        | string  | yes      | (none)        | 定义要配置的 switch                        |                                                              |
| `port`          | integer | yes      | (none)        | 要配置的端口索引                           |                                                              |
| `pvid`          | integer | no       | †             | 端口PVID; 该VLAN标签††分配给未标记的传入包 | †通常默认为与端口关联的VLAN标记之一。当端口上有多个VLAN时，逻辑不明确。可能发生“ 0”。某些值已被拒绝；逻辑上没有明确的限制。††*可能*引用VLAN “索引”，而不是VLAN标记本身（未确认）。 |
| `enable_eee`    | `0|1`   | no       | 0             | 启用“节能”功能                             |                                                              |
| `igmp_snooping` | `0|1`   | no       | 0启用IGMP侦听 |                                            | 不确定是否可以设置。未知如何与接口级或交换机级IGMP侦听交互。 |
| `igmp_v3`       | `0|1`   | no       | 0             |                                            | 不确定是否可以设置。未知如何与接口级或交换机级IGMP侦听交互。 |

可以通过运行`/etc/init.d/Network restart`重新应用网络配置。

各个接口可以使用`ifup`或`ifdown`启动，其中name对应于相应配置接口部分的逻辑接口名称。ifup意味着一个先前的ifdown，因此在重新加载接口时不需要同时调用这两者。

请注意，无线接口由外部管理，ifup可能会中断与现有网桥的关系。在这种情况下，需要在ifup之后运行wifi up，以便重新建立网桥连接。

### [/etc/config/wireless](https://openwrt.org/docs/guide-user/network/wifi/basic)

> 如果设备具有以太网端口，则默认情况下无线功能为关闭状态。
>
> 可以通过修改`/etc/config/wireless`文件中的`option disabled '1'`为`option disabled '0'`（或者注释，删除都可以）将其打开。

`/etc/config/wireless`文件至少包含以下一对：

* *wifi device*  指定常规的radio属性，如：channel, driver type 和 txpower

* *wifi interface*  在wifi设备上定义无线网络

#### device

`wifi-device`是指系统中存在的物理无线电设备

一个最小的wifi设备声明类似如下。请注意，不同芯片组类型或驱动程序的标识符和选项可能有所不同。

```shell
config	wifi-device	'radio0'
	option	type	'broadcom'
	option	channel	'6'
```

- `radio0`是无线适配器的*内部标识符*
- `Broadco`指定芯片组/驱动程序类型
- `6`是设备运行的[无线信道](https://en.wikipedia.org/wiki/List_of_WLAN_channels)

下表列出了设备部分的可能选项。请注意，并非所有芯片组/驱动程序类型都使用所有选项

**常用选项**

| Name              | Type              | Required | Default                            | Description                                                  |
| :---------------- | :---------------- | :------- | :--------------------------------- | :----------------------------------------------------------- |
| *type*            | string            | yes      | *(autodetected)*                   | type在上电期间首次引导时确定，通常不需要改变。在brcm47xx平台是`Broadcom`，其他平台是`mac80211` |
| *phy*             | string            | no/yes   | *(autodetected)*                   | 与本section关联的无线物理设备。如果存在，通常是自动检测的，不需要修改。 |
| *macaddr*         | MAC address       | yes/no   | *(autodetected)*                   | 与本section关联的无线适配器，它不用于更改设备mac，而是用于标识基础接口。 |
| *disabled*        | boolean           | no       | *0*                                | *如果设置为*1，则禁用无线适配器。删除此选项或将其设置为0将启用适配器 |
| *channel*         | integer or “auto” | yes      | *auto*                             | 指定要使用的无线信道。“自动”默认为最低可用频道，或[使用ACS算法] [utilizes the ACS algorithm](https://forum.openwrt.org/t/wi-fi-channel-auto-selection/47776/8) 取决于硬件/驱动程序支持。 |
| *channels*        | list              | no       | *(regulatory domain specific)*     | 当通道处于“自动”模式时，请使用特定的通道。当自动选择频道时，此选项允许hostapd选择提供的频道之一。可以使用连字符（'-'）将通道提供为范围，也可以使用空格（''）分隔值来指定各个通道。 |
| *hwmode*          | string            | no       | *(driver default)*                 | 选择要使用的无线协议，可能的值为11b，11g(2.4g)和11a(5g)。请注意，11ng和11na不是可用选项，请参见 [ticket 17541](https://dev.openwrt.org/ticket/17541). |
| *htmode*          | string            | no       | *(driver default)*                 | 指定802.11n和802.11ac模式下的信道宽度。详情见 [this section](https://openwrt.org/docs/guide-user/network/wifi/basic#htmodethe_wi-fi_channel_width) 。可能的值为: *HT20*, *HT40-*, *HT40+*, *HT40*, or *VHT20*, *VHT40*, *VHT80*, *VHT160*, *NOHT* 禁用11n |
| *chanbw*          | integer           | no       | 20                                 | 指定窄通道宽度（MHz），可能的值为：*5*，*10*，*20*           |
| *ht_capab*        | string            | no       | *(driver default)*                 | 指定无线的可用功能。这些值是自动检测的。  [有关选项](http://w1.fi/cgit/hostap/tree/hostapd/hostapd.conf) (使用“refs”链接检查路由器上安装的hostapd版本) |
| *txpower*         | integer           | no       | *(driver default)*                 | 指定发射功率，单位为：dBm                                    |
| *diversity*       | boolean           | no       | *1*                                | 启用或禁用驱动程序的自动选择天线                             |
| *rxantenna*       | integer           | no       | *(driver default)*                 | 指定用于接收的*天线*，该值可能是特定于驱动器的，通常第一个天线的值为*1*，第二个天线的值为*2*。如果支持，指定*0*将启用驱动程序的自动选择。如果启用了多样性，则此选项无效 |
| *txantenna*       | integer           | no       | *(driver default)*                 | 指定用于传输的天线，值与*rxantenna相同*                      |
| *country*         | varies            | no       | *(driver default)*                 | 指定国家代码，影响可用信道和传输功率。对于*broadcom*类型，使用两个字母的国家代码（*EN*或*DE*）。*madwifi*驱动程序需要一个数字代码。 |
| *country_ie*      | boolean           | no       | 1 if *country* is set, otherwise 0 | 在信标和探测器响应帧中启用IEEE 802.11d国家/地区IE（信息元素）广告。这个IE包含国家代码和频道/功率图。需要*country*。 |
| *distance*        | integer           | no       | *(driver default)*                 | ap和最远客户端之间的距离（米）。                             |
| *beacon_int*      | integer           | no       | *100 (hostapd default)*            | 设置信标间隔。这是信标帧之间的时间间隔，以1.024 ms为单位测量。hostapd允许将其设置为15到65535之间。此选项仅对*ap*和*adhoc* wifi-ifaces有效 |
| *basic_rate*      | list              | no       | *(hostapd/driver default)*         | 设置支持的基本速率。每个基本速率以kb/s为单位。此选项仅对*ap*和*adhoc*wifi ifes有影响。 |
| *supported_rates* | list              | no       | *(hostapd/driver default)*         | 设置支持的数据速率。每个支持的速率以kb / s为单位。此选项仅对*ap*和*adhoc* wifi-ifaces有效。必须是basic_rate的超集。Basic_rate应该是最低的数据速率。 |
| *require_mode*    | string            | no       | *none*                             | （AP模式）设置允许连接的客户端支持的最低模式。支持的值：g = 802.11g，n = 802.11n，ac = 802.11ac |
| *log_level*       | integer           | no       | 2                                  | 设置log_level。支持的级别为：0 =详细调试，1 =调试，2 =参考消息，3 =通知，4 =警告 |
| *legacy_rates*    | boolean           | no       | *1*                                | 0禁用802.11b数据速率，1启用802.11b数据速率                   |

#### interfaces

> 一个完整的wireless，每个适配器至少包含一个`wifi-iface`部分来定义基于无线硬件之上的无线网络。某些驱动程序每个设备支持多个无线网络： 
>
> * broadcom，如果核心版本大于或等于9（参见dmesg | grep COREEV）
> * mac80211

 `wifi-iface`声明的最小示例 :

```shell
config	wifi-iface
	option	device		'radio0'
	option	network		'lan'
	option	mode		'ap'
	option	ssid		'WifiAP'
	option	encryption	'psk2'
	option	key			'password'
```

- `radio0`是基于`wifi-device`定义的底层无线硬件的标识符.
- `lan`指定Wi-Fi连接到的网络接口。
- `ap`是操作模式，本例中为*接入点*
- `WifiAP`是无线的SSID
- `psk2`指定无线加密方法，此处为WPA2 PSK
- `key`是WPA密码，至少8个字符

以下列出 了*wifi-iface*部分的常用配置选项。 

**常用选项**

| 名称                       | 类型                  | 是否需要 | 默认                       | 描述                                                         |
| :------------------------- | :-------------------- | :------- | :------------------------- | :----------------------------------------------------------- |
| *ifname*                   | string                | no       | *(driver default)*         | 为Wi-Fi接口指定自定义名称，否则将自动命名。最大长度：15个字符（有关更多信息，请参见[网络基础知识](https://openwrt.org/docs/guide-user/base-system/basic-networking)）。 |
| *device*                   | string                | yes      | *(first device id)*        | 指定使用的无线适配器，必须引用定义的*wifi-device* sections之一 |
| *network*                  | string                | yes      | *lan*                      | 指定要将无线连接到的网络接口。                               |
| *mode*                     | string                | yes      | *ap*                       | 选择无线网络接口控制器的操作模式。可能的值有*ap*，*sta*，*adhoc*，*wds*，*monitor*，*mesh* |
| *disabled*                 | boolean               | no       | *0*                        | 设置为1时，将禁用无线网络。                                  |
| *ssid*                     | string                | yes      | OpenWrt                    | 无线网络的广播SSID，对于托管模式，为连接到的网络的SSID       |
| *bssid*                    | BSSID address         | no       | *(driver default)*         | 覆盖网络的BSSID，仅适用于*adhoc*或*sta*模式。在*wds*模式下，指定另一个AP的BSSID来创建wds。 |
| *mesh_id*                  | Mesh ID               | no       | none                       | IEEE 802.11s中定义的mesh ID。如果设置，则无线接口在启动时将加入此mesh网络。如果不是，则必须在打开接口后调用`iw <iface> mesh join <mesh_id>`来加入网格。 |
| *hidden*                   | boolean               | no       | *0*                        | 如果设置为*1，*则关闭SSID广播                                |
| *isolate*                  | boolean               | no       | *0*                        | 将无线客户端彼此隔离，仅适用于*ap*模式。有关详细信息，请参[见此](https://forum.openwrt.org/t/clients-in-same-wlan-cant-reach-each-other/2501/22)帖子。 |
| *doth*                     | boolean               | no       | *0*                        | 启用802.11h支持。                                            |
| *wmm*                      | boolean               | no       | *1*                        | 启用WMM（802.11e）支持。802.11n支持所需                      |
| *encryption*               | string                | no       | *none*                     | 无线加密方法。可能的值为：*none*，*wep*，*psk*，*psk2*。对于WEP工作站模式，默认为“开放系统”身份验证。使用*wep + shared*或*wep + open*强制使用特定模式。 |
| *key*                      | integer or string     | no       | *(none)*                   | 在任何**WPA-PSK**模式下，这是一个字符串，它指定将从其派生预共享密钥的预共享密码。明文密钥的长度必须为8-63个字符。如果提供了一个64个字符的十六进制字符串，它将直接用作预共享密钥。在**WEP**模式下，它可以是一个整数，指定要使用的密钥索引（*key1*，*key2*，*key3*或*key4*。）或者，它可以是一个直接指定密码或密钥的字符串，如*key1所示*。在任何**WPA-Enterprise AP**模式下，此选项都有不同的解释。 |
| *key1*                     | string                | no       | *(none)*                   | WEP密码或密钥＃1（由*key中*的索引选择）。该字符串被视为从中派生WEP密钥的密码短语。如果提供了10个或26个字符的十六进制字符串，它将直接用作WEP密钥。 |
| *key2*                     | string                | no       | *(none)*                   | 和*key1一样*，是WEP密码或密钥＃2（由*key中*的索引选择）。    |
| *key3*                     | string                | no       | *(none)*                   | 和*key1一样*，是WEP密码或密钥＃3（由*key中*的索引选择）。    |
| *key4*                     | string                | no       | *(none)*                   | 和*key1一样*，是WEP密码或密钥＃4（由*key中*的索引选择）。    |
| *macfilter*                | string                | no       | *disable*                  | 指定*mac过滤器策略*，*disable*以禁用过滤器，*允许*将其视为白名单或*拒绝*将其视为黑名单。 |
| *maclist*                  | list of MAC addresses | no       | *(none)*                   | 放入mac过滤器的MAC地址列表（以空格分隔）。                   |
| *iapp_interface*           | string                | no       | *(none)*                   | 指定要用于802.11f（IAPP）的网络接口-仅在定义时启用。         |
| *rsn_preauth*              | boolean               | no       | *0*                        | 允许对WPA2-EAP网络进行预身份验证（并在WLAN信标中进行公告）。仅在指定的网络接口是网桥的情况下有效。 |
| *ieee80211w*               | integer               | no       | *0*                        | 启用MFP（802.11w）支持（0 =禁用，1 =可选，2 =必需）。**需要wpad / hostapd的“完整”版本以及Wi-Fi驱动程序的支持** |
| *ieee80211w_max_timeout*   | integer               | no       | *(hostapd default)*        | 指定802.11w关联SA查询的最大超时时间。                        |
| *ieee80211w_retry_timeout* | integer               | no       | *(hostapd default)*        | 指定802.11w关联SA查询重试超时。                              |
| *maxassoc*                 | integer               | no       | *(hostapd/driver default)* | 指定要连接的最大客户端数。                                   |
| *macaddr*                  | mac address           | no       | *(hostapd/driver default)* | 覆盖用于Wi-Fi接口的MAC地址。警告：如果指定的MAC地址是多播地址，则该覆盖将静默失败。为避免此问题，请确保指定的mac地址是有效的单播mac地址。 |
| *dtim_period*              | integer               | no       | *2 (hostapd default)*      | 设置DTIM（传递交通信息消息）周期。每这么多个信标帧将有一个DTIM。可以在1到255之间设置。此选项仅对*ap* wifi-ifaces有效。 |
| *short_preamble*           | boolean               | no       | *1*                        | 设置可选使用短前导                                           |
| *max_listen_int*           | integer               | no       | *65535 (hostapd default)*  | 设置允许的最大STA（客户端）侦听间隔。如果STA尝试以大于此值的侦听间隔进行关联，则将拒绝关联。此选项仅对*ap* wifi-ifaces有效。 |
| *mcast_rate*               | integer               | no       | *(driver default)*         | 设置固定的组播速率，以kb / s为单位。**仅在即席和网格模式下受支持** |
| *wds*                      | boolean               | no       | *0*                        | 设置[4地址模式](https://wireless.wiki.kernel.org/en/users/documentation/iw#using_4-address_for_ap_and_client_mode) |
| *owe_transition_ssid*      | string                | no       | *none*                     | 机会无线加密（OWE）过渡SSID（仅适用于OPEN和OWE网络）         |
| *owe_transition_bssid*     | BSSID address         | no       | *none*                     | 机会无线加密（OWE）过渡BSSID（仅适用于OPEN和OWE网络）        |

#### Start/Stop wireless

> 无线接口通过*wifi*命令启动和关闭。要在更改配置后（重新）启动无线网络，请使用*wifi*，禁用无线*网络*，然后关闭*wifi*。如果您的平台带有多个无线设备，则可以通过在*wifi*命令后跟设备名称作为第二个参数来分别启动或运行每个*无线*设备。注意：*wifi*命令具有可选的第一个参数，默认为*up*，即启动设备。为了使第二个参数确实成为第二个参数，必须赋予第一个参数，该参数可以是*down*以外的任何值。例如启动界面*wlan2*问题：*wifi up wlan2* ; 停止该界面：*wifi down wlan2*。如果平台还具有例如wlan0和wlan1，则将不会通过有选择地停止或启动wlan2来触摸它们。 
>
> `Usage: /sbin/wifi [config|up|down|reconf|reload|status]
> enables (default), disables or configures devices not yet configured.`

#### Regenerate configuration

> 要重建配置文件，例如在安装新的无线驱动程序之后，请删除现有的无线配置（如果有）并使用*wifi config*命令： 
>
> ```shell
> rm -f /etc/config/wireless
> wifi config
> ```

#### htmode: the Wi-Fi channel width

> Wi-Fi通道宽度是频率范围，即信号用于传输数据的宽度。一般而言，通道宽度越大，可以通过信号传输的数据越多。但是与所有内容一样，也有缺点。随着信道宽度的增大，与其他Wi-Fi网络或蓝牙的干扰成为一个更大的问题，而建立牢固的连接也变得更加困难。认为它就像高速公路。道路越宽，可以通过的流量（数据）越多。另一方面，您在路上的汽车（路线）越多，交通拥堵就越多。

> Wi-Fi标准允许10、20、22、40、80和160 MHz，但不再使用10MHz，80和160只能在5 GHz频率下使用，某些设备无法连接到具有信道宽度的AP超过40Mhz。

> 默认情况下，2.4 GHz频率使用20 MHz的通道宽度。20MHz的信道宽度足以跨越一个信道。40 MHz的信道宽度将两个相邻的20 MHz信道绑定在一起，形成40 MHz信道宽度; 因此，它允许更快的速度和更快的传输速率。一个“控制”通道用作主通道，另一个“扩展”用作辅助通道。主通道发送信标包和数据包，辅助通道发送其他包。扩展通道可以在控制通道的“上方”或“下方”，只要它不在频带之外即可。例如，如果您的控制频道为1，则您的扩展频道必须“高于”，因为低于频道1的任何内容都将低于2.4GHz ISM频段所允许的最低频率。扩展通道必须与控制通道的边缘连续且不重叠。

> `HT40+`表示20 MHz主频道的中心频率高于辅助频道的中心频率，`HT40-`否则。例如，如果中心频率149和中心频率153驻留在两个20 MHz信道上，则149plus表示将两个20 MHz信道捆绑在一起以形成40 MHz信道。

> 在2.4 GHz频段中使用HT40模式时，只有一个非重叠通道。因此，建议您不要在2.4 GHz频带中使用HT40模式。
>
> - `HT20` 高吞吐量20MHz，802.11n
> - `HT40` 高吞吐量40MHz，802.11n
> - `HT40-` 高吞吐量40MHz，802.11n，控制通道为波纹管扩展通道。
> - `HT40+` 高吞吐量40MHz，802.11n，控制信道在扩展信道之上。
> - `VHT20` 802.11ac支持超高吞吐量20MHz
> - `VHT40` 802.11ac支持超高吞吐量40MHz
> - `VHT80` 802.11ac支持极高的吞吐量80MHz
> - `VHT160` 高吞吐量160MHz，由802.11ac支持
> - `NOHT` 禁用11n
>
> **仅限802.11n设备40 MHz的通道宽度（最高300 Mbps）**
>
> 默认的最大通道宽度（`VT20`即20MHz）支持150Mbps的最大速度。将其增加到40MHz将使最大理论速度增加到300Mbps。要注意的是，在Wi-Fi流量很大的区域（和蓝牙等共享相同的无线电频率），40MHz可能会降低您的整体速度。使用40MHz时，设备**应**检测到干扰，然后回落至20MHz。编辑`htmode`文件中的选项，`/etc/config/wireless`然后重新启动Wi-Fi AP以测试各种通道宽度。请注意，*应将htmode*选项设置为`HT40+`（对于通道1-7）或`HT40-`（对于通道5-11）或简单地设置`HT40`。

###  [/etc/config/dhcp](https://openwrt.org/docs/guide-user/base-system/dhcp)





## Alias 别名

https://openwrt.org/docs/guide-user/network/network_interface_alias





 https://openwrt.org/zh/docs/guide-user/network/vlan/switch_configuration 

 https://openwrt.org/docs/guide-user/network/vlan/switch 

 https://oldwiki.archive.openwrt.org/zh-cn/doc/networking/network.interfaces 

 https://www.right.com.cn/FORUM/thread-181806-1-1.html 











无线桥接与无线中继 -70dm以内

无线中继 适合家庭网络扩展，相当于无线交换机，他的LAN通过无线连接到主路由的LAN，同时也是LAN口连接手机等设备。通过LAN口进行数据转发。ssid与主路由ssid相同，IP在同一网段。主路由开DHCP自身不开DHCP。Repeter



无线桥接 适合蹭网。WAN连接上层路由的LAN。自身的LAN开辟一个新的内网。与上层路由，ssid不同，网段不同，DHCP均开启。



base

https://openwrt.org/docs/guide-user/base-system/start

各种uci

https://openwrt.org/docs/guide-user/base-system/uci#get_wan_interface