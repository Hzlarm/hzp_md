## Openwrt常用软件模块之NTP

### NTP简介

- NTP（Net Time Protocol）是用于互联网上**计算机时间同步的协议**。其中有NTP服务器来提供网络时间服务，客户端从服务器获取时间

### OpenWrt的NTP服务

- OpenWrt 路由器中内置了一些常用的NTP 时间服务器地址，一旦与因特网连接后，路由器可以自动从时间服务器获取当前时间， 然后设置到路由器系统当中
- OpenWrt默认支持内置的网络时间服务器，在配置文件**/etc/config/system**中设置。该选项用来设置NTP时间服务器的IP地址，可以设置多个网络时间服务器

```shell
# cat /etc/config/system 
config system
        option hostname 'hzlarm'
        option timezone 'UTC'
        option ttylogin '1'
        option log_size '64'
        option urandom_seed '0'

config timeserver 'ntp'
        option enabled '1'
        option enable_server '0'
        list server '0.openwrt.pool.ntp.org'
        list server '1.openwrt.pool.ntp.org'
        list server '2.openwrt.pool.ntp.org'
        list server '3.openwrt.pool.ntp.org'
```

- **注意：**
  - 关闭路由器电源后，没有电池的路由器时间信息会丢失，只有再次开机连上因特 网后，路由器才会自动获取 GMT 时间
  - 必须先设置系统时间后，路由器的防火墙的时间限定才能生效
  - 另外可以不采用NTP时间，通过date命令来手动设置系统时间

### date命令

- 可以不采用NTP时间，通过date命令来手动设置系统时间
- 在调试时我们可以使用date命令**手动设置路由器的时间**，然后等待路由器进行时间更新
- date命令如果没有指定选项，则**默认输出当前时间**
- **设置时间**需要传递一个-s选项，后面再以引号传递时间字符串。推荐使用 “YYYY-MM-DD hh:mm:ss”的格式进行时间设置：

```shell
date –s '2019-10-18 00:00:00'
```

### openwrt的NTP服务器（/etc/init.d/sysntpd）

- OpenWrt 也支持提供NTP服务器，可以控制配置文件来打开和关闭NTP服务器，系统重启后生效

- 也可以通过调用/etc/init.d/sysntpd restart命令生效，然后再重新设置配置文件

```shell
uci set system.ntp.enable=1 
uci commit system
```