## Openwrt常用软件模块之uHTTPd

### uHTTPd概述

>   uHTTPd 是 OpenWrt/LuCI 开发者从零开始编写的 Web 服务器，目的是成为优秀稳定 的、适合嵌入式设备的轻量级任务的 HTTP 服务器，并且和 OpenWrt 配置框架非常好地 集成在一起。它是管理 OpenWrt 的默认的 Web 服务器，还提供了现代 Web 服务器所有的 功能 。
>
>   - uHTTPd**支持TSL（SSL）、CGI和 Lua**，是单线程运行但支持多个实例，例如多个监听端口，每一个都有自己的根目录和其他特性
>   - 使用**TLS（HTTPS 支持）时需要安装uhttpd-mod-tls模块**
>   - 和许多其他的Web服务器一样，它也支持在进程内运行Lua，这样可以加速Lua CGI脚本。注意这依赖于Lua，默认情况下没有这样配置

### 安装

- uHTTPd是OpenWrt 的标准HTTP服务器，但是它默认并不会安装在OpenWrt发行版的系统文件中。因为默认的发行版并不包含 Web 用户管理界面，通常 uHTTPd 会作为 Web 接口 LuCI 的依赖模块自动安装
- 如果需要**单独安装**，可以通过以下命令来实现：

```sh
opkg update
 
opkg install uhttpd
```

### 配置

- uHTTPd也提供一个初始化脚本/etc/init.d/uhttpd来启动或停止服务，或者在系统启动时自动启动

- uHTTPd的配置和OpenWrt用户接口系统UCI完全集成在一起。UCI配置文件是/ etc/config/uhttpd
- 由于uHTTPd直接依赖这文件，因此当UCI设置提交时没有第二个配置文件需要重新生成。uHTTPd是UCI系统配置的一部分

### 配置文件内容

- uHTTPd有两个配置节定义，类型uHTTPd包含了通用的服务器设置
- cert部分：定义了加密连接SSL证书的默认值，在局域网中一般不使用，因此不再介绍
- 配置文件中必须包含文档根目录（home）和HTTP监听端口

| **名 称**           | **类型** | **含 义**                                                    |
| ------------------- | :------- | :----------------------------------------------------------- |
| **listen_http**     | 字符串   | 定义服务器的 IP 和端口。指所监听的非加密的地址和端口。如 果仅给出端口号，将同时服务于 IPv4 和 IPv6 请求。使用 0.0.0.0:80 仅绑定在 IPv4 接口，使用[::]:80 仅绑定 IPv6 |
| **home**   | 目录路径 | 定义服务器的文档根目录                                       |
| **max_requests**    | 整型数字 | 最大的并行请求数，如果大于这个值，后续的请求将进入排队队 列中 |
| **cert**            | 文件路径 | 用于 HTTPS 连接的 ASN.1/DER 证书。在提供 HTTS 连接时必须 提供 |
| **key**             | 文件路径 | 用于 HTTPS 连接的 ASN.1/DER 私钥。在提供 HTTPS 连接时必 须提供 |
| **cgi_prefix**      | 字符串   | 定义 CGI 脚本的相对于根目录的前缀。如果没有该选项，CGI 功能将不支持 |
| **script_timeout**  | 整型数字 | Lua 或 CGI 请求的最大等待时间秒值。如果没有输出产生，则超 时后执行就结束了 |
| **network_timeout** | 整型数字 | 网络活动的最大等待时间，如果指定的秒数内没有网络活动发 生，则程序终止，连接关闭 |
| **tcp_keepalive**   | 整型数字 | tcp 心跳检测时间间隔，发现对端已不存在时则关闭连接。设置 为 0 则关闭 tcp 心跳检测 |
| **realm**           | 字符串   | 基本认证的域值，默认为主机名，是当客户端进行基本认证的提 示内容 |
| **config**          | 文件路径 | 用于基本认证的配置文件                                       |

```sh
config uhttpd main
        list listen_http        0.0.0.0:80
        list listen_http        [::]:80
        list listen_https       0.0.0.0:443
        list listen_https       [::]:443
        option redirect_https   1
        option home             /www
        option rfc1918_filter 1
        option max_requests 3
        option max_connections 100
        option cert             /etc/uhttpd.crt
        option key              /etc/uhttpd.key
        option cgi_prefix       /cgi-bin
        list lua_prefix         "/cgi-bin/luci=/usr/lib/lua/luci/sgi/uhttpd.lua"
        option script_timeout   60
        option network_timeout  30
        option http_keepalive   20
        option tcp_keepalive    1
        option config   /etc/httpd.conf
config cert defaults
        option days             730
        option key_type         rsa
        option bits             2048
        option ec_curve         P-256
        option country          ZZ
        option state            Somewhere
        option location         Unknown
        option commonname       'OpenWrt'
```

