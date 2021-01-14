## Openwrt常用软件模块之SSH(Dropbear)

> SSH（Secure Shell）是专为远程登录会话和其他网络服务提供安全性的协议。OpenWrt 默认**采用Dropbear软件**来实现 SSH协议。它是一个在小内存环境下非常高效的SSH服务器和客户端 

### Dropbear概述

- Dropbear 是一个开源软件包，是由马特·约翰逊撰写，并且和安全shell兼容的服务 器和客户端。它是在**低内存和处理器资源**情况下对标准的 OpenSSH 的一个替代品，适合 嵌入式操作系统。它是 OpenWrt 的一个核心组件
- Dropbear实现了SSH 协议V2版本。SSH协议是一种在不安全的网络环境中，**通过加密和认证机制**，实现安全的远程访问以及文件传输等业务的网络安全协议。它使用了第三方的加密算法，但嵌入到Dropbear代码中，终端的部分代码继承自OpenSSH软件
- Dropbear在客户端和服务器都实现了完整的SSH 协议 V2版。它**不支持SSH版本V1的向后兼容性**，以节省空间和资源，并**避免了在 SSH 版本V1中固有的安全漏洞**
- Dropbear还提供**安全远程复制功能**，可以在网络上的主机之间进行远程文件复制。它利用 SSH 协议来传输数据，和SSH登录采用同样的认证和安全，当需要认证时提示输入密码。文件名包含一个用户和主机地址，以表明该文件复制的源地址和目标地址。本地文件名可以明确使用绝对或相对路径名来避免处理文件名含有主机说明符。远程主机之间的复制也是可以的。将目标路由器的配置文件复制下来的命令示例如下：

`scp root@192.168.6.1:/etc/config/dropbear /tmp/dropbear`

### 配置文件

- 配置文件为/etc/config/dropbear，所有的配置在唯一一个配置节dropbear中
- **下表列出了 SSH 服务器的主要配置选项：**

| **名 称**            | **类 型** | **含 义**                                |
| -------------------- | --------- | ---------------------------------------- |
| **PasswordAuth**     | 布尔值    | 设置为0关闭密码认证。默认为 1            |
| **RootPasswordAuth** | 布尔值    | 设置为0关闭root用户的密码认证。默认为1   |
| **Port**             | 数字      | 监听的端口号，默认为 22                  |
| **BannerFile**       | 字符串    | 用户认证成功后登录进去的输出内容的文件名 |
| **enable**           | 布尔值    | 是否随系统启动该进程，默认为 1           |
| **Interface**        | 字符串    | 指定监听的网卡接口，即只从该接口接收请求 |

- 下面所示的是dropbear的默认配置：打开了密码认证功能，并且允许管理员用户登录，设置在 TCP 端口号 22 处监听

```sh
#cat /etc/config/dropbear
config dropbear
        option PasswordAuth 'on'
        option RootPasswordAuth 'on'
        option Port         '22'
#       option BannerFile   '/etc/banner'
```

