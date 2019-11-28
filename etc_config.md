常用功能配置文件含义：

```shell
/etc/config/dhcp        // dnsmasq软件包配置，包含dhcp和dns设置
/etc/config/dropbear    // SSH服务器选项
/etc/config/firewall    // 防火墙设置，包含网络地址转换、包过滤、端口转发等
/etc/config/timeserver  // rdate的时间服务列表
/etc/config/luci        // 基本的LuCI配置
/etc/config/uhttpd      // web服务器选项配置
/etc/config/upnpd       // miniupnpd UPnP服务设置
/etc/config/qos         // 网络服务质量的配置文件定义

/etc/config/system      // 系统配置，包含主机名称、网络时间同步等
/etc/config/network     // 网络配置，包含桥接、接口、路由配置
/etc/config/wireless    // 无限设置和wifi网络定义
```



- 网络模式切换（Router，Repeater），每一种又分为dhcp和static，涉及配置文件/etc/config/network & /etc/config/wireless
    - **Router & dhcp** : mac地址相关的参数不要直接复制,信道需要手动修改
    
      ```shell
      # vi /etc/config/network
      
      config interface 'loopback'
              option ifname 'lo'
              option proto 'static'
              option ipaddr '127.0.0.1'
              option netmask '255.0.0.0'
      
      config globals 'globals'
              option ula_prefix 'fd6c:eb2d:4f69::/48'
      
      config interface 'lan'
              option force_link '1'
              option macaddr 'ac:23:3f:c0:2f:87'
              option type 'bridge'
              option proto 'static'
              option ipaddr '192.168.99.1'
              option netmask '255.255.255.0'
              option ip6assign '60'
      
      config switch
              option name 'switch0'
              option reset '1'
              option enable_vlan '0'
      
      config interface 'wan'
              option ifname 'eth0'
              option proto 'dhcp'
      
      ```
    
      ```shell
      # vi /etc/config/wireless
      
      config wifi-device         mt7628
              option type        mt7628
              option vendor      ralink
              option band        2.4G
              option channel     '0'
              option autoch      '1'
              option wifimode    '9'
              option radio       '1'
              option bw          '0'
              option country     'CN'
              option region      '1'
              
      config wifi-iface
              option device      mt7628
              option ifname      ra0
              option network     lan
              option mode        ap
              option disabled    '0'
              option ssid        GW-AC233FC02F87
              option encryption  none
              option wpa_crypto  TKIP+AES
              option key         
      
      ```
    
    - **Router & static** : 在Router & dhcp的模式基础上直接修改片段
    
      ```shell
      # vi /etc/config/network
      
      config interface 'wan'
              option ifname 'eth0'
              option proto 'static'
              option ipaddr '192.168.0.3'
              option netmask '255.255.255.0' 
              option gateway '192.168.0.1'
              option dns '114.114.114.114 8.8.8.8'
      ```
    
    - **Repeater & dhcp**:
    
      ```shell
      # vi /etc/config/network
      
      config interface 'loopback'
              option ifname 'lo'
              option proto 'static'
              option ipaddr '127.0.0.1'
              option netmask '255.0.0.0'
      
      config globals 'globals'
              option ula_prefix 'fd6c:eb2d:4f69::/48'
      
      config interface 'lan'
              option force_link '1'
              option macaddr 'ac:23:3f:c0:2f:87'
              option type 'bridge'
              option proto 'static'
              option ipaddr '192.168.99.1'
              option netmask '255.255.255.0'
              option ip6assign '60'
              option ifname 'eth0'
      
      config switch
              option name 'switch0'
              option reset '1'
              option enable_vlan '1'
      
      config interface 'wan'
              option ifname 'apcli0'
              option proto 'dhcp'
      ```
      
    ```shell
      # vi /etc/config/wireless
      
      config wifi-device 'mt7628'
              option type 'mt7628'
              option vendor 'ralink'
              option band '2.4G'
              option wifimode '9'
              option radio '1'
      		option bw '0'
            	option country 'CN'
              option region '1'
              option channel '2'  #需要手动分析信道
              option autoch '0'
      
      config wifi-iface
              option device 'mt7628'
              option ifname 'ra0'
              option network 'lan'
              option mode 'ap'
              option disabled '0'
              option ssid 'GW-AC233FC02F87'
              option encryption 'none'
              option wpa_crypto 'TKIP+AES'
              option ApCliSsid '@PHICOMM_AE'
              option ApCliEnable '1'
              option ApCliAuthMode 'WPA2PSK'
              option ApCliEncrypType 'AES'
              option ApCliWPAPSK 'beacon888'
      
      ```
      
    - **Repeater & static** : 在Repeater & dhcp 的模式基础上直接修改片段
    
      ```shell
      # vi /etc/config/network
      
      config interface 'wan'
              option ifname 'apcli0'
              option proto 'static'
              option ipaddr '192.168.2.99'
              option netmask '255.255.255.0'
              option gateway '192.168.2.1'
              option dns '8.8.8.8'
      ```



 - **/etc/config/network**
   
      - <https://openwrt.org/docs/guide-user/base-system/basic-networking> 官方对/etc/config/network的解析
      
    - **/etc/config/wireless**
    
      - 该文件会因为wifi的驱动不同而不同





```shell
#package/base-files/files/etc/config/system来修改固件
#vi /etc/config/system
config system
        option hostname Thingoo
        option timezone CST-8

config timeserver ntp
        list server     0.openwrt.pool.ntp.org
        list server     1.openwrt.pool.ntp.org
        list server     2.openwrt.pool.ntp.org
        list server     3.openwrt.pool.ntp.org
        option enabled 1
        option enable_server 0
```