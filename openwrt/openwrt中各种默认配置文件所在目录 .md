# openwrt中各种默认配置文件所在目录

openwrt版本为15.05.1，以mt7620为例，其他类似。

1.wifi的默认开启方式、ssid、加密方式等配置  /etc/config/wireless

```
package/kernel/mac80211/files/lib/wifi/mac80211.sh
```


2.硬件资源的配置（usb、gpio、flash等），即dts

```
target/linux/ramips/dts/  下文件
```

3.镜像生成方式控制

```
target/linux/ramips/image/Makefile
```

4.board检测配置脚本（对升级有影响）!!!

```
target/linux/ramips/base-files/lib/ramips.sh
匹配/proc/cpuinfo中字段设置board名字`
```

5.升级镜像检查脚本

```
target/linux/ramips/base-files/lib/upgrade/platform.sh
target/linux/ramips/xxx/base-files/lib/upgrade/platform.sh
根据board名字来检测镜像中magic是否匹配`
```


6.status_led设置

```
target/linux/ramips/base-files/etc/diag.sh
package/base-files/files/etc/diag.sh
根据board名字设置status_led为在dts中定义的gpio
```

7.usb_led、wifi_led设置

```
target/linux/ramips/xxx/base-files/etc/board.d/01_leds
根据board名字设置led为在dts中定义的gpio
```

7.以太网网络配置（lan/wan配置）

```
target/linux/ramips/xxx/base-files/etc/board.d/02_network
设置switch的port vlan，及lan、wan端口的配置，lan、wan的mac地址配置
```

8.uboot-evntools 分区设置

```
package/boot/uboot-envtools/files/ramips
```

9 /etc/config/system  /etc/config/network

- 默认hostname   br-lan

```shell
package/base-files/files/bin/config_generate
```

