## OpenWrt 基础软件模块之libubox

> Openwrt 支持模块化编程，增加新功能非常简单。但是一些通用的基础模块必须包含,他们是OpenWrt核心。
> 如：实用基础库libubox、系统总线ubus、网络接口管理模块netifd、核心工具模块ubox、服务管理模块procd。



### libubox软件模块

- libubox是在2011年加入OpenWrt的代码库的。它是OpenWrt中的一个核心库，封装了一系列基础实用功能
- **提供的功能**：主要提供事件循环、二进制块格式处理、Linux链表实现和一些JSON辅助处理
- 它的目的是以动态链接库方式来提供可重用的通用功能，给其他模块提供便利和避免再造轮子
- 这个软件由许多独立的功能组成，主要**划分为3个软件包libubox、 jshn和libblobmsg-json**

#### libubox库

- libubox软件包是OpenWrt 12.09版本之后增加到新版本中的一个基础库，在Open Wrt 15.07中有很多应用程序是基于libubox开发的，如ubus、netifd和freecwmp等
- 这样带来了一些好处：我们不用关注底层基础功能，可以基于libubox提供的稳定API来进行进一步的功能开发
- **libubox主要提供以下三部分功能：**
  - **提供多种基础通用功能接口，包含链表、平衡二叉树、二进制块处理、key-value链表、MD5等**
  - **提供多种sock接口封装**
  - **提供一套基于事件驱动的机制及任务队列管理功能**

代码：[https://git.openwrt.org/?p=project/libubox.git;a=tree](https://git.openwrt.org/?p=project/libubox.git;a=tree)

` utils.h`提供简单实用功能，包括字节序转换、位操作、编译器属性包装、连续的内存分配函数、静态数组大小的宏、断言/错误的实用功能和 base64 编码解码等功能 

` blob.h`提供二进制数据处理功能。有几种支持的数据类型，并可以创建块数据在socket上发送。整形数字会在libubox库内部转换为网络字节序进行处理。二进制块的处理方法是创建一个TLV（类型-长度-值）链表数据，支持嵌套类型数据，并提供设置和获取数据接口。Blobmsg 位于 blob.h 的上层，提供表格和数组等数据类型的处理
**TLV** 是用于表示可变长度的数据格式，Type 表示数据的类型，Length 表示数据的长度， Value 存储着数据值。类型和长度的占用空间是固定的，在 libubox 库中共占用 4 个字节。 Value 的长度由 Length 指定。这样可以存储和传输任何类型的数据，只需预先定义服务器 和客户端之间的 TLV 的类型和长度的空间大小即可。在 DHCP 协议中也是采用 TLV 数据 类型来传输扩展数据的

` usock.h `是一个非常简单的 socket 对象封装，以避免所有这些套接字接口库复杂调用。 可以创建 TCP、UDP 和 UNIX 套接字，包含客户端和服务器端、IPv4/IPv6、阻塞/非阻塞 等。可以通过 usock 函数来返回所创建的文件描述符 

 `uloop.h` 是提供事件驱动机制接口，是基于epoll接口来实现的。uloop是一个I/O循环调度，将不同的文件描述符添加到轮询中。文件描述符fd的管理由 uloop_fd 结构来设置。仅需设置 fd 和事件发生时的回调函数，数据结构的其他部分供内部使用。超时管理 部分由 uloop_timeout 结构来管理，在定时时间到了之后调用回调函数，定时时间单位为 毫秒 ,常用接口：

| **接 口 名 称**       | **含 义**                                                    |
| --------------------- | ------------------------------------------------------------ |
| **uloop_fd_add**      | 将一个新文件描述符增加到事件处理循环中                       |
| **uloop_fd_delete**   | 从事件处理循环中删除指定的文件描述符                         |
| **uloop_init**        | 初始化 uloop.内部将调用 epoll_create 函数来创建 epoll 对象   |
| **uloop_run**         | 进入事件处理循环中                                           |
| **uloop_done**        | 反初始化 uloop，即释放内部 epoll 对象，删除内部的超时和 process 对象 |
| **uloop_end**         | 设置 uloop 内部结束循环标志                                  |
| **uloop_timeout_set** | 设置定时器超时时间，并增加到链表中                           |

#### jshn库 [官方参考](https://openwrt.org/docs/guide-developer/jshn)

- jshn是封装JSON对象的转换库，用于脚本语言生成JSON对象和将JSON对象数据取出
- jshn软件包含两个文件分别为：**jshn和jshn.sh**

**jshn命令工具**：`Usage: jshn [-n] [-i] -r <message>|-R <file>|-w`

* 工具jshn提供以下两部分功能：

  * 读取JSON格式的字符串，并组合为json_add_*命令导出到标准输出（stdout）中

  * 将环境变量中的设置组合为JSON字符串，并输出到标准输出中

* 常用选项：
  * -r：通过该选项来读取JSON格式字符串，并按照类型和名称导出到标准输出中
  * -w：可以读取环境变量设置来生成JSON对象字符串
  
  - `-R ` :从文件解析
  - `-o ` write to file 写入文件
  - `-p ` set prefix设置前缀
  - `-n` no newline没有换行符
  - `-i` indent缩进
  
  例如`jshn -i -R /etc/board.json `
  
  ```shell
  root@OpenWrt:/# jshn
  Usage: jshn [-n] [-i] -r <message>|-R <file>|-o <file>|-p <prefix>|-w
  root@OpenWrt:/# jshn -i -R /etc/board.json 
  json_init;
  json_add_object 'model';
  json_add_string 'id' 'innotek-gmbh-virtualbox';
  json_add_string 'name' 'innotek GmbH VirtualBox';
  json_close_object;
  json_add_object 'network';
  json_add_object 'lan';
  json_add_string 'ifname' 'eth0';
  json_add_string 'protocol' 'static';
  json_close_object;
  json_add_object 'wan';
  json_add_string 'ifname' 'eth1';
  json_add_string 'protocol' 'dhcp';
  json_close_object;
  json_close_object;
  ```
  
  

 **jshn.sh脚本**

- jshn.sh是利用jshn工具对JSON的操作进行的更为便利的封装。这样其他模块可以更方便地进行操作
- **主要提供以下三部分功能：**
  - ①将JSON格式的字符串在环境变量中导入和导出
  - ②将配置内容设置到环境变量中
  - ③从环境变量中查询配置设置的值
- jshn.sh定义了大量的函数来对JSON数据进行编程操作。其内部实现是将定义的变量存储在shell空间中，这样可以用函数来操作每一个JSON对象。在操作完成后调用json_dump函数输出所有的内容
- **备注：**在使用jshn.sh中的函数之前，**需要使用source命令来执行jshn.sh**。source命令是在当前环境下执行的，其设置的环境变量对其后面的命令都有效。 source命令和点命令“. ”等效

| **函 数 命 令**        | **含 义**                                                    |
| ---------------------- | ------------------------------------------------------------ |
| **json_init**          | 初始化JSON对象                                               |
| **json_add_string**    | 增加字符串数据类型，例如 json_add_string name zhang          |
| **json_dump**          | 以 JSON 格式输出所有增加的 JSON 内容                         |
| **json_add_int**       | 增加整型数据，例如 json_add_int age 36                       |
| **json_add_boolean**   | 增加布尔类型数据                                             |
| **json_set_namespace** | 定义命名空间，即定义设置变量的前缀，这样变量就可以区分开来   |
| **json_load**          | 将所有内容读入到 JSON 对象中，并将这些对象设置到环境变量中   |
| **json_get_var**       | 从环境变量中读取 JSON 对象的值，例如 json_get_var ifdev device 获取 device 的 值并赋值给 ifdev 变量 |
| **json_get_type**      | 从环境变量中读取指定 JSON 对象的类型，例如 json_get_type iftype device 获取 device 的类型并赋值给 iftype 变量 |
| **json_get_keys**      | 从环境变量中读取 JSON 对象的所有名称，例如 json_get_keys keys 获取所有的名 称并赋值给 keys 变量 |
| **json_get_values**    | 从环境变量中读取 JSON 对象的所有值，例如 json_get_values values 将获取所有 的值并赋值给 values 变量 |
| **json_select**        | 选择JSON对象。因为 JSON 对象会嵌套 JSON 对象，因此在操作内部嵌套对象 时首先选择所操作的 JSON 对象例如：选择111这个对象进行操作：json_select 111选择上一层JSON对象：json_select .. |
| **json_add_object**    | 增加对象，其后的操作均在该对象内部进行操作，该命令不需要参数 |
| **json_close_object**  | 完成对象的增加                                               |
| **json_add_array**     | 增加顺序数组，例如 json_add_array study，数组的内容后续通过 json_add_string 来增加 |
| **json_close_array**   | 完成顺序数组的增加                                           |
| **json_cleanup**       | 清除jshn所有设置的环境变量                                   |

例如：

```shell
source /usr/share/libubox/jshn.sh  #导出json_开头的函数，使后续可以调用
json_init                          #初始化
json_add_int action 2             #增加执行动作
json_add_int signal 9             #增加信号量
json_add_string "interface" "wan"  #增加操作的接口
env                                #这时将所有 JSON 字符串保存到环境变量中。可以使用该命令查看环境变量
json_dump                          #输出前面设置的所有 JSON 字符串
json_cleanup                       #jshn所有设置的环境变量
env                                #再次查看消失
```





