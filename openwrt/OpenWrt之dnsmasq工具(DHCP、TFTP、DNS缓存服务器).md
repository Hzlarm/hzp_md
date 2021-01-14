# OpenWrt之dnsmasq工具(DHCP、TFTP、DNS缓存服务器)

### 介绍

* 智能路由器服务于家庭和小型企业网络，当多个人同时上网时，客户机经常进行DNS查询，大多查询会是重复的域名，如果有一个 **DNS缓存代理** 服务于局域网，这样将减少DNS的因特网存取， **加快DNS访问速度和节省网络流量**  ，dnsmasq软件就是这样应运而生的。

- dnsmasq是轻量级DHCP、TFTP和DNS缓存服务器， **给小型网络提供DNS和DHCP服务** 。它的设计目标是轻量级的DNS，并且 **占用空间小** ，适用于资源受限的路由器和防火墙，以及智能手机、便携式热点设备等
-  **工作原理：** dnsmasq接收DNS请求，并从本地缓存中读取，如果缓存不存在就转发到一个真正的递归 DNS 服务器。它也可以读取/etc/hosts的内容，这样就可以对局域网的主机查询进行DNS查询响应，这些局域网的主机名称不会暴露在全局DNS域中

>### 本地DNS服务器
>
>- DNS子系统提供网络的本地DNS服务器，即只服务于局域网的DNS服务器。转发所有类型的查询请求到上游递归DNS服务器，并且缓存通用记录类型（A、AAAA、CNAME 和 PTR）。
>- 支持的主要特性有以下几方面：
> - 本地DNS服务器可以通过读取/etc/hosts来定义，或者通过导入DHCP子系统的名字，或者通过各种各样的用户配置
> - 上行服务器可以各种遍历的配置，包括动态配置
> - 认证DNS模式允许本地DNS名称导出到全球DNS区域。dnsmasq作为这个区域的认证服务器，也可以提供区域传送
> - 从上游服务器DNS响应执行DNSSEC验证，防止欺骗和缓存中毒
> - 指定子域名可以继承自它们的上行 DNS 服务器，这样使VPN配置更容易
> - 国际化域名支持等

### dnsmasq配置文件（/etc/config/dhcp）

- dnsmasq配置文件位于**`/etc/config/dhcp`**，**控制着DNS和DHCP服务选项**。默认配置包含一个通用的配置节来指定全局选项，还有一个或多个DHCP来定义动态主机配置服务的网络接口和地址池等。还可以包含多个域名和主机配置，并且提供客户端地址列表来查询。

```shell
#cat /etc/config/dhcp
config dnsmasq
        option domainneeded '1'
        option boguspriv '1'
        option filterwin2k '0'
        option localise_queries '1'
        option rebind_protection '1'
        option rebind_localhost '1'
        option local '/lan/'
        option domain 'lan'
        option expandhosts '1'
        option nonegcache '0'
        option authoritative '1'
        option readethers '1'
        option leasefile '/tmp/dhcp.leases'
        option resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'
        option nonwildcard '1'
        option localservice '1'
        option filter_aaaa '1'

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

config dhcp 'wan'
        option interface 'wan'
        option ignore '1'

config odhcpd 'odhcpd'
        option maindhcp '0'
        option leasefile '/tmp/hosts/odhcpd'
        option leasetrigger '/usr/sbin/odhcpd-update'
        option loglevel '4'

```

- local和domain选项使得dnsmasq使用/etc/hosts文件里的条目定义来提供解析，如果DHCP配置了lan的域，那么获得地址的客户机也可以通过主机名解析。
- domainneeded、 boguspriv、localise_qureies、以及expandhosts选项，保证了本地域名的请求，不会转发到上游域名解析服务器上。
- authoritative选项保证了路由器成为本网络上的唯一一台DHCP服务器；客户机可以更快的获取IP地址的配置。
- leasefile文件用于保存租约内容，这样如果dnsmasq如果重启的话就可以根据该文件重新维护租约信息。
- resolvfile定义了dnsmasq使用的文件，该文件用于找到上游服务器，通常由WAN DHCP客户端和PPP客户端创建。
- enable_tftp打开tftp服务，而tftp_root定义了TFTP服务器的文件根目录。你可以在客户端访问tftp服务器时，需要指定IP。在客户机，通过设定环境变量serverip来定义（e.g. setenv serverip 192.168.1.10)。

* rebind_protection ：通过丢弃上游RFC1918响应来启用DNS重新绑定攻击保护
* rebind_localhost ： 允许上游127.0.0.0/8响应（基于DNS的黑名单服务所需）仅在启用重新绑定保护时生效
* nonegcache： 禁止缓存否定的“没有这样的域”响应
* filterwin2k：不要转发公共名称服务器无法响应的请求。如果需要解析SRV记录或使用SIP电话，请确保禁用该功能。   
* readethers：从“/etc/ethers”读取静态租约条目，在SIGHUP上重新读取
* nonwildcard：只绑定已配置的接口地址，而不是通配符地址。
* localservice：仅接受来自地址位于本地子网（即服务器上存在接口的子网）的主机的DNS查询。

### 全局配置

- 下图所示的是dnsmasq的所有配置选项:

| 名 称             | 转换后配置          | 含 义 描 述                                                  |
| ----------------- | ------------------- | ------------------------------------------------------------ |
| domainneeded      | domain-needed       | 不会转发针对不带点的普通文本的A 或AAAA 查询请求到上行的域名 服务器。如果在/etc/hosts 和DHCP 中没有该名称将直接返回“not found” |
| cachesize         | cache-size          | 指定缓存的大小。默认是 150                                   |
| boguspriv         | bogus-priv          | 所有私有查找如果在/etc/hosts 没找到，将不转发到上行 DNS 服务器 |
| filterwin2k       | filterwin2k         | 不转发公共域名不能应答的请求                                 |
| localise_queries  | localise-queries    | 如果有多个接口，则返回从查询接口来的接口网络的主机 IP 地址。 在同一主机有多个 IP 地址时非常有用，返回查询网段的 IP 地址， 这样源主机和目标主机通信是将不会跨越路由器 |
| rebind_protection | stop-dns-rebind     | 上游域名服务器带有私有 IP 地址范围的响应报文将被丢弃         |
| rebind_localhost  | rebind-localhost-ok | 允许上游域名服务器的 127.0.0.0/8 响应， 这是采用 DNS 黑名单时所 需的服务， 这在绑定保护启用时使用 |
| expandhosts       | expand-hosts        | 在/etc/hosts 中的名称增加本地域名部分                        |
| nonegcache        | no-negcache         | 在通常情况下，“no such domain”也会缓存，下次查询时不再转发 到上游服务器而直接应答，这个选项将禁用“no such domain”返回 的缓存 |
| authoritative     | dhcp-authoritative  | 我们是局域网的唯一的 DHCP 服务器，当收到请求后会立即响应， 而不会等待，如果拒绝的话也会很快拒绝 |
| readethers        | read-ethers         | 从/etc/ethers 文件中读取静态分配的表项。格式为硬件地址和主机名 或 IP 地址，当收到 SIGHUP 信号时也会重新读取 |
| resolvfile        | resolv-file         | 指定一个 DNS 配置文件来读取上游域名服务器的地址，默认是从 /etc/resolv.conf 文件读取 |

### DHCP地址池配置

- 类型为dhcp的配置节指定了每一个接口的DHCP设置，通常最少有一个服务于局域网接口的dhcp配置设置
- **配置选项如下：**

| 名 称     | 含 义                                                        |
| --------- | ------------------------------------------------------------ |
| interface | 表示服务的网络接口，这个接口名称是 network 中配置的虚拟接口  |
| start     | 分配 IP 的起始地址                                           |
| limit     | 地址空间范围，默认为 150                                     |
| leasetime | DHCP 分配IP 地址的租期， start 和limit 在生成dnsmasq 的配置文件时进行组合为dhcp-range |
| ignore    | dnsmasq 将忽略从该接口来的请求                               |

例如：

```shell
config dhcp lan
    option interface lan	#指定了DHCP服务器的服务接口“lan”
    option start 100		#start：100 是客户端分配的IP地址起点 
    option limit 150		#limit: 150 总共可以分配150个IP 地址
    option leasetime 12h	#12h 表示客户端得到的地址租约时间为 12 小时
```

### 域名配置

- dnsmasq 支持自定义主机或者是自定义域名，使用 domain 配置节来管理自定义域名
- **配置选项如下：**

| 名 称 | 类 型   | 含 义                                  |
| ----- | ------- | -------------------------------------- |
| name  | 字符串  | 主机的域名，这个域名将不在因特网上查询 |
| ip    | IP 地址 | 域名对应的 IP 地址                     |

例如：

- 第一步：我们使用uci命令来增加两条自定义域名记录。首先创建一个类型为domain匿名的配置节， 然后设置其名称和 IP 地址

```shell
uci add dhcp host
uci set dhcp.@host[-1].ip = "192.168.6.120"
uci set dhcp.@host[-1].mac=" 08:00:27:9d:89:e7"
uci set dhcp.@host[-1].name="buildServer"
uci commit dhcp
```

- 第二步：记录被写到/etc/config/dhcp 文件中，但现在功能并未生效。调用重启 dnsmasq 进程命 令来使 dnsmasq 读取这些配置更改

`/etc/init.d/dnsmasq restart`

- 第三步：实际的配置将转换为 dnsmasq 的配置，配置文件为/var/etc/dnsmasq.conf，生效后内容如下：

```shell
config host
    option ip '192.168.6.120'
    option mac ' 08:00:27:9d:89:e7'
    option name 'buildServer
```

- 第四步：然后在 OpenWrt shell 中 ping 主机名称 bjbook.net。这时将访问 192.168.6.20 这个 IP 地址，并从 192.168.6.20 收到响应。这和主机系统的功能完全相同，只是在/etc/hosts 文件 中只在本机生效，如果加载这里就可以服务于家庭网

### 主机配置

- DHCP 在分配 IP 时，选择一个未使用的 IP 地址进行分配。假定有一个服务器，也是 通过 DHCP 进行 IP 分配的，这样每次重启后分配的 IP 地址可能发生改变，这在访问服务 器时还需查看其 IP 地址。根据 MAC 地址分配固定 IP 地址可以解决这个问题。在 DHCP 配置文件中使用 host 来配置
- **配置选项如下：**

| 名 称 | 类 型  | 含 义                                               |
| ----- | ------ | --------------------------------------------------- |
| ip    | 字符串 | 客户端所获得的 IP 地址                              |
| mac   | 字符串 | 主机的网卡 MAC 地址                                 |
| name  | 字符串 | DHCP 客户端所获取到的主机名称，是否使用由客户端决策 |

### DHCP客户端信息

- DHCP 还有一个功能是记录客户端列表。客户端列表显示当前所有通过 DHCP 服务器 获得 IP 地址主机的相关信息，包括客户端主机名称、MAC 地址、所获得的 IP 地址及 IP 地址的有效期。如下列出了所有保存字段的含义，我们可以通过/tmp/dhcp.leases 文件来 查看所有通过 DHCP 服务器获得 IP 地址的计算机信息
- **配置选项如下：**

| 类 别            | 含 义                                                        |
| ---------------- | ------------------------------------------------------------ |
| 有效时间（租期） | 指客户端计算机获得 IP 地址的有效时间，是指从 1970 年开始的一个秒值，到 这个时间之后地址将失效，客户端软件会在租期到期前自动续约 |
| MAC 地址         | 获得 IP 地址的客户端计算机的 MAC 地址                        |
| IP 地址          | DHCP 服务器分配给客户端计算机的 IP 地址                      |
| 客户端名称       | 显示获得 IP 地址的客户端计算机的主机名称                     |