

# openwrt中LED的控制



### 上手总结

> #### 配置方法一 简单操作
>
> 直接进入`/sys/class/leds`目录下面。以`<路由器名字>:颜色:<功能>`格式命名的目录均对应一个LED。
>
> 进入要操作的目录，重点是 `trigger`(触发方式) 、`brightness` （开关）、`delay_off`(熄灯时间)、`delay_on`(亮灯时间)
>
> ```shell
> #ls
> brightness      delay_on        max_brightness  trigger
> delay_off       device          subsystem       uevent
> ```
>
> 对文件brightness写入0/1，关闭/打开LED灯。如 ：` echo  0 > brightness`.
>
> 设置闪烁：
>
> ```
> echo timer > trigger
> echo 1000  > delay_on
> echo 1000  > delay_off
> ```
>
> #### 配置方法二
>
> 修改配置文件`/etc/config/system`
>
> 往下细看



关闭路由器所有led脚本：

```sh
#!/bin/ash
for i in `ls /sys/class/leds` 
do cd /sys/class/leds 
cd $i 
echo 0 > brightness
done
```

### 配置文件

#### `/etc/config/system`

```sh
#......
config led 'led_internet'
        option name 'internet'
        option sysfs 'newifi-d2:amber:internet'
        option trigger 'switch0'
        option port_mask '0x10'

config led 'led_wlan2g'
        option name 'WiFi 2.4GHz'
        option sysfs 'newifi-d2:blue:wlan2g'
        option trigger 'netdev'
        option mode 'link tx rx'
        option dev 'ra0'

config led 'led_wlan5g'
        option name 'WiFi 5GHz'
        option sysfs 'newifi-d2:blue:wlan5g'
        option trigger 'netdev'
        option mode 'link tx rx'
        option dev 'rai0'

```

#### 添加配置

所有可以被控制的LED灯均在`/sys/class/leds`目录下。例如：

```sh
ls /sys/class/leds/
newifi-d2:amber:internet  newifi-d2:blue:power      newifi-d2:blue:wlan5g
newifi-d2:amber:power     newifi-d2:blue:usb
newifi-d2:blue:internet   newifi-d2:blue:wlan2g
```

LED受系统中的各种事件控制，由对应的`trigger`指定。：

```shell
# cat /sys/class/leds/newifi-d2:blue:usb/trigger
[none] switch0 timer default-on netdev usbport phy0rx phy0tx phy0assoc phy0radio phy0tpt phy1rx phy1tx phy1assoc phy1radio phy1tpt
# echo "default-on" > /sys/class/leds/newifi-d2:blue:usb/trigger
# cat /sys/class/leds/newifi-d2:blue:usb/trigger
none switch0 timer [default-on] netdev usbport phy0rx phy0tx phy0assoc phy0radio phy0tpt phy1rx phy1tx phy1assoc phy1radio phy1tpt 
```

执行以上命令，可以打开对应的LED灯，重启系统会失效。需要永久生效则写入`/etc/config/system`。

例如：

```sh
#查看
#uci show system | grep 'system.led'
system.led_usb=led
system.led_usb.name='USB'
system.led_usb.sysfs='newifi-d2:blue:usb'
system.led_usb.trigger='usbport'
system.led_usb.interval='50'
system.led_usb.dev='1-1'

#修改
uci set system.led_sub.trigger='default-on'
uci commit

#或者

uci batch <<EOF 
set system.led_usb=led
set system.led_usb.name='USB'
set system.led_usb.sysfs='newifi-d2:blue:usb'
set system.led_usb.trigger='default-on'
EOF
uci commit

#重启 生效
service led restart
```

### Led triggers

* **`none`** :  LED始终处于默认状态。未列出的LED默认为OFF，因此仅在声明LED始终为ON时有用。 

| Name      | Type    | Required | Default  | Description                                              |
| :-------- | :------ | :------- | :------- | :------------------------------------------------------- |
| *default* | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON |
| *sysfs*   | string  | yes      | *(none)* | LED device name                                          |
| *trigger* | string  | yes      | *(none)* | *none*                                                   |

* **`switch0`** : 如果已在已配置的交换机端口之一上建立链接，则该指示灯点亮。 

| Name         | Type    | Required | Default  | Description                                                 |
| :----------- | :------ | :------- | :------- | :---------------------------------------------------------- |
| *default*    | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON    |
| *sysfs*      | string  | yes      | *(none)* | LED device name                                             |
| *port_mask*  | integer | no       | 0        | Hexadecimal bit mask that encodes the regarded switch ports |
| *speed_mask* | ?       | ?        | *(none)* | Example value: '0xf'                                        |
| *trigger*    | string  | yes      | *(none)* | *switch0*                                                   |
*  **`Timer`** :   配置LED的开/关频率闪烁。 

```sh
#安装命令
opkg install kmod-ledtrig-timer
```

| Name     | Type    | Required | Default  | Description                                              |
| :------- | :------ | :------- | :------- | :------------------------------------------------------- |
| default  | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON |
| delayoff | integer | yes      | *(none)* | How long (in milliseconds) the LED should be off.        |
| delayon  | integer | yes      | *(none)* | How long (in milliseconds) the LED should be on.         |
| sysfs    | string  | yes      | *(none)* | LED device name                                          |
| trigger  | string  | yes      | *(none)* | *timer*                                                  |

* **`default-on`** :  LED灯常亮，已经被弃用，使用`default=1 trigger=none`

```sh
#安装命令
opkg install kmod-ledtrig-default-on 
```

| Name      | Type    | Required | Default  | Description                                              |
| :-------- | :------ | :------- | :------- | :------------------------------------------------------- |
| *default* | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON |
| *sysfs*   | string  | yes      | *(none)* | LED device name                                          |
| *trigger* | string  | yes      | *(none)* | *default-on*                                             |

* **`heartbeat`** :  LED闪烁以模拟实际的心跳<频率与1分钟平均CPU负载成正比。

```shell
#安装
opkg install kmod-ledtrig-heartbeat
```

| Name      | Type    | Required | Default  | Description                                              |
| :-------- | :------ | :------- | :------- | :------------------------------------------------------- |
| *default* | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON |
| *sysfs*   | string  | yes      | *(none)* | LED device name                                          |
| *trigger* | string  | yes      | *(none)* | *heartbeat*                                              |



* **` nand-disk `** :   当数据写入闪存时，LED闪烁。 

| Name      | Type    | Required | Default  | Description                                              |
| :-------- | :------ | :------- | :------- | :------------------------------------------------------- |
| *default* | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON |
| *sysfs*   | string  | yes      | *(none)* | LED device name                                          |
| *trigger* | string  | yes      | *(none)* | *nand-disk*                                              |

* **` netdev `** :  LED闪烁并显示链接状态和/或已配置接口上的发送和接收活动。 

```shell
#安装
opkg install kmod-ledtrig-netdev
```

| Name      | Type    | Required | Default  | Description                                                  |
| :-------- | :------ | :------- | :------- | :----------------------------------------------------------- |
| default   | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON     |
| *dev*     | string  | yes      | *(none)* | Name of the network interface which status should be reflected |
| *mode*    | string  | yes      | *(none)* | One or more of *link*, *tx*, or *rx*, seperated by spaces    |
| *sysfs*   | string  | yes      | *(none)* | LED device name                                              |
| *trigger* | string  | yes      | *(none)* | *netdev*                                                     |
| interval  | ?       | ?        | *(none)* | Example value: '50'                                          |

* **`WiFi Activity triggers`** :  当在物理接口而不是软件网络接口中触发的事件上，LED闪烁。除了*phy*触发器具有更多事件之外，如果您想分别监视2.4 GHz无线电（通常为*phy0*）和5 GHz无线电（通常为*phy1*），它还提供了静态LED设置的可能性。*netdev*无法保证这种区分，因为根据当前的网络设置，*wlan0*可能是指2.4 GHz或5 GHz无线电。 

| Name      | Type    | Required | Default  | Description                                               |
| :-------- | :------ | :------- | :------- | :-------------------------------------------------------- |
| *default* | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON  |
| *sysfs*   | string  | yes      | *(none)* | LED device name                                           |
| *trigger* | string  | yes      | *(none)* | *phy0rx*, *phy0tx*, *phy0assoc*, *phy0radio* or *phy0tpt* |

  >    **phy0rx-**接收时闪烁。
  **phy0tx-**传输时闪烁。
  **phy0assoc-**在客户端关联上闪烁。
  **phy0radio-**（未知，此选项对我的tl-wr1043nd无效）
  **phy0tpt-**网络活动缓慢且稳定地闪烁。与tx和rx模式的充满活力的闪烁相比

* **` usbdev / usbport`** :  如果连接了USB设备，则LED点亮。 

```shell
#安装
opkg install kmod-ledtrig-usbdev 
```

| Name       | Type    | Required | Default  | Description                                              |
| :--------- | :------ | :------- | :------- | :------------------------------------------------------- |
| *default*  | integer | no       | 0        | LED state before trigger: *0* means OFF and *1* means ON |
| *dev*      | string  | yes      | *(none)* | Name of USB device to monitor.                           |
| *interval* | integer | yes      | *(none)* | Interval in ms when device is active.                    |
| *sysfs*    | string  | yes      | *(none)* | LED device name                                          |
| *trigger*  | string  | yes      | *(none)* | usbdev – **This may be `usbport` (March 2019)**          |

*  **`gpio`** : 允许通过gpio事件控制LED。 

```shell
#安装
 opkg install kmod-ledtrig-gpio
```

| Name      | Type    | Required | Default | Description                                              |
| :-------- | :------ | :------- | :------ | :------------------------------------------------------- |
| *default* | integer | no       | 0       | LED state before trigger: *0* means OFF and *1* means ON |

*  **` Net filter`** :  当特定数据包通过您的计算机时，指示灯会闪烁。 

```shell
#安装
opkg install kmod-ipt-led

#示例：当ssh连接通信时触发
iptables -A INPUT -p tcp --dport 22 -j LED --led-trigger-id ssh --led-delay 1000
#然后将新触发器连接到系统上的LED
echo netfilter-ssh > /sys/class/leds/<ledname>/trigger 
```

| Name      | Type    | Required | Default | Description                                              |
| :-------- | :------ | :------- | :------ | :------------------------------------------------------- |
| *default* | integer | no       | 0       | LED state before trigger: *0* means OFF and *1* means ON |

### 示例

#### Heartbeat led

```shell
config 'led'
	option 'sysfs'		'wrt160nl:amber:wps'
	option 'trigger'	'heartbeat'
```

#### WLAN led

```shell
config 'led' 'wlan_led'
	option 'name'           'WLAN'
	option 'sysfs'          'tl-wr1043nd:green:wlan'
	option 'trigger'        'netdev'
	option 'dev'            'wlan0'
	option 'mode'           'link tx rx'
```

#### 3G led

当USB正确注册到3G / EDGE / GPRS网络时，此指示灯点亮。
```shell
config 'led'
	option 'name'           '3G'
	option 'sysfs'          'asus:blue:3g'
	option 'trigger'        'netdev'
	option 'dev'            '3g-wan'
	option 'mode'           'link'
```

#### Timer led - 500ms ON, 2000ms OFF

```shell
config 'led'
	option 'sysfs'		'wrt160nl:blue:wps'
	option 'trigger'	'timer'
	option 'delayon'	'500'
	option 'delayoff'	'2000'
```

### led服务脚本

 `/etc/init.d/led` 

```sh
#!/bin/sh /etc/rc.common
# Copyright (C) 2008 OpenWrt.org

START=96

load_led() {
        local name
        local sysfs
        local trigger
        local dev
        local ports
        local mode
        local default
        local delayon
        local delayoff
        local interval

        config_get sysfs $1 sysfs
        config_get name $1 name "$sysfs"
        config_get trigger $1 trigger "none"
        config_get dev $1 dev
        config_get ports $1 port
        config_get mode $1 mode
        config_get_bool default $1 default "nil"
        config_get delayon $1 delayon
        config_get delayoff $1 delayoff
        config_get interval $1 interval "50"
        config_get port_state $1 port_state
        config_get delay $1 delay "150"
        config_get message $1 message ""
        config_get gpio $1 gpio "0"
        config_get inverted $1 inverted "0"

        if [ "$trigger" = "rssi" ]; then
                # handled by rssileds userspace process
                return
        fi

        [ "$trigger" = "usbdev" ] && {
                # Backward compatibility: translate to the new trigger
                trigger="usbport"
                # Translate port of root hub, e.g. 4-1 -> usb4-port1
                ports=$(echo "$dev" | sed -n 's/^\([0-9]*\)-\([0-9]*\)$/usb\1-port\2/p')
                # Translate port of extra hub, e.g. 2-2.4 -> 2-2-port4
                [ -z "$ports" ] && ports=$(echo "$dev" | sed -n 's/\./-port/p')
        }

        [ -e /sys/class/leds/${sysfs}/brightness ] && {
                echo "setting up led ${name}"

                printf "%s %s %d\n" \
                        "$sysfs" \
                        "$(sed -ne 's/^.*\[\(.*\)\].*$/\1/p' /sys/class/leds/${sysfs}/trigger)" \
                        "$(cat /sys/class/leds/${sysfs}/brightness)" \
                                >> /var/run/led.state

                [ "$default" = 0 ] &&
                        echo 0 >/sys/class/leds/${sysfs}/brightness

                echo $trigger > /sys/class/leds/${sysfs}/trigger 2> /dev/null
                ret="$?"

                [ $default = 1 ] &&
                        cat /sys/class/leds/${sysfs}/max_brightness > /sys/class/leds/${sysfs}/brightness

                [ $ret = 0 ] || {
                        echo >&2 "Skipping trigger '$trigger' for led '$name' due to missing kernel module"
                        return 1
                }
                case "$trigger" in
                "netdev")
                        [ -n "$dev" ] && {
                                echo $dev > /sys/class/leds/${sysfs}/device_name
                                for m in $mode; do
                                        [ -e "/sys/class/leds/${sysfs}/$m" ] && \
                                                echo 1 > /sys/class/leds/${sysfs}/$m
                                done
                                echo $interval > /sys/class/leds/${sysfs}/interval
                        }
                        ;;

                "timer"|"oneshot")
                        [ -n "$delayon" ] && \
                                echo $delayon > /sys/class/leds/${sysfs}/delay_on
                        [ -n "$delayoff" ] && \
                                echo $delayoff > /sys/class/leds/${sysfs}/delay_off
                        ;;

                "usbport")
                        local p

                        for p in $ports; do
                                echo 1 > /sys/class/leds/${sysfs}/ports/$p
                        done
                        ;;

                "port_state")
                        [ -n "$port_state" ] && \
                                echo $port_state > /sys/class/leds/${sysfs}/port_state
                        ;;

                "gpio")
                        echo $gpio > /sys/class/leds/${sysfs}/gpio
                        echo $inverted > /sys/class/leds/${sysfs}/inverted
                        ;;

                switch[0-9]*)
                        local port_mask speed_mask

                        config_get port_mask $1 port_mask
                        [ -n "$port_mask" ] && \
                                echo $port_mask > /sys/class/leds/${sysfs}/port_mask
                        config_get speed_mask $1 speed_mask
                        [ -n "$speed_mask" ] && \
                                echo $speed_mask > /sys/class/leds/${sysfs}/speed_mask
                        [ -n "$mode" ] && \
                                echo "$mode" > /sys/class/leds/${sysfs}/mode
                        ;;
                esac
        }
}

start() {
        [ -e /sys/class/leds/ ] && {
                [ -s /var/run/led.state ] && {
                        local led trigger brightness
                        while read led trigger brightness; do
                                [ -e "/sys/class/leds/$led/trigger" ] && \
                                        echo "$trigger" > "/sys/class/leds/$led/trigger"

                                [ -e "/sys/class/leds/$led/brightness" ] && \
                                        echo "$brightness" > "/sys/class/leds/$led/brightness"
                        done < /var/run/led.state
                        rm /var/run/led.state
                }

                config_load system
                config_foreach load_led led
        }
}
```

