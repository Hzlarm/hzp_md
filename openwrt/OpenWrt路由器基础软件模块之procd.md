## OpenWrt 基础软件模块之procd

> Openwrt 支持模块化编程，增加新功能非常简单。但是一些通用的基础模块必须包含,他们是OpenWrt核心。
> 如：实用基础库libubox、系统总线ubus、网络接口管理模块netifd、核心工具模块ubox、服务管理模块procd。



### 服务管理模块procd

>  通常的嵌入式系统均有一个守护进程，该守护进程监控系统进程的状态，如果某些系统进程异常退出，将再次启动这些进程。procd 就是这样一个进程，它是使用C语言编写 的，一个新的OpenWrt进程管理服务。
>
>   它通过init脚本来将进程信息**加入到procd的数据库**中来管理进程启动，这是**通过ubus总线调用**来实现，可以防止进程的重复启动调用 

procd的进程管理功能主要包含3个部分：

-  **reload_config：** 检查配置文件是否发生变化，如果有变化则通知procd进程 
-  **procd守护进程：**  接收使用者的请求，增加或删除所管理的进程，并监控进程的状态，如果发现进程退出，则再次启动进程 
-  **procd.sh：** 提供函数封装procd提供系统总线方法，调用者可以非常便利的使用procd提供的方法 

代码：[https://git.openwrt.org/?p=project/procd.git;a=tree](https://git.openwrt.org/?p=project/procd.git;a=tree)

#### reload_config

> **工作原理：**当在命令行执行reload_config时，会对系统中的**所有配置文件生成MD5值**，并且和应用程序使用的配置文件MD5值**进行比较（对/var/run/config.md5文件进行比较）**，如果不同就**通过ubus总线通知procd配置文件**发生改变，如果应用程序在启动时，向procd注册了配置触发服务，那就将调用 reload函数**重新读取配置文件**，通常是进程退出再启动。如果配置文件没有改变将不会调用，这将节省系统CPU资源 

**两点注意事项**

- 配置文件的真实配置内容发生改变之后才会调用，如果 **增加空行和注释并不会引起** 配置文件的实质内容改变
- 当**系统启动时** ，会执行reload_config将 **初始配置文件摘要值** 保存为**/var/run/config.md5** 文件中，下次再执行reload_config就是与这文件里面的MD5值进行比较的

> ### 工作原理详解：
>
> 我们以防火墙的配置文件发生改变为例来说明
>
> - ①当手动执行reload_config时，首先将目录/etc/config目录下的所有文件通过“uci show”命令输出其配置到“/var/run/config.check” 目录下，这个命令将过滤配置文件增加空行和注释的情况
> - ②初始系统启动时的配置文件摘要值保存在文件/var/run/config.md5 中，我们通过 “md5sum –c”命令来从文件中读取MD5值并验证是否和现有的配置文件MD5是否一致， 如果不一致则就调用ubus方法通知procd进程配置文件发生改变
> - ③当procd知道配置文件发生改变后，procd就会**调用/etc/init.d/firewall reload**来处理配置文件改变，其他配置文件没有改变的进程，系统将不会花费资源进行处理
> - ④最后将现在运行中的配置文件MD5值**保存到/var/run/config.md5**中



#### procd进程

 procd进程向ubus总线注册了 **service和system对象** .`ubus list`命令可以才看到。

##### service对象

>serveis对象提供的方法，主要有3部分功能： **进程的管理、文件触发器（trigger）、配置验证服务（validate）**
>
> | **方 法**    | **含 义**                                                    |
>| ------------ | ------------------------------------------------------------ |
>| **set**      | 进程如果存在，则修改已经注册的进程信息，如果不存在则增加，最后启动注册的进程 |
>| **add**      | 增加注册的进程                                               |
>| **list**     | 如果不带参数，则列出所有注册的进程和其信息                   |
>| **delete**   | 删除指定服务进程，在结束进程时调用，例如停止防火墙会进行以下调用: ubus call service delete ‘{“name”:”firewall”}’ |
>| **event**    | 发出事件，例如 reload_config 就使用该方法来通知配置发生改变  |
>| **validate** | 查看所有的验证服务                                           |
>
>- **set方法：**
>
> - 上面的3个功能都是通过set方法增加到procd保存的内存数据库中。数据库以服务名称作为其主键
> - 共有5个参数：第一个参数为被管理的服务进程名称；第二个参数为启动脚本绝对路径；第三个参数为进程实例信息，例如可执行程序路径和进程的启动参数等；第四个参数为触发器；第五个参数为配置验证项（前3个参数是必须要传递的，后面两个参数可选。）
> 
> - **delete方法：**
>
> - 在删除时使用 delete 方法
> - 共有两个参数：第一个参数为服务名称，第二个参数为进程实例名称，可以不指定实例名称
> 
> - **list方法：**
>
> - 查询时使用 list 方法
> - 共有两个参数：第一个参数为服务名称，第二个参数是布尔值，表示是否输出其详细信息，默认为不输出详细信息（该方法可以不带任何参数，表示查询所有注册的服务信息）
> 
> ```shell
>ubus -v list service
>  
>  'service' @7e08a163
>       "set":{"name":"String","script":"String","instances":"Table","triggers":"Array","validate":"Array","autostart":"Boolean","data":"Table"}
>       "add":{"name":"String","script":"String","instances":"Table","triggers":"Array","validate":"Array","autostart":"Boolean","data":"Table"}
>          "list":{"name":"String","verbose":"Boolean"}
>          "delete":{"name":"String","instance":"String"}
>          "signal":{"name":"String","instance":"String","signal":"Integer"}
>          "update_start":{"name":"String"}
>          "update_complete":{"name":"String"}
>          "event":{"type":"String","data":"Table"}
>          "validate":{"package":"String","type":"String","service":"String"}
>          "get_data":{"name":"String","instance":"String","type":"String"}
>          "state":{"spawn":"Boolean","name":"String"}
>     ```

例如：

- **①增加进程：** 如果hello进程需要procd来管理，那么我们使用ubus命令将hello进程加入的procd的内存数据库中。下面命令传递了4个参数，第一个参数设置被管理的服务进程名称为“hello”。第二个参数设置启动脚本绝对路径“/etc/init.d/hello”。第三个参数设置了进程实例信息，实例的启动命令为“/bin/hello”，启动参数为“-f -c bjbook.net”，并设置进程意外退出的重生参数（respawn）为默认值。第四个参数为触发器，收到文件“hello” 的“config.change”消息后执行脚本“/ect/init.d/hello”并传递“reload”参数

```shell
ubus call service add '{"name":"hello", "script":"/etc/init.d/hello","instances":{"instance1":{ "command":["/bin/hello","-f","-c","bjbook.net"],"respawn":[ ] }},"triggers": [ ["config.change",["if", ["eq","package", "hello" ], ["run_script","/ect/init.d/hello", "reload" ] ] ] ]}'
```

- **②删除进程：** 参数传递进程的名字即可

```shell
ubus call service delete '{"name":"hello"}'
```

- **③查看注册的进程信息：** 也可以不指定名称，将输出所有的管理列表。“verbose”为真，表示输出其详细信息

```
ubus call service list '{"name":"hello","verbose":true}'
```

- **④发送事件：** 第一个参数含义为事件类型，现在只支持“config.change”事件消息； 第二个参数表示文件“hello”，是指在目录“/etc/config”下的文件。在配置文件发生改变 时调用。通知 procd 进程配置文件 hello 发生了改变

```shell
ubus call service event '{"type":"config.change","data":{"package":"hello"}}'
```

##### system对象

| **方 法**       | **含 义**                                                    |
| --------------- | ------------------------------------------------------------ |
| **board**       | 系统软硬件版本信息，包含 4 个部分，分别为内核版本、主机名称、系统 CPU 类 型信息和版本信息,版本信息从/etc/openwrt_release 文件读出 |
| **info**        | 当前系统信息，包含 5 部分，分别为系统启动时间、系统当前时间、系统负载情况、 内存和交换分区占用情况等 |
| **upgrade**     | 设置 service_update 为 1                                     |
| **watchdog**    | 设置 watchdog 信息，还存在问题，例如如果本身为 0 的情况      |
| **signal**      | 向指定 pid 的进程发信号，是通过 kill 函数来实现的            |
| **nandupgrade** | 执行升级                                                     |


#### procd.sh

> * 使用ubus方法来进行管理时其**传递参数复杂并且容易出错**，procd.sh将这些参数拼接组织功能**封装为函数**，每一个需要被procd管理的进程都使用它提供的函数进行注册 。
> * 这些函数**组织为JSON格式** 的消息然后通过ubus总线向procd进程发送消息。这些函数将不同功能封装为不同的函数，构建特定的JSON消息来表达特定的功能用法
> * **函数命名规范：** procd.sh提供的API命名非常规范，除了有一个**uci_validate_section函数** 用于验证UCI 配置文件以外，其他所有的函数均是**以“procd_”开头**



**procd_open_ trigger** 函数创建一个触发器数组，在增加了所有的触发器之后，调用**procd_close_trigger函数** 来结束触发器数组的增加

**procd_add_reload_trigger**：增加配置文件触发器，每次配置文件的修改，如果调用了reload_config时，当前实例都被重启。有一个可选的参数为配置文件名称。其实它在内部是调用 procd_open_trigger、procd_add_config_trigger 和 procd_close_trigger 这3个函数来增加触发器



**procd_open_instance：** 开始增加一个服务实例 

 **procd_set_param：** 设置服务实例的参数值。通常会有以下几种类型的参数：（每次只能使用一种类型参数，其后是这个类型参数的值） 

- command：服务的启动命令行
- respawn：进程意外退出的重启机制及策略，它需要有 3 个设置值。第一个设置为 判断异常失败边界值（threshold），默认为 3600 秒，如果小于这个时间退出，则 会累加重新启动次数，如果大于这个临界值，则将重启次数置 0。第二个设置为 重启延迟时间（timeout），将在多少秒后启动进程，默认为 5 秒。第三个设置是总 的失败重启次数（retry），是进程永久退出之前的重新启动次数，超过这个次数进 程退出之后将不会再启动。默认为 5 次。也可以不带任何设置，那这些设置都是 默认值
- env：进程的环境变量
- file：配置文件名，比较其文件内容是否改变
- netdev：绑定的网络设备（探测 ifindex 更改）
- limits：进程资源限制

 **procd_close_instance：**完成进程实例的增加 

例如 rpcd对procd函数的使用，这个示例可以用于大多数应用程序。PROG变量在前面已设置为/bin/rpcd。该示例将最终调用以下命令完成进程的增加 :

```shell
ubus call service set '{"name":"rpcd", "script":"/etc/init.d/rpcd",
"instances": {"instance1":{ "command": ["/bin/rpcd"] } } }'
```

```shell
procd_open_instance
procd_set_param command "$PROG"
procd_close_instance
```



**procd_open_validate：** 打开一个验证数组，是和 procd_close_validate 函数一起使用
**procd_close_validate：** 关闭一个验证数组。

**演示案例：**

下面是软件包firewall使用 procd 来对防火墙配置的触发器和验证

```shell
procd_add_reload_trigger firewall
 
procd_open_validate
validate_firewall_redirect
validate_firewall_rule
procd_close_validate
```

**procd_open_service(name, [script])：** 至少需要一个参数，第一个参数是实例名称， 第二个参数是可选参数为启动脚本。该函数仅在在 rc.common 中调用，用于创建一个新的 procd 进程服务消息
**procd_close_service：** 该函数不需要参数，仅在 rc.common 中调用，完成进程管理服务的增加

**procd_kill：** 杀掉服务实例（或所有的服务实例）。至少需要一个参数，第一个参 数是服务名称，通常为进程名，第二个是可选参数，是进程实例名称，因为可能有多个进 程示例，如果不指定所有的实例将被关闭。该函数在 rc.common 中调用，用户从命令行调 用 stop 函数时会使用该函数杀掉进程

**uci_validate_section：** 调用 validate_data 命令注册为验证服务。在配置发生改变 后对配置文件的配置项合法性进行校验。验证服务是在进程启动时通过 ubus 总线注册到 procd 进程中

```shell
#输入以下命令，可以看到系统所有注册的验证服务
ubus call service validate

{
        "firewall": {
                "redirect": {
                        "dest": "string",
                        "dest_ip": "cidr",
                        "dest_port": "or(port, portrange)",
                        "proto": "or(uinteger, string)",
                        "src": "string",
                        "src_dport": "or(port, portrange)",
                        "src_ip": "cidr",
                        "target": "or(SNAT, DNAT)"
                },
                "rule": {
                        "dest": "string",
                        "dest_port": "or(port, portrange)",
                        "proto": "or(uinteger, string)",
                        "src": "string",
                        "src_port": "or(port, portrange)",
                        "target": "string"
                }
        },
...............
```

- 这些验证服务是在启动脚本中增加验证服务来实现，如下代码所示，service_triggers 函数是预定义好的回调函数，在每一个增加服务结束后会自动调用，使用者不必关注如何 调用。validate_cron_section 函数是真正的将验证服务加入 procd 的验证服务中。它调用 uci_validate_section 函数，而 uci_validate_section 函数进一步调用 validate_data 程序

```shell
validate_cron_section() {
    uci_validate_section system system "${1}" \
    'cronloglevel:uinteger'
}
 
service_triggers()
{
    procd_add_validation validate_cron_section
    procd_add_reload_trigger "hello"
}
```

#### rc.common

> rc.common在1209及之前的版本中并不支持procd启动，在1407版本中增加了专门针对procd的启动，该脚本向前兼容 
>
> 在软件模块的启动脚本中**如果没有定义USE_PROCD变量**：则启动流程和之前**完全相同**
>
> 如果**定义了 USE_PROCD变量**：对start、stop 和 reload函数进行重新定义，在调用这些函数时，将调用start_service、stop_service和 reload_service函数等

- **procd预定义的函数如下：**

  如果在自己的启动脚本中定义了USE_PROCD那就调用这些函数。在rc.common中重新定义了start函数，相当于重载了这些函数

| **函 数**            | **含 义**                                                    |
| -------------------- | ------------------------------------------------------------ |
| **start_service**    | 向 procd 注册并启动服务，是将在 services 所管理对象里面增加了一项 |
| **stop_service**     | 让 procd 解除注册，并关闭服务, 是将在 services 中的管理对象删除 |
| **service_triggers** | 配置文件或网络接口改变之后触发服务重新读取配置               |
| **service_running**  | 查询服务的状态                                               |
| **reload_service**   | 重启服务，如果定义了该函数，在 reload 时将调用该函数，否则再次调用 start 函数 |
| **service_started**  | 用于判断进程是否启动成功                                     |

#### 编写一个procd启动脚本（注意与[init脚本](https://blog.csdn.net/hzlarm/article/details/103028193)不一样）

[官方参考以及与init区别](https://oldwiki.archive.openwrt.org/inbox/procd-init-scripts)

```bash
#!/bin/sh /etc/rc.common  
#使用/etc/rc.common来解释脚本
 
USE_PROCD=1		#表示使用procd来管理进程
START=15
STOP=85
PROG=/bin/hello	#PROG变量用来给程序的启动脚本赋值，用于启动应用程序

#validate_hello_section函数：验证了配置文件hello中的delay变量否为整型值，并且在合理的（1～200）范围内
validate_hello_section()
{
	uci_validate_section hello system globe \
	'delay:uinteger(1:200)' 
}

#start_service函数：负责程序的启动
start_service() {
	echo "start HelloRoute!"
	validate_hello_section || {
	echo "hello validattion failed!"
	return 1
	}
 
 #在参数验证完成后，调用procd_open_instance 数发起实例增加，接着调用了procd_set_param函数来设置了启动命令和启动参数，再接着respawn设置其进程意外退出的重启机制及策略为默认值，最后调用procd_close_instance函数完成实例的增加。注意procd管理的进程需要运行在前台，即不能调用daemon或类似函数
	procd_open_instance
	procd_set_param command "$PROG" –f -w bjbook.net
	procd_set_param respawn
	procd_close_instance
}

#service_triggers函数：增加触发器，我们增加了对配置文件hello的触发服务。当hello文件发生改变后，如果调用了 reload_config命令，将触发调用reload_service函数
service_triggers()
{
	procd_add_reload_trigger "hello"
}

#reload_service函数：在传递reload参数时进行调用，如果没有该函数，将会调用默认start函数
reload_service()
{
	stop
	start
}
```

 **备注：** 在执行该启动脚本时，如果需要对procd脚本进行调试，可以设置PROCD_DEBUG变量为 1，这样可以输出向ubus总线调用的参数信息。例如： `PROCD_DEBUG=1 /etc/init.d/hello start`

















