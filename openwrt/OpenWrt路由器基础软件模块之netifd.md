## OpenWrt 基础软件模块之netifd

> Openwrt 支持模块化编程，增加新功能非常简单。但是一些通用的基础模块必须包含,他们是OpenWrt核心。
> 如：实用基础库libubox、系统总线ubus、网络接口管理模块netifd、核心工具模块ubox、服务管理模块procd。



### 网络接口管理模块netifd

> netifd（network interface daemon）是一个管理网络接口和路由功能的后台进程，是一 个使用 C 语言编写的带有 RPC 能力的精灵进程，它和内核系统通信采用 Netlink 接口来操 作，采用 ubus 总线来提供 RPC，这样比直接使用 Linux 内核的管理接口更方便。 
>
> Netlink 是 Linux 操作系统内核和用户空间的通信机制，通常用于在内核和用户空间进 程之间传输数据。它由针对用户空间的标准 socket 接口和内核空间的内部 API 模块组成。 RFC 3549 对 Netlink 有详细的介绍。 
>
> netifd 也提供接口来提供扩展功能。netifd 不需要 shell 脚本就可以设置静态 IP 配置。对于其他的 IP 设置()例如(PPPoE 或 DHCP)就需要一系列的 shell 脚本来处理协议实现。

### netifd基本框架

netifd 主要包含设备和接口对象。一个设备代表着一个 Linux 物理接口或者一个虚拟链路接口，例如 eth0 或 ppp 接口。任何需要关注设备状态的对象就注册为设备用户（device_user），当设备状态发生改变时就会通过回调函数来通知设备用户。当最后一个设备用户移除时，设备自己就立即释放。

我们配置一个网络接口通常都要完成下面三类工作：

1. MAC地址、设备MTU、协商速率等L2属性，这些都是直接操作实际网络设备的。
2. IP地址、路由（包括应用层的DNS）等L3属性。
3. 设置特定接入方式，如静态IP、DHCP、PPPoE等。设置完成后可能需要更新L3的属性。

 我们可以通过上述思路来理解netifd的设计 ：

![](E:\gateway_git\openwrt-database\note\hzp\pic\netifd.png)



拿我们最常用的路由器来讲，作为路由器的使用者我们只关心要配置interface层的哪个接口（LAN口、WAN口？），以及配置成怎样的上网方式。使用netifd配置网络，也是以interface为中心：创建一个interface并指明其依赖的实际网络设备（device），及其绑定的上网方式（proto handler），就完成了一个网络接口的配置并可使其开始工作。当网络状态发生变化时，这三者之间也能相互通知（事件通知或引用计数）以完成自身状态的转换。
例如，在/etc/config/network中对WAN口的配置如下 ： 

```shell
config interface 'wan'
    option ifname 'eth0'
    option proto 'static'
    option mtu '1500'
    option auto '1'
    option netmask '255.255.255.0'
    option ipaddr '192.168.1.100'   
    option gateway '192.168.1.1'
    option dns '8.8.8.8'
```

 Netifd通过读取上述配置，来创建出一个名为”WAN”的interface实例并将其中与interface相关的配置项应用到这个新创建的实例中。同时，如果其指定依赖的设备（ifname）不存在，就通过配置中与device相关的配置项创建一个新的device，并确定二者的依赖（引用）关系。由于proto handler中每一种proto的工作方式是确定的，不依赖于任何配置，因此在netifd启动时就会初始化好所有的proto handler，因而要求配置中的proto一项必须是在netifd中已存在的proto handler的名字。
也可以单独用一个uci section来保存device的配置信息，让netifd先把device创建好。 

### 设备层（Device）

Device是指链路层的设备，在netifd中就特指链路层的网络设备。Netifd中每个设备都用一个struct device_type结构的实例来表示。

设备也可以引用其他设备，这是用于管理各种设备，例如网桥或虚拟局域网（Virtual Local Area Network，VLAN）。这样将不用对各种设备进行区别对待，但需要通过热插拔来增加更多的成员接口，这在管理网桥设备时非常有用。

|      设备类型       | 含义                                                         |
| :-----------------: | :----------------------------------------------------------- |
| simple_device_type  | 简单设备                                                     |
| bridge_device_type  | 网桥设备，网桥设备可以包含多个简单设备                       |
| tunnel_device_type  | 隧道设备，例如在以太网上封装 GRE 报文                        |
| macvlan_device_type | 一个物理网卡上创建另外一个 MAC 地址的网卡，即在真实的物理网卡上再虚拟出来一个网卡 |
| vlandev_device_type | 一个物理网卡通过 VLAN ID 来划分为多个网卡                    |

创建好一个设备后，如果要引用这个设备，就要注册一个device_user，像上面说的，device的user一般是interface，但也有device之间相互引用的情况，例如bridge member和bridge的关系。向device注册和注销device_user的函数为device_add_user(user, dev)和device_remove_user(user)。

#### Device user

```c
/*
 * device dependency with callbacks
*/
struct device_user {
    struct list_head list;

    bool claimed;
    bool hotplug;
    bool alias;

    struct device *dev;
    void (*cb)(struct device_user *, enum device_event);
};
```

各个成员的含义：
**list**：该user引用的deivce的user链表节点。
**claimed**：相当于引用计数，由于一个user实例只能作为某一个device的user，因此设为BOOL类型。一个user在绑定了device后，还要通过device_claim才算真正使用了device。这样就允许引用和生效可以不同时进行，例如要等热插拔设备存在时才能启动interface。与claim相反的操作为device_release()。
**hotplug**：标识bridge下动态添加的、以及调ubus call network.interface add_device的设备。
**alias**：用来标记将该user加到device的users链表还是aliases链表。
**dev**：该user引用的device对象指针。
**cb()**：当device状态发生变化时，会调用该cb()函数以事件的形式来通知所有的users。目前支持的事件类型可参考netifd的DESIGN。

设备struct device中也维护了一个引用计数来控制设备的up/down状态，每次device_claim(user)成功后，引用计数+1，如果设备没有成功启动，claim_device 函数将返回非零值，设备的引用计数不会增加。每次device_release(user)成功后，引用计数-1。当引用计数从0变1，即有一个user使用了该device时，device就会被UP起来，而当引用计数从1变0，即最后一个user离开时，device就会立即被DOWN掉。

一个注册的设备可能不能立即可用，一个接口或其他设备也可以关联上它，等待它出现在系统中来支持通过热插拔触发接口。

所有的设备状态通过事件机制通知给设备用户注册的回调函数。以下表格所示的是主要支持的设备事件类型及含义。

| 设备事件类型       | 含义                                                         |
| ------------------ | ------------------------------------------------------------ |
| DEV_EVENT_ADD      | 系统中增加了设备，当设备用户增加到一个存在的设备上时，这个事件立即产生 |
| DEV_EVENT_REMOVE   | 设备不再可用，或者是移除了设备或者是不可见了。所有的设备用户应当立即移除引用并且清除这个设备的状态 |
| DEV_EVENT_SETUP    | 设备将要启动，这允许设备用户去应用一些必要的低级别的配置参数，这个事件并不是在所有情况下均被触发 |
| DEV_EVENT_UP       | 设备已经启动成功                                             |
| DEV_EVENT_TEARDOWN | 设备准备关闭                                                 |
| DEV_EVENT_DOWN     | 设备已经关闭                                                 |



### 接口层（interface）

由于device属于L2层的概念，如果用户对一个网络设备配置属于L3或更高层协议的属性，则要直接对interface进行操作，进而间接作用于device。因此一个interface必须绑定到一个device上，通过struct interface的main_dev成员指定。
Interface配置完成后，是否可以UP或DOWN由available和autostart两个成员来决定：

```c
struct interface {
    … …
    bool available;
    bool autostart;
    bool config_autostart; /* uci配置中的"autostart"，默认为true。仅用于uci有关的操作 */
    … …
};
```

**available**：interface是否是可用的(已准备好可以up了)，通过interface_set_available()来设置。
**autostart**：interface在配置完成后，是否自动执行up操作，默认和config_autostart值相同。但如果用户手动up了interface(如通过ubus来up)，则autostart强制变为true。如果用户手动down了interface(如通过ubus来down)，则autostart强制变为false。

而一个interface的具体配置内容都放在struct interface_ip_settings的结构中，由于一个interface可能有多个IP/Route/DNS条目，因此将这些信息又封装了一层，而不是直接放到struct interface中。

#### Interface user

不常用。Alias设备会产生一个interface user，用于指明自己的parent。Alias自身作为user的信息保存在struct interface的parent_iface成员中，而其parent则用struct interface的parent_ifname来指定。

### netifd方法

netifd 在 ubus 中注册了一些对象和方法，启动 netifd 进程之后，就可以通过“ubus list”命令来查看注册的对象。netifd 注册了 3 种对象，分别为 network、network.device 和network.interface。

```shell
#ubus list
network
network.device
network.interface
network.interface.lan
network.interface.loopback
network.interface.wan
network.wireless
```

每一个对象都包含有一些方法，而每个 ubus 方法都注册了一个接口函数来进行处理。

network 对象全局接口方法（执行` ubus -v list network `查看）：

|       方 法        |           函 数           | 含 义                                                        |
| :----------------: | :-----------------------: | ------------------------------------------------------------ |
|      restart       |   netifd_handle_restart   | 整个进程关闭后重新启动                                       |
|       reload       |   netifd_handle_reload    | 重新读取配置来初始化网络设备                                 |
|   add_host_route   |   netifd_add_host_route   | 增加静态主机路由，是根据当前的路由增加了一个更为具体的路由表项，目的地址为 IP 地址而不是 IP 网段。例如：ubus call network add_host_route '{"target":"192.168.1.20", "v6":"false"}'，将增加一个静态主机的接口路由 |
| get_proto_handlers | netifd_get_proto_handlers | 获取系统所支持的协议处理函数，该方法不需要参数               |
|    add_dynamic     |    netifd_add_dynamic     |                                                              |

network.device 是一个二层设备接口，已经向 ubus 总线注册的方法有 3 个（执行` ubus -v list network.device`查看）：

| 方 法     | 函 数                   | 含 义                                                        |
| --------- | ----------------------- | ------------------------------------------------------------ |
| status    | netifd_dev_status       | 获取物理网卡设备的状态，包含统计信息，例如 ubus call network.device status '{"name":"eth0"}' |
| set_alias | netifd_handle_alias     | 设置 alias，这个很少用到                                     |
| set_state | netifd_handle_set_state | 设置状态，这个也很少用到                                     |

还有 network.wireless （执行`ubus -v list network.wireless`查看）：

| 方 法        | 函 数                           |
| ------------ | ------------------------------- |
| up           | netifd_handle_wdev_up           |
| down         | netifd_handle_wdev_down         |
| status       | netifd_handle_wdev_status       |
| notify       | netifd_handle_wdev_notify       |
| get_validate | netifd_handle_wdev_get_validate |



network.interface 是一个三层接口，可以包含多个二层网卡设备，如果接口启动则包含IP 地址、子网掩码、默认网关和域名服务器地址等信息（执行`ubus -v list network.interface`查看）：

| 方 法         | 函 数                      | 含 义                                               |
| ------------- | -------------------------- | --------------------------------------------------- |
| up            | netifd_handle_up           | 启动接口                                            |
| down          | netifd_handle_down         | 关闭接口                                            |
| status        | netifd_handle_status       | 查看接口状态，如果为启动，则包含启动时间、IP 地址等 |
| add_device    | netifd_iface_handle_device | 增加设备                                            |
| remove_device | netifd_iface_handle_device | 删除设备                                            |
| notify_proto  | netifd_iface_notify_proto  | 调用原型函数，在 netifd-proto.sh 中会使用到         |
| remove        | netifd_iface_remove        | 删除接口                                            |
| set_data      | netifd_handle_set_data     | 设置额外的存储数据，可以通过 status 方法来查看      |

如果在对象中未指定接口名称，则需要在参数中指定接口名称。例如我们获取 lan 接
口的状态可以通过以下两种方法调用：
`ubus call network.interface status '{"interface":"lan"}'`
`ubus call network.interface.lan`



interface 对象的 notify_proto 方法共注册了 0～7 共 8 种动作处理函数，分别用于处理各种不同的情况。在/lib/netifd/netifd-proto.sh 中封装为不同的 shell 命令如表 所示。

| 编号 |         shell命令         | 含义                                                       |
| :--: | :-----------------------: | ---------------------------------------------------------- |
|  0   |     proto_init_update     | 初始化设备及配置                                           |
|  1   |     proto_run_command     | 运行获取 IP 地址命令，例如启动 dhcp 客户端或者启动 ppp拨号 |
|  2   |    proto_kill_command     | 杀掉协议处理进程，例如杀掉 udhcpc 进程                     |
|  3   |    proto_notify_error     | 通知发生错误                                               |
|  4   |    proto_block_restart    | 设置自动启动标示变量 autostart 为 false                    |
|  5   |    proto_set_available    | 设置接口的 available 状态                                  |
|  6   | proto_add_host_dependency | 增加对端 IP 地址的路由                                     |
|  7   |    proto_setup_failed     | 失败后设置状态                                             |

编号为在 netifd 进程和 shell 脚本之间的预先定义好的处理动作 ID。在 netifd-proto.sh中设置，通过 ubus 消息总线传递到 netifd 进程中，根据功能编号来进入到相应的处理函数。Shell 脚本导出的命令供各种协议处理函数调用。例如 DHCP 处理过程中会首先调用 proto_init_update 函数来初始化设备，初始化完成之后会通过 proto_run_command 命令来启动 udhcpc 进程获取 IP 地址等信息。

### proto  shell

proto是interface获取IP配置的方式，包括static、DHCP、DHCPv6、PPPoE等，其中static(proto_static)是在代码中定义的，不需要 Shell 脚本就可以进行 IP 配置。而DHCP、PPPoE定义在shell scripts上(proto_shell)，scripts位于/lib/netifd/proto/目录下。

文件名通常和网络配置文件 network 中的协议选项关联起来。为了访问网络功能函数，这些脚本通常在文件开头导入一些通用功能的 Shell 脚本，例如 functions.sh 脚本和netifd-proto.sh 脚本。

#### static proto

```c
static struct proto_handler static_proto = {
    .name = "static",
    .flags = PROTO_FLAG_IMMEDIATE |
         PROTO_FLAG_FORCE_LINK_DEFAULT,
    .config_params = &proto_ip_attr,
    .attach = static_attach,
}; 
```

config_params包括ipaddr、ip6addr、netmask、broadcast、gateway、ip6gw、ip6prefix；
如果一个interface需要使用到该proto，则会使用它的attach方法。 



#### Proto handler的注册

通过构造函数，在netifd启动的时候便注册了一系列的proto handler（注册到一个全局的AVL树中）。

```shell
proto_shell_init() -> proto_shell_add_script() -> proto_shell_add_handler() -> add_proto_handler();
static_proto_init() -> add_proto_handler();
```

 注册的过程为：在/lib/netifd/proto目录下对每个.sh文件执行**./xxx.sh  '' dump ** ， 执行结果是一个json格式的字符串 。例如对于dhcp.sh： 

```shell
root@openwrt:/lib/netifd/proto# ./dhcp.sh '' dump
{ "name": "dhcp", "config": [ [ "ipaddr", 3 ], [ "netmask", 3 ], [ "hostname", 3 ], [ "clientid", 3 ]
, [ "vendorid", 3 ], [ "enable_broadcast", 7 ], [ "reqopts", 3 ] ], "no-device": false, "available": 
false }
```

 分析一下执行脚本命令`dhcp.sh '' dump`做了哪些事情，进到dhcp.sh，首先执行函数init_proto “$@”，init_proto定义在netifd-proto.sh中，init_proto函数中，cmd=dump，也就是定义了函数add_protocol； 

```c
add_protocol() {
        no_device=0
        no_proto_task=0
        available=0
        renew_handler=0

        add_default_handler "proto_$1_init_config"

        json_init
        json_add_string "name" "$1"
        json_add_array "config"
        eval "proto_$1_init_config"
        json_close_array
        json_add_boolean no-device "$no_device"
        json_add_boolean no-proto-task "$no_proto_task"
        json_add_boolean available "$available"
        json_add_boolean renew-handler "$renew_handler"
        json_add_boolean lasterror "$lasterror"
        json_dump
}
```

 回到dhcp.sh，文件的最后会执行函数add_protocol dhcp，实际上就是装置一个json结构的字符串，包括key：name、config、no-device、no-proto-task、available、renew-handler和lasterror；config为array类型，在proto_dhcp_init_config中组装，proto_dhcp_init_config函数定义在dhcp.sh中，向config添加成员ipaddr:ipaddr、hostname:hostname、clientid、vendorid、broadcast:bool、reqopts:list(string)、iface6rd、sendopts、delegate、zone6rd、zone、mtu6rd、customroutes，这些即是DHCP需要的参数。
proto_shell_add_handler中封装一个proto_handle *proto： 

```c
proto->name = "dhcp"
proto->attach = proto_shell_attach
proto->flags //依赖于dump中no-device、no-proto-task、available、renew-handler和lasterror
proto->config_params //从dump中的config导入，包括ipaddr、hostname、clientid、vendorid、broadcast、reqopts、iface6rd、sendopts、delegate、zone6rd、zone、mtu6rd、customroutes
```

 而最终该脚本的proto handler保存在一个struct proto_handler结构的实体中，并通过add_proto_handler 最后通过add_proto_handler将proto添加到全局avl tree中，也就是句柄handlers中，供后续查找和引用。上述的dhcp.sh注册的结果为： 

```shell
struct proto_shell_handler *handler;
handler->script_name = "./dhcp.sh";
handler->proto.name = "dhcp";
handler->proto.config_params = &handler->config;
handler->proto.attach = proto_shell_attach;
handler->proto.flags |= ...; //由no-device和available决定，ppp使用，static和dhcp不关注
handler->proto.avl.key = handler->proto.name; //插到handler树中的key
handler->config.n_params = 7; //下面config param的数目
handler->config_buf = "ipaddr\0netmask\0hostname ..."
handler->config.params[0].name = "ipaddr";
handler->config.params[0].type = 3; //BLOBMSG_TYPE_STRING
handler->config.params[1].name = "netmask";
handler->config.params[1].type = 3;
... ...
```

 其中handler->proto.config_params中的配置列表，就是为了使proto生效，而需要在uci中配置的项。

dhcp.sh中：

（1）proto_dhcp_init_config。这个函数负责协议配置的初始化，主要目的是让 netifd知道这个协议所拥有的参数。这些参数存储在/etc/config/network 配置文件中。


```c
proto_dhcp_init_config() {
	renew_handler=1
	proto_config_add_string 'ipaddr:ipaddr'
	proto_config_add_string 'hostname:hostname'
	proto_config_add_string clientid
	proto_config_add_string vendorid
	proto_config_add_boolean 'broadcast:bool'
	proto_config_add_string 'reqopts:list(string)'
	proto_config_add_string iface6rd
	proto_config_add_string sendopts
	proto_config_add_boolean delegate
	proto_config_add_string zone6rd
	proto_config_add_string zone
	proto_config_add_string mtu6rd
	proto_config_add_string customroutes
}
```

（2）proto_dhcp_setup。这个函数负责协议的设置，主要目的是实现了实际 DHCP 协议配置和接口启动。当被调用时，传递两个参数，第一个参数是配置节名称，第二个参是接口名称。任何协议处理都必须实现设置函数。这个函数通常是读取配置文件中的参数，然后将参数传递给 netifd。DHCP 协议在这个函数中组织 DHCP 参数传递给 udhcpc 进程。
（3）proto_dhcp_teardown。这个函数负责接口关闭动作，如果协议需要特别的关闭处理，例如杀掉 udhcpc 进程，调用停止功能等。这个函数在我们使用 ifdown 命令关闭接口时调用，或者是 netifd 探测到链路连接失去时调用。这个函数是通常可选的，调用时需要传递一个参数为 UCI 配置节名称，用于 config_get 函数调用时获取 UCI 配置。

#### Proto与interface的绑定

interface的config中具有名为”proto”的属性，在interface_init()函数中读取uci配置获取proto的名字（如”static”、”dhcp”、”pptp”），然后查找已注册的对应名字的proto handler，并赋值给interface的proto_handler数据成员，这样就使一个interface绑定到了一个特定的proto handler上。这是在初始化一个interface的时候完成的。

#### Proto与interface的交互

由于proto是更上层的概念，因此是与interface无关的，而一个interface总会关联到一种proto。例如，WAN口总会要设置一种上网方式（static/dhcp/pppoe等），因此在interface进行配置的过程中，通过调用其proto_handler的attach()方法，为自己分配一个struct interface_proto_state结构并赋值给interface的proto数据成员。这个过程是在proto_init_interface()函数中完成的。也就是说，interface通过其proto成员与proto层交互来通知proto自身状态的变化。

```c
struct interface_proto_state {
    const struct proto_handler *handler; //其对应的proto handler
    struct interface_t *iface; //其attach的interface

    /* 由proto的user来赋值，对于interface，被统一赋值为了interface_proto_cb */
    void (*proto_event)(struct interface_proto_state *, enum interface_proto_event ev);
    
    /* 由特定proto handler来赋值。 */
    int (*notify)(struct interface_proto_state *, struct blob_attr *data);
    int (*cb)(struct interface_proto_state *, enum interface_proto_cmd cmd, bool force);
    void (*free)(struct interface_proto_state *);
};
```

这个结构中的几个方法：
**cb**: 在interface向proto发送某个事件event时，proto的处理函数。目前proto接受的事件有两个：PROTO_CMD_SETUP和PROTO_CMD_TEARDOWN。
**proto_event**: 在proto处理event完成后，如果需要告知interface处理已完成，就调用该方法。Interface会根据这个回复的消息做这个event的收尾工作。
**notify**: 如果proto需要主动改变interface的状态，则调用该方法。可以在/lib/netifd/netifd-proto.sh中去了解不同”action”的值的含义以及如何通过ubus通知到netifd的，netifd收到notify的消息后，由proto_shell_notify()进行处理。
**free**: 释放自己的struct interface_proto_state指针。

Interface通过interface_proto_event()函数向proto层发送事件来告知其自身状态的变化，即这个函数是interface层通向proto层的入口，在interface的状态变为IFS_SETUP或IFS_TEARDOWN的时候都会通过该函数通知到proto，发送的事件对应为PROTO_CMD_SETUP和PROTO_CMD_TEARDOWN。

### netifd文件

netifd 还包含一些非常方便用户操作的命令，这些命令调用 ubus 命令来查询 netifd进程提供的设备和网络接口管理服务。
* /sbin/ifup：启动接口。

* /sbin/ifdown：关闭接口。

* /sbin/devstatus：获取网卡设备状态。

* /sbin/ifstatus：获取接口的状态。

ifup 和 ifdown 实际上为一个文件，ifdown 是指向 ifup 的软链接。这两个脚本由同一个文件 ifup 实现。在执行时会判断执行的文件名称，然后传递相应的参数。如果传递-a 选项则表示所有的接口，这两个命令可以传递接口名称，例如 lan 或 wan 接口，来控制局域网接口和互联网接口的状态，实际上是通过调用 ubus 命令来控制的。命令如下：
  `ubus call network.interface.<lan/wan> <down/up>`
devstatus 命令需要一个参数，参数传递一个网卡设备名称，devstatus 命令将设备名称转换为 JSON 格式后通过 ubus 总线传递给 netifd，最后调用的命令为：
  `ubus call network.device status '{ "name": "eth0" }'`
ifstatus 命令用于获取接口的状态，该命令首先判断是否传递了参数，需要传递接口名称作为参数。接着使用 list 方法来查看接口对象是否存在。最后通过接口的 status 方法来获取接口状态，这个方法的签名使用 ubus list 查看显示没有参数，但在实际调用时必须传递接口名称作为参数才能成功。如果我们查看局域网接口的状态，最后调用的命令为：
  `ubus call network.interface status'{"interface": "lan"}'`

#### 网络配置

网络功能的配置文件在/etc/config/network 中。这个配置文件定义了二层网络设备Device 和网络接口 Interface、路由和策略路由等配置。网络接口配置根据协议的不同包含的选项不同。常见的协议有静态配置、DHCP 及 PPPoE 等。接口配置协议不同，支持的配置选项不同。协议配置以 proto 来做区分，如果为 static 则需要设置 IP 地址和网络掩码等。DHCP，表示通过动态主机控制协议获取 IP 信息。PPPoE，表示通过拨号来获取 IP。

如果网络服务提供商（ISP）提供固定 IP 地址，则使用静态配置，另外局域网接口通 常为静态配置。静态配置可以设置的选项如下:

|  名 称  | 类 型  | 含 义                                |
| :-----: | :----: | ------------------------------------ |
| ifname  | 字符串 | 物理网卡接口名称，例如："eth0"       |
|  type   | 字符串 | 网络类型，例如：bridge               |
|  proto  | 字符串 | 设置为 static，表示静态配置          |
| ipaddr  | 字符串 | IP 地址                              |
| netmask | 字符串 | 网络掩码                             |
|   dns   | 字符串 | 域名服务器地址，例如为 8.8.8.8       |
|   mtu   |  数字  | 设置接口的 mtu 地址，例如设置为 1460 |

当 ISP（网络服务提供商）未提供任何 IP 网络参数时，选择通过 DHCP 协议来设置。 这种情况下，路由器将从 ISP 自动获取 IP 地址。DHCP 配置选项如下：

|  名 称   | 类 型  | 含 义                              |
| :------: | :----: | ---------------------------------- |
|  ifname  | 字符串 | 物理网卡接口名称，例如："eth0"     |
|  proto   | 字符串 | 协议类型为 DHCP                    |
| hostname | 字符串 | DHCP 请求中的主机名，可以不用设置  |
| vendorid | 字符串 | DHCP 请求中的厂商 ID，可以不用设置 |
|  ipaddr  | 字符串 | 建议的 IP 地址，可以不用设置       |

更常见的是 PPPoE，使用用户名和密码进行宽带拨号上网。设置选项如下：

| 名 称    | 类 型  | 含 义                                                        |
| -------- | ------ | ------------------------------------------------------------ |
| ifname   | 字符串 | PPPoE 所使用物理网卡接口名称，例如 eth0                      |
| proto    | 字符串 | 协议 PPPoE，采用点对点拨号连接                               |
| username | 字符串 | PAP 或 CHAP 认证用户名                                       |
| password | 字符串 | PAP/CHAP 认证密码                                            |
| demand   | 数字   | 指定空闲时间之后将连接关闭，在以时间为单位计费的环境下经常使用 |

### 参考资料

[1] [OpenWrt Wiki - netifd Technical Reference](https://wiki.openwrt.org/doc/techref/netifd)
[2] [ netifd DESIGN](http://git.openwrt.org/?p=project/netifd.git;a=blob;f=DESIGN)
[3] [ netifd project](http://git.openwrt.org/?p=project/netifd.git;a=summary)

