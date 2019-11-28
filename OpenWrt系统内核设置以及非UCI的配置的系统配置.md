#### 系统内核设置以及非UCI的配置的系统配置

##### 系统内核设置

OpenWrt与桌面系统的Ubuntu及Fedora等一样，都采用sysctl作为系统的内核配置工具。

##### sysctl

sysctl命令，用于修改运行中的内核参数，这些参数位于/proc/sys目录下。可以用sysctl来设置或重新设置联网功能，如IP转发、IP碎片去除以及源路由检查等。

参数以key=value的形式进行设置。

-n :：查询时输出配置项的值，但不输出配置项

-e ： 当碰到不认识的配置项时，忽略错误。

-w：使用这个选项来修改系统设置。

-p：从指定的配置文件中加载配置，如果未指定则默认用/etc/sysctl.conf。

-a：显示当前所有可用的值。

例如：

`/sbin/sysctl -a`，显示所有的内核配置。

`/sbin/sysctl -n  kernel.hostname`,查询kernel.hostname的值。

`/sbin/sysctl -w kernel.hostname="xxxx"`，修改系统主机的名称为"xxxx"。

`/sbin/sysctl -p /etc/sysctl.conf`,加载配置。

内核的参数配置在启动时由sysctl工具加载，默认为/etc/sysctl.conf。启动之后均可在/proc/sys下查询，例如直接查询是否打开路由转发：`cat /proc/sys/net/ipv4/ip_forward`。

内核参数也可以通过直接修改/proc/sys/下的文件来生效。例如打开路由转发设置：

`echo "1" > /proc/sys/net/ipv4/ip_forward`

##### 非UCI的配置的系统配置

OpenWrt有一部分配置是大多linux系统都有的配置，因为用户很少修改，所以未提供UCI接口给用户修改。



`/etc/rc.local   `    // 想要在开机后就执行的命令可以写入该文件

这个文件是一个shell脚本，在系统每次启动时由`/etc/rc.d/S95done`调用。开机之后想要执行的命令写入这里。如启动时增加域名服务器地址为“8.8.8.8”：把`echo "nameserver 8.8.8.8" >> /etc/resolv.conf`写到/etc/rc.local文件中，默认内容如下。

```bash
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

exit 0
```



`/etc/profile `       // 为系统的每个登陆用户设置环境变量

当用户第一次登录时该文件被执行，首先会输出“banner”文件的内容，紧接着为登录用户设置环境变量，并创建一些常用的命令链接，如more命令链到less，即执行more命令最终会调用less命令。

```bash
#!/bin/sh
[ -f /etc/banner ] && cat /etc/banner
[ -e /tmp/.failsafe ] && cat /etc/banner.failsafe

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export HOME=$(grep -e "^${USER:-root}:" /etc/passwd | cut -d ":" -f 6)
export HOME=${HOME:-/root}
export PS1='\u@\h:\w\$ '

[ -x /bin/more ] || alias more=less
[ -x /usr/bin/vim ] && alias vi=vim || alias vim=vi

[ -z "$KSH_VERSION" -o \! -s /etc/mkshrc ] || . /etc/mkshrc

[ -x /usr/bin/arp ] || arp() { cat /proc/net/arp; }
[ -x /usr/bin/ldd ] || ldd() { LD_TRACE_LOADED_OBJECTS=1 $*; }

[ -n "$FAILSAFE" ] || {
        for FILE in /etc/profile.d/*.sh; do
                [ -e "$FILE" ] && . "$FILE"
        done
        unset FILE
}
```

其中：

* PATH：决定了shell命令的查找位置及顺序。
* HOME：登录用户主目录
* PSI：用户命令提示符。



[/etc/fstab](https://openwrt.org/zh/docs/guide-user/storage/fstab_configuration)          // 各种文件系统的描述信息

> Fstab, 或者叫 **f**ile **s**ystems **tab**le, 是一个集中的配置 。
>
>  定义了必要时（例如启动设备时，或者在物理上连接它时），文件系统（通过在块设备上）应该如何被挂载。这样，你不需要在你想要访问它们时，手动挂载设备。挂载配置不仅包括静态文件系统，也包括 swap 分区。 
>
>  Fstab UCI 子系统是所有选项被定义的地方，包括需要被挂载的全部设备和文件系统，文件位于： **/etc/config/fstab**
> 默认情况下，这个子系统和它的配置文件都不存在，因为对大多数 LEDE 用例（网络设备）来说，不需要它。
> 所以如果你需要配置这个，你首先需要创建它。 

 创建 fstab
你需要使用 *block* 工具。安装软件包 *block-mount*:
```
root@lede:~# opkg update && opkg install block-mount
```
调用 *block detect* 来得到一个 fstab UCI 子系统配置文件的范例。
```
root@lede:~# block detect > /etc/config/fstab
```
现在，有 UCI 子系统了，你可以使用 UCI 命令行来改变它，或者直接编辑文件本身。







`/etc/shells`      // openWrt采用的shell是 /bin/ash

`/etc/services  `     // 互联网网络服务类型列表
`/etc/protocols `     // 协议定义描述文件

` /etc/banner `     // 登录欢迎横幅。 

其他见:[官网介绍]( https://openwrt.org/docs/guide-user/base-system/notuci.config )














