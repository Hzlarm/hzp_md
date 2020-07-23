# OpenWrt之时区设置（夏令时设置）

今天遇到一个客户关于设置时区问题。涉及到夏令时区，查阅一些资料终于搞明白了。记录如下：

因为openwrt是基于linux内核。所以记录一下Linux的时间和时区设置。

### Linux的时间和时区设置

 在linux中与时间相关的文件有

 `/etc/localtime`   : 是用来描述本机时间的。`zdump -v /etc/localtime`查看。

`/etc/timezone`  ：是 用来描述本机所属的时区，内容为`Asia/Shanghai`或者`Etc/UTC`等 
`/usr/share/zoneinfo/*`  ： 存放着不同时区格式的时间文件，执行以下命令，可以将本机时间调整至目标时区的时间格式。 

所以设置方法为(例修改为中国)：

```shell
#1、复制或者创建一个软连接都可
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#2、修改etc/timezone内容为 Asia/Shanghai
vi /etc/timezone
```

### openwrt的时区设置

 在openwrt中更改时区 在/etc/config/system文件中，对应的源码目录是： package/base-files/files/etc/config/system 。

```shell
config system
        option hostname hzlarm
        option timezone UTC-8
        option zonename Asia/Shanghai

config timeserver ntp
        list server     0.openwrt.pool.ntp.org
        list server     1.openwrt.pool.ntp.org
        list server     2.openwrt.pool.ntp.org
        list server     3.openwrt.pool.ntp.org
        option enabled 1
        option enable_server 0
```

重点内容是这两个：`option timezne UTC-8 `与  `option zonename Asia/Shanghai`。

UTC-8代表中国的东八区(明明东八区是UTC+08:00,但是这里必须设置UTC-8)。

 东八区（[UTC](https://baike.baidu.com/item/UTC)/[GMT](https://baike.baidu.com/item/GMT/6026868)+08:00）是比[世界协调时间](https://baike.baidu.com/item/世界协调时间/8036498)（UTC）/[格林尼治时间](https://baike.baidu.com/item/格林尼治时间/410004)（GMT）快8小时的时区，理论上的位置是位于[东经](https://baike.baidu.com/item/东经/8661846)112.5度至127.5度之间，是东盟标准的其中一个候选时区。当格林尼治标准时间为0:00时，东八区的标准时间为08:00。         

大部分时候只需要设置这个就可以了。但是由于UTC是时间协议不代表时区。因为有一些地方是有夏令时的，例如澳大利亚的阿特莱德，这个地方平时时间为 UTC+09:30 。但是在 夏令时期间（10月的第一个星期日– 4月的第一个星期日） 时间会变为 UTC+10:30 。这段时间就会出错。

设置zonename  为 Australia/Adelaide 即可解决。但是有一个前提。 只有当使用glibc和zoneinfo时有用！也就是类似于 一般的linux设置。必须要安装这两个包，/usr/share/zoneinfo/路径下存放世界各地的时区。

但是有些openwrt系统编译时是没有安装这两个包的。也就是说`option zonename Asia/Shanghai`不起作用。

如果没有的话可以参照[openwrt官方资料]( https://openwrt.org/start?id=zh/docs/guide-user/base-system/system_configuration )来设置。 Australia/Adelaide对应  CST-9:30CST,M10.1.0,M4.1.0/3 

`option timezone CST-9:30CST,M10.1.0,M4.1.0/3`  就可以了。[M10.1.0,M4.1.0/3解释]( https://www.di-mgt.com.au/wclock/help/wclo_tzexplain.html )



 

