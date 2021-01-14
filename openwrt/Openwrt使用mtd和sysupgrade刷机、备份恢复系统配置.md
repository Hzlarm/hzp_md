# Openwrt使用mtd和sysupgrade刷机、备份恢复系统配置、修改mac地址

### 查看当前系统分区

```shell
# cat /proc/mtd 
dev:    size   erasesize  name
mtd0: 00030000 00010000 "u-boot"
mtd1: 00010000 00010000 "u-boot-env"
mtd2: 00010000 00010000 "factory"
mtd3: 00fb0000 00010000 "firmware"
mtd4: 00185df7 00010000 "kernel"
mtd5: 00e2a209 00010000 "rootfs"
mtd6: 00810000 00010000 "rootfs_data"
```

### 备份恢复openwrt系统配置

```shell
#备份自定义系统信息，包括新装软件包,读文件可以用cat 操作，但是写文件不能用cat操作
dd if=/dev/mtd6 of=/mnt/overlay.bin
#or
cat /dev/mtd0 > /mnt/overlay.bin

#恢复备份文件
mtd -r write /mnt/overlay.bin rootfs_data

#仅备份系统配置
sysupgrade -b /mnt/back.tar.gz

#恢复系统配置
sysupgrade -f /mnt/back.tar.gz
```

###  恢复Openwrt系统默认设置： 

```shell
#删除/overlay分区所有文件，重启即恢复默认设置
rm -rf /overlay/* && reboot

#使用命令恢复出厂设置，重启。firstboot  =  /sbin/jffs2reset $@
jffs2reset -y && reboot -f
#or
firstboot  reboot

#使用mtd清除/overlay分区信息后重启即恢复默认设置
mtd -r erase rootfs_data && reboot -f
```

###  刷新系统： 

```shell
#使用mtd更新系统
mtd -r write openwrt.bin firmware

#使用sysupgrade更新系统，推荐
sysupgrade openwrt.bin
```

### 修改MAC地址：

#### 查看MAC地址

```shell
#查看mac地址
cat /sys/class/ieee80211/phy0/macaddress
#or
hexdump -s 4 -n 6 -C /dev/mtd2 | head -n 1 | sed 's/\ \ /:/g' | cut -d: -f 2 | sed 's/\ /:/g'

#hexdump -s 偏移4个字节，-n 读取6个字节长度
#head -n 显示1行
#sed 's/\ \ /:/g'  将两个空格替换为一个冒号，在此为了取第二个域的mac地址
#cut -d: 自定义分隔符‘：’，默认制表符；-f 与-d一起使用，指定显示哪个区域。
#sed 's/\ /:/g'   将单空格替换为冒号进行显示
```

#### 修改Factory分区

```shell
#读取Factory分区
dd if=/dev/mtd2 of=/tmp/factory.bin
#or
cat /dev/mtd2 > /tmp/factory.bin

#修改Factory分区可写
vi target/linux/(xxx)/dts/xxx.dts
#去掉Factory分区的read-only

#修改Mac地址
...

#写回Factory分区
mtd write /tmp/factory.bin  factory
```



### openwrt的两种固件类型：factory原厂固件、sysupgrade固件

factory多了一些验证的东西，用于在原厂固件的基础上进行升级。

普通家用路由一般不是openwrt固件，如果要将家用路由升级为openwrt固件，就可以用factory刷到路由上。sysupgrade是在openwrt路由基础上升级固件，无论你是原厂固件或者本身就是openwrt固件，要升级到openwrt，factory都适用，但是sysupgrade只能用在升级，TTL救砖的时候就不能用sysupgrade。sysupgrade不包含数据分区，factory带，factory预留原厂分区，sysupgrade只包含openwrt分区。

有一个公式:sysupgrade.bin+空闲空间+系统的配置空间=factory.bin的大小

在openwrt wiki中有专门描述sysupgrade：

sysupgrade替换linux内核和squash文件系统，擦除整个jffs2部分。能保留配置文件，但不能保留二进制安装文件。