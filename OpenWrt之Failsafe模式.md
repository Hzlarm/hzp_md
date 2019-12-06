### Failsafe 模式（故障恢复模式）

安全模式作用：

只加载基本的文件系统，可以修改密码，网络配置等，可以进行升级系统，Uboot等操作；

当系统出现故障时，比如忘记密码，忘记 IP 等，就可以通过进入 Failsafe 模式来修复系统。在 failsafe 模式下，

系统会启动 Telnet 服务器，我们可以无需密码通过 Telnet 登录到路由器。在 failsafe 模式下，系统一般会关闭 

VLAN，给 eth0设置默认 IP 为 192.168.1.1（在/etc/preinit 中默认设置）。RT5350|MT7628|MT7688 例外， 有

一个 bug，需要打开 VLAN 才能使用TCP 协议。 

分析如何进入 Failsafe 模式。

```txt
ramips_set_preinit_iface（/lib/preinit/07_set_preinit_iface_ramips）
初始化网络接口，设置 switch，针对RT5350|MT7628|MT7688的设置，为了避免 Failsafe 模式 TCP 连接超时。

failsafe_wait（/lib/preinit/30_failsafe_wait）
根据内核参数/proc/cmdline 或者用户是否按下相应按键，决定是否进入 failsafe 模式（故障恢复模式）。
如果内核参数含有 FAILSAFE=true，则表示直接进入 failsafe 模式，否则调用 fs_wait_for_key 等待用户终端按键（默认为’F’+Enter），等待时间为 fs_failsafe_wait_timeout（在/etc/preinit 中设置,默认为 2s）
如果在等待时间内用户按下指定的按键，则表示要进入 failsafe 模式。接着再检测文件/tmp/failsafe_button 
是否存在，如果存在则表示要进入 failsafe 模式（该文件可通过设备上的实体按键来创建）。
如果要进入 failsafe 模式，则设置全局变量 FAILSAFE=true

run_failsafe_hook（/lib/preinit/40_run_failsafe_hook）
如果全局变量 FAILSAFE=true，则执行 failsafe 这类函数。

indicate_failsafe（/lib/preinit/10_indicate_failsafe）
设置 LED,指示进入 failsafe 模式

failsafe_netlogin（/lib/preinit/99_10_failsafe_login）
启动 Telnet 服务器（telnetd）

failsafe_shell（/lib/preinit/99_10_failsafe_login）
启动 shell
```

下面是系统启动时输出的日志：

```bash
Press the [f] key and hit [enter] to enter failsafe mode
Press the [1], [2], [3] or [4] key and hit [enter] to select the debug level
```

针对 RT5350|MT7628|MT7688，系统启动时，首先打开 VLAN，并设置 VLAN 1 的端口为 0，如下所示： 

/etc/preinit/07_set_preinit_iface_ramips

```bash
#!/bin/sh
#
# Copyright (C) 2013 OpenWrt.org
#
. /lib/ramips.sh

ramips_set_preinit_iface() {
        RT3X5X=`cat /proc/cpuinfo | egrep "(RT3.5|RT5350|MT7628|MT7688)"`
        if [ -n "${RT3X5X}" ]; then
                swconfig dev rt305x set reset 1
        fi

        if echo $RT3X5X | egrep -q "(RT5350|MT7628|MT7688)"; then
                # This is a dirty hack to get by while the switch
                # problem is investigated. When VLAN is disabled, ICMP
                # pings work as expected, but TCP connections time
                # out, so telnetting in failsafe is impossible. The
                # likely reason is TCP checksumming hardware getting
                # disabled:
                # https://www.mail-archive.com/openwrt-devel@lists.openwrt.org/msg19870.html
                swconfig dev rt305x set enable_vlan 1
                swconfig dev rt305x vlan 1 set ports "0 6"
                swconfig dev rt305x port 6 set untag 0
                swconfig dev rt305x set apply 1
                vconfig add eth0 1
                ifconfig eth0 up
                ifname=eth0.1
        else
                ifname=eth0
        fi
}

boot_hook_add preinit_main ramips_set_preinit_iface
```

这里需要将 VLAN 1 的端口修改为 0,1,2,3,4，在 Openwrt 源码树中修改，修改文件为：

`target/linux/ramips/base-files/lib/preinit/07_set_preinit_iface_ramips`
`swconfig dev rt305x vlan 1 set ports "0 1 2 3 4 6"`

然后重新编译固件，更新固件，重启系统，在日志中出现“Press the [f] key and hit [enter] to enter failsafe 

mode”这样的提示时，按下 F 和 Enter 键，就进入 failsafe 模式了。

在进入 failsafe 后，系统只挂载了只读的 SquashFS 分区，我们可以通过命令 `mount_root `来挂载 jffs2 分区 

在 failsafe 模式，我们可以修改密码。`passwd`

查看ip `uci get network.lan.ipaddr`

可以执行 ·firstboot· 命令或者删除·/overlay/*·

来恢复出厂设置。 



### 禁止failsafe

```shell
## vi package/base-files/files/etc/preinit 注释掉failsafe的初始化

boot_hook_init preinit_essential
boot_hook_init preinit_main
# boot_hook_init failsafe
boot_hook_init initramfs
boot_hook_init preinit_mount_root
```



```shell
## vi package/base-files/files/lib/preinit/30_failsafe_wait 注释掉初始化failsafe_wait

# boot_hook_add preinit_main failsafe_wait
```



```shell
### vi package/base-files/files/lib/preinit/40_run_failsafe_hook //注释掉按f加enter键的入口程序

run_failsafe_hook() {
    if [ "$FAILSAFE" = "true" ]; then
#	boot_run_hook failsafe
#	lock -w /tmp/.failsafe
	echo "run_failsafe_hook"
    fi
}

#boot_hook_add preinit_main run_failsafe_hook
```



