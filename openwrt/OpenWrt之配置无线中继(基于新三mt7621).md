> 按照以下配置一条龙执行！
>
> ### 无线中继介绍
>
> **无线中继** 适合家庭网络扩展，相当于无线交换机，他的LAN通过无线连接到主路由的LAN，同时也是LAN口连接手机等设备。通过LAN口进行数据转发。ssid与主路由ssid相同，IP在同一网段。主路由进行DHCP。
>
> **无线桥接** 适合蹭网。WAN连接上层路由的LAN。自己的LAN开辟一个新的内网。与上层路由的ssid不同，网段不同，DHCP均开启。
>
> 无线桥接与无线中继 -70dm以内



### 配置完wireless 执行`wifi reload`

```shell
#vi /etc/config/wireless 

config wifi-device 'radio0'
	option type 'mac80211'
	option channel '2'      #需要与主路由设置同一频道
	option hwmode '11g'
	option path '1e140000.pcie/pci0000:00/0000:00:01.0/0000:02:00.0'
	option htmode 'HT20'
	option country 'US'

config wifi-iface
	option device 'radio0'
	option network 'wwan'
	option encryption 'psk2'
	option mode 'sta'
	option ssid 'upstream'	#上级路由ssid
	option key 'password'		#设置上级路由的密码

config wifi-iface
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'OpenWrt_2.4G'	#可与上级设置相同
	option encryption 'none'

config wifi-device 'radio1'
	option type 'mac80211'
	option channel '36'
	option hwmode '11a'
	option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
	option htmode 'VHT80'
	option country 'US'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'OpenWrt_5G'
	option encryption 'none'
	option disabled '1'
```

#### 配置network文件后执行`/etc/init.d/network reload`：

```shell
#vi /etc/config/network 

config interface 'loopback'
	option ifname 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config interface 'lan'
	option type 'bridge'
	option proto 'static'
	option ipaddr '192.168.1.1'		#为了支持中继设置192.168.x.x，但不会被客户端使用
	option gateway '192.168.2.1'	#主路由的IP
	option netmask '255.255.255.0'
	option dns '192.168.2.1'
	option ifname 'eth0.1'

config interface 'wwan'
	option proto 'static'
	option ipaddr '192.168.2.254'
	option netmask '255.255.255.0'
	option gateway '192.168.2.1'

config interface 'stabridge'
	option proto 'relay'
	option network 'lan wwan'
	option ipaddr '192.168.2.254'	#静态ip在主路由的地址范围内

config switch
	option name 'switch0'
	option reset '1'
	option enable_vlan '1'

config switch_vlan
	option device 'switch0'
	option vlan '1'
	option ports '0 1 2 3 4 6t'	#所有的口都设置为lan口了。即eth0.1
```

>配置完成后通过无线连接到上极路由了
>ping www.baidu.com 显示ok

### 连到上级热点之后需要安装relayd

```shell
#需要安装relayd
opkg update
opkg install luci-proto-relay
#或者安装relayd，不过在luci页面会显示不支持的协议类型，不影响使用

#/etc/init.d/relayd enable

#防火墙关闭或者修改
/etc/init.d/firewall stop
/etc/init.d/firewall disable
#或者在 vi /etc/config/firewall
config zone
    option name 'wan'
	option network 'wan wwan' #加入wwan

/etc/init.d/firewall restart
```

### 配置完dhcp执行`/etc/init.d/dnsmasq restart`


```shell
#vi /etc/config/dhcp
config dhcp 'lan'
	option interface 'lan'
	option start '100'
	option limit '150'
	option leasetime '12h'
	option dhcpv6 'server'
	option ra 'server'
	option ra_slaac '1'
	list ra_flags 'managed-config'
	list ra_flags 'other-config'
	option ignore '1'	#其实就加了这一句关闭dhcp分配

config dhcp 'wan'
	option interface 'wan'
	option ignore '1'
```









