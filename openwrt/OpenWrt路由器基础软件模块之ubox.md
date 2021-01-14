## OpenWrt 基础软件模块之ubox

> Openwrt 支持模块化编程，增加新功能非常简单。但是一些通用的基础模块必须包含,他们是OpenWrt核心。
> 如：实用基础库libubox、系统总线ubus、网络接口管理模块netifd、核心工具模块ubox、服务管理模块procd。



### 核心工具模块ubox

>  ubox在2013年加入OpenWrt的代码库中。它是 OpenWrt 中的一个核心扩展功能，是OpenWrt的**帮助工具箱** 

ubox分三个部分：

- 内核模块管理，例如加载内核模块，查看已经加载内核模块等
- 日志管理
- UCI配置文件数据类型的验证



#### 内核模块管理

>  内核模块管理使用kmodloader来管理，并软链接为以下5个不同的Linux命令： 



- **rmmod：** 从Linux内核中移除一个模块
- **insmod： ** 向Linux内核插入一个模块
- **lsmod：**  显示已加载到Linux内核中的模块状态
- **modinfo： ** 显示一个Linux内核模块的信息，包含模块路径、许可协议和所依赖模块 
- **modprobe：** 加载一个内核模块 



#### 日志管理

- 日志管理提供了ubus日志服务，可以**通过ubus总线**来获取和写入日志
- logread读取日志，logd来对日志进行管理



#### 配置文件数据类型的验证

> 对于其他软件模块来说，主要使用 ubox 提供的配置文件验证功能，这样带来了一些好处，可以在软件启动之前**使用脚本来对UCI配置进行验证**，这样可以很好的同其他软件模块进行分工合作 

**配置验证选项有很多类型和关键字，下标列出常用的验证关键字含义：**

| **关键字**    | **含 义**                                                    |
| ------------- | ------------------------------------------------------------ |
| **bool**      | 布尔值，合法的取值有"0"、"off"、"false"、"no"、"disabled"、"1"、"on"、"true"、"yes" 和"enabled" |
| **cidr**      | 无类别路由选择的缩写，包含 cidr4 和 cidr6，是指 IP 地址和其掩码长度，IPv4 类型通常 为 255.255.255.255/32 格式 |
| **cidr4**     | IPv4 类型的 IP 地址和其子网掩码，格式为 255.255.255.255/32   |
| **file**      | 文件路径，例如为/etc/config/network                          |
| **host**      | 主机名称、域名或 IP 地址                                     |
| **ip4addr**   | IPv4 地址，可以是任何 IP 地址，不验证 IP 地址合法性          |
| **list**      | 是指一个类型的几个数据列表，中间用空格分开，例如 list(port)表示是一个端口列表 |
| **netmask4**  | IPv4 地址的网络掩码，例如 255.255.255.0                      |
| **or**        | 表示可以为几种类型的一个，例如 or(port, portrange)表示为端口或者端口范围 |
| **portrange** | 端口范围，形式为 n-m，中间为短横线，不能为冒号，数字小于 65535，并且 n≤m |
| **port**      | 端口号数字，合法数字范围为 0～65535                          |
| **range**     | 表示数字所处的范围，例如 range(0, 31)表示大于等于 0，小于等于 31 |
| **string**    | 字符串，可以限定字符串长度，例如 string(1, 10)限定字符串长度在 1 到 10 之间 |
| **uinteger**  | 无符号整形数字                                               |

提供的配置验证工具为**validate_data** 

方法：

- 第一种用法是对单个数据类型进行验证，它通常用于在软件启动前直接验证，如果数据类型不正确，将输出错误并退出启动流程；它需要两个参数，第一个参数为数据类型，第二个参数为需要验证的配置值

如： cron软件包对配置参数进行验证，是否为整型数字，如果不是数字，则输出验证失败并退出 

```shell
loglevel=$(uci_get "system.@system[0].cronloglevel")
 
[ -z "${loglevel}" ] || {
    /sbin/validate_data uinteger "${loglevel}" 2>/dev/null
[ "$?" -eq 0 ] || {
    echo "validation failed"
    return 1
    }
}
```

- 第二种用法是对配置文件的多个数据类型进行验证； 它至少需要4个参数，第一个参数为 UCI 配置文件名，第二个参数为配置节类型，第三个参数配置节的名称，第四个参数 为验证的 UCI 选项、类型和默认值； 如果有多个配置选项需要验证，则以空格分开紧跟在 第四个参数在后面

如： 对网络时间服务器的配置进行验证，该用法必须指定配置节的名称，不能对匿名配置节的内容进行检查。前两行是命令输入，后面是该工具对配置文 件检查的结果。可以使用 echo $？来获取其返回值，0 表示成功，根据返回值是否成功再 执行下一步的处理流程。

```shell
/sbin/validate_data system timeserver ntp \
    'server:list(host)' 'enabled:bool:1' 'enable_server:bool:0'

#下面是输出
system.ntp.server[0]=0.openwrt.pool.ntp.org validates as list(host) with true
system.ntp.server[1]=1.openwrt.pool.ntp.org validates as list(host) with true
system.ntp.server[2]=2.openwrt.pool.ntp.org validates as list(host) with true
system.ntp.server[3]=3.openwrt.pool.ntp.org validates as list(host) with true
system.ntp.enabled=1 validates as bool with true
system.ntp.enable_server=0 validates as bool with true
server='0.openwrt.pool.ntp.org'\ '1.openwrt.pool.ntp.org'\ '2.openwrt.pool.ntp.org'\ '3.openwrt.pool.ntp.org'; enabled=1; enable_server=0;
```

* 第3种用法的参数和第2种用法参数含义和顺序完全相同，但第 3 个参数为`""`(注意不要有空格)，表示空字符串，在这种情况下，将生成导入验证服务的命令字符串 

 **如：** 下面案例前两行是命令调用， 其后是该命令生成的字符串 

```shell
/sbin/validate_data system timeserver "" ntp \
	'timeserver:list(host)' 'enabled:bool:1' 'enable_server:bool:0'

#下面是输出
json_add_object; 
json_add_string "package" "system"; 
json_add_string "type" "timeserver"; 
json_add_object "data"; 
json_add_string "timeserver" "list(host)"; 
json_add_string "enabled" "bool"; 
json_add_string "enable_server" "bool"; 
json_close_object; 
json_close_object;
```

