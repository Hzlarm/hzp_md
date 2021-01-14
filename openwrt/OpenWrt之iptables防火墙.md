### 防火墙概述

> Linux防火墙通常包括两个部分，分别为iptables和netfilter。
> iptables是Linux管理防火墙规则的命令行工具，处于用户空间。
> netfilter执行报文过滤，处于Linux内核空间。
> 有时候也用iptables来统称Linux防火墙。(但实际上netfilter才是真正的防火墙)
>
> netfilter是Linux操作系统核心层内部的一个数据包处理模块，它具有如下功能：
> 网络地址转换(Network Address Translate)、数据包内容修改、以及数据包过滤的防火墙功能
> 虽然我们使用service iptables start启动iptables"服务"，但是其实准确的来说，iptables并没有一个守护进程，所以并不能算是真正意义上的服务，而应该算是内核提供的功能。

[参考](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)

![数据经过防火墙的流程](E:\gateway_git\openwrt-database\note\hzp\pic\数据经过防火墙的流程.png)

### iptables基础

* 规则（rules），规则其实就是网络管理员预定义的条件，规则一般的定义为"如果数据包头符合这样的条件，就这样处理这个数据包"。规则存储在内核空间的信息包过滤表中，这些规则分别指定了源地址、目的地址、传输协议（如TCP、UDP、ICMP）和服务类型（如HTTP、FTP和SMTP）等。当数据包与规则匹配时，iptables就根据规则所定义的方法来处理这些数据包，如放行（accept）、拒绝（reject）和丢弃（drop）等。配置防火墙的主要工作就是添加、修改和删除这些规则。 

* 链（chains）是数据包传播的路径，每一条链其实就是众多规则中的一个检查清单，每一条链中可以有一条或数条规则。当一个数据包到达一个链时，iptables就会从链中第一条规则开始检查，看该数据包是否满足规则所定义的条件。如果满足，系统就会根据该条规则所定义的方法处理该数据包；否则iptables将继续检查下一条规则，如果该数据包不符合链中任一条规则，iptables就会根据该链预先定义的默认策略来处理数据包。 

  五个规则链。

  * PREROUTING (路由前)

  * INPUT (数据包流入口)

  * FORWARD (转发)

  * OUTPUT(数据包出口)

  * POSTROUTING（路由后）


这是NetFilter规定的五个规则链，任何一个数据包，只要经过本机，必将经过这五个链中的其中一个链。       

* 表（tables）提供特定的功能，iptables内置了4个表，即raw表、filter表、nat表和mangle表，分别用于实现包过滤，网络地址转换和包重构的功能。 

（1）RAW表： 关闭nat表上启用的连接追踪机制；iptable_raw 

只使用在PREROUTING链和OUTPUT链上,因为优先级最高，从而可以对收到的数据包在连接跟踪前进行处理。一但用户使用了RAW表,在 某个链上,RAW表处理完后,将跳过NAT表和 ip_conntrack处理,即不再做地址转换和数据包的链接跟踪处理了。这个表很少用到。

（2）filter表 ： 负责过滤功能，防火墙；内核模块：iptables_filter 

主要用于过滤数据包，该表根据系统管理员预定义的一组规则过滤符合条件的数据包。对于防火墙而言，主要利用在filter表中指定的规则来实现对数据包的过滤。Filter表是默认的表，如果没有指定哪个表，iptables 就默认使用filter表来执行所有命令，filter表包含了INPUT链（处理进入的数据包），RORWARD链（处理转发的数据包），OUTPUT链（处理本地生成的数据包）在filter表中只能允许对数据包进行接受，丢弃的操作，而无法对数据包进行更改。这里是真正实现防火墙处理的地方。

（3）nat表： network address translation，网络地址转换功能；内核模块：iptable_nat 

主要用于网络地址转换NAT，该表可以实现一对一，一对多，多对多等NAT 工作，iptables就是使用该表实现共享上网的，NAT表包含了PREROUTING链（修改即将到来的数据包），POSTROUTING链（修改即将出去的数据包），OUTPUT链（修改路由之前本地生成的数据包）

（4）mangle表： 拆解报文，做出修改，并重新封装 的功能；iptable_mangle 

主要用于对指定数据包进行更改，以便进行QoS和策略路由。在内核版本2.4.18 后的linux版本中该表包含的链为：INPUT链（处理进入的数据包），RORWARD链（处理转发的数据包），OUTPUT链（处理本地生成的数据包）POSTROUTING链（修改即将出去的数据包），PREROUTING链（修改即将到来的数据包）

此外，还有security表，这个表用于安全Linux的防火规则，是iptables后面新增的，在实际项目中还很少用到。

**规则表之间的优先顺序：**

`Raw——mangle——nat——filter`

**规则链之间的优先顺序（分三种情况）：**

* 第一种情况：入站数据流向

从外界到达防火墙的数据包，先被PREROUTING规则链处理（是否修改数据包地址等），之后会进行路由选择（判断该数据包应该发往何处），如果数据包 的目标主机是防火墙本机（比如说Internet用户访问防火墙主机中的web服务器的数据包），那么内核将其传给INPUT链进行处理（决定是否允许通 过等），通过以后再交给系统上层的应用程序（比如Apache服务器）进行响应。

* 第二冲情况：转发数据流向

来自外界的数据包到达防火墙后，首先被PREROUTING规则链处理，之后会进行路由选择，如果数据包的目标地址是其它外部地址（比如局域网用户通过网 关访问QQ站点的数据包），则内核将其传递给FORWARD链进行处理（是否转发或拦截），然后再交给POSTROUTING规则链（是否修改数据包的地 址等）进行处理。

* 第三种情况：出站数据流向

防火墙本机向外部地址发送的数据包（比如在防火墙主机中测试公网DNS服务器时），首先被OUTPUT规则链处理，之后进行路由选择，然后传递给POSTROUTING规则链（是否修改数据包的地址等）进行处理。



处理动作在iptables中被称为target（这样说并不准确，我们暂且这样称呼），动作也可以分为基本动作和扩展动作。

此处列出一些常用的动作，之后的文章会对它们进行详细的示例与总结：

**ACCEPT**：允许数据包通过。

**DROP**：直接丢弃数据包，不给任何回应信息，这时候客户端会感觉自己的请求泥牛入海了，过了超时时间才会有反应。

**REJECT**：拒绝数据包通过，必要时会给数据发送端一个响应的信息，客户端刚请求就会收到拒绝的信息。

**SNAT**：源地址转换，解决内网用户用同一个公网地址上网的问题。

**MASQUERADE**：是SNAT的一种特殊形式，适用于动态的、临时会变的ip上。

**DNAT**：目标地址转换。

**REDIRECT**：在本机做端口映射。

**LOG**：在/var/log/messages文件中记录日志信息，然后将数据包传递给下一条规则，也就是说除了记录以外不对数据包做任何其他操作，仍然让下一条规则去匹配。

### iptables规则的"增删改查" 

##### 查看规则：
iptables -t 表名 -L
查看对应表的所有规则，-t选项指定要操作的表，省略"-t 表名"时，默认表示操作filter表，-L表示列出规则，即查看规则。

iptables -t 表名 -L 链名
查看指定表的指定链中的规则。

iptables -t 表名 -v -L
查看指定表的所有规则，并且显示更详细的信息（更多字段），-v表示verbose，表示详细的，冗长的，当使用-v选项时，会显示出"计数器"的信息，由于上例中使用的选项都是短选项，所以一般简写为iptables -t 表名 -vL

iptables -t 表名 -n -L
表示查看表的所有规则，并且在显示规则时，不对规则中的IP或者端口进行名称反解，-n选项表示不解析IP地址。

iptables --line-numbers -t 表名 -L
表示查看表的所有规则，并且显示规则的序号，--line-numbers选项表示显示规则的序号，注意，此选项为长选项，不能与其他短选项合并，不过此选项可以简写为--line，注意，简写后仍然是两条横杠，仍然是长选项。

iptables -t 表名 -v -x -L
表示查看表中的所有规则，并且显示更详细的信息(-v选项)，不过，计数器中的信息显示为精确的计数值，而不是显示为经过可读优化的计数值，-x选项表示显示计数器的精确值。

实际使用中，为了方便，往往会将短选项进行合并，所以，如果将上述选项都糅合在一起，可以写成如下命令，此处以filter表为例。
iptables --line -t filter -nvxL
当然，也可以只查看某张表中的某条链，此处以filter表的INPUT链为例
iptables --line -t filter -nvxL INPUT

##### 添加规则
注意点：添加规则时，规则的顺序非常重要
在指定表的指定链的尾部添加一条规则，-A选项表示在对应链的末尾添加规则，省略-t选项时，表示默认操作filter表中的规则
命令语法：iptables -t 表名 -A 链名 匹配条件 -j 动作
示例：iptables -t filter -A INPUT -s 192.168.1.146 -j DROP


在指定表的指定链的首部添加一条规则，-I选型表示在对应链的开头添加规则
命令语法：iptables -t 表名 -I 链名 匹配条件 -j 动作
示例：iptables -t filter -I INPUT -s 192.168.1.146 -j ACCEPT

在指定表的指定链的指定位置添加一条规则
命令语法：iptables -t 表名 -I 链名 规则序号 匹配条件 -j 动作
示例：iptables -t filter -I INPUT 5 -s 192.168.1.146 -j REJECT

设置指定表的指定链的默认策略（默认动作），并非添加规则。
命令语法：iptables -t 表名 -P 链名 动作
示例：iptables -t filter -P FORWARD ACCEPT

##### 删除规则
注意点：如果没有保存规则，删除规则时请慎重
按照规则序号删除规则，删除指定表的指定链的指定规则，-D选项表示删除对应链中的规则。
命令语法：iptables -t 表名 -D 链名 规则序号
示例：iptables -t filter -D INPUT 3
上述示例表示删除filter表中INPUT链中序号为3的规则。

按照具体的匹配条件与动作删除规则，删除指定表的指定链的指定规则。
命令语法：iptables -t 表名 -D 链名 匹配条件 -j 动作
示例：iptables -t filter -D INPUT -s 192.168.1.146 -j DROP
上述示例表示删除filter表中INPUT链中源地址为192.168.1.146并且动作为DROP的规则。

删除指定表的指定链中的所有规则，-F选项表示清空对应链中的规则，执行时需三思。
命令语法：iptables -t 表名 -F 链名
示例：iptables -t filter -F INPUT

删除指定表中的所有规则，执行时需三思。
命令语法：iptables -t 表名 -F
示例：iptables -t filter -F


##### 修改规则
注意点：如果使用-R选项修改规则中的动作，那么必须指明原规则中的原匹配条件，例如源IP，目标IP等。

修改指定表中指定链的指定规则，-R选项表示修改对应链中的规则，使用-R选项时要同时指定对应的链以及规则对应的序号，并且规则中原本的匹配条件不可省略。
命令语法：iptables -t 表名 -R 链名 规则序号 规则原本的匹配条件 -j 动作
示例：iptables -t filter -R INPUT 3 -s 192.168.1.146 -j ACCEPT
上述示例表示修改filter表中INPUT链的第3条规则，将这条规则的动作修改为ACCEPT， -s 192.168.1.146为这条规则中原本的匹配条件，如果省略此匹配条件，修改后的规则中的源地址可能会变为0.0.0.0/0。

其他修改规则的方法：先通过编号删除规则，再在原编号位置添加一条规则。

修改指定表的指定链的默认策略（默认动作），并非修改规则，可以使用如下命令。
命令语法：iptables -t 表名 -P 链名 动作
示例：iptables -t filter -P FORWARD ACCEPT
上例表示将filter表中FORWARD链的默认策略修改为ACCEPT

 

##### 保存规则
保存规则命令如下，表示将iptables规则保存至/etc/sysconfig/iptables文件中，如果对应的操作没有保存，那么当重启iptables服务以后
service iptables save
注意点：centos7中使用默认使用firewalld，如果想要使用上述命令保存规则，需要安装iptables-services。

或者使用如下方法保存规则
iptables-save > /etc/sysconfig/iptables
可以使用如下命令从指定的文件载入规则，注意：重载规则时，文件中的规则将会覆盖现有规则。
iptables-restore < /etc/sysconfig/iptables

### iptables匹配条件
当规则中同时存在多个匹配条件时，多个条件之间默认存在"与"的关系，即报文必须同时满足所有条件，才能被规则匹配。

##### 基本匹配条件总结
-s用于匹配报文的源地址,可以同时指定多个源地址，每个IP之间用逗号隔开，也可以指定为一个网段。

```sh
iptables -t filter -I INPUT -s 192.168.1.111,192.168.1.118 -j DROP
iptables -t filter -I INPUT -s 192.168.1.0/24 -j ACCEPT
iptables -t filter -I INPUT ! -s 192.168.1.0/24 -j ACCEPT
```

-d用于匹配报文的目标地址,可以同时指定多个目标地址，每个IP之间用逗号隔开，也可以指定为一个网段。

```sh
iptables -t filter -I OUTPUT -d 192.168.1.111,192.168.1.118 -j DROP
iptables -t filter -I INPUT -d 192.168.1.0/24 -j ACCEPT
iptables -t filter -I INPUT ! -d 192.168.1.0/24 -j ACCEPT
```

-p用于匹配报文的协议类型,可以匹配的协议类型tcp、udp、udplite、icmp、esp、ah、sctp等（centos7中还支持icmpv6、mh）。

```sh
iptables -t filter -I INPUT -p tcp -s 192.168.1.146 -j ACCEPT
iptables -t filter -I INPUT ! -p udp -s 192.168.1.146 -j ACCEPT
```

-i用于匹配报文是从哪个网卡接口流入本机的，由于匹配条件只是用于匹配报文流入的网卡，所以在OUTPUT链与POSTROUTING链中不能使用此选项。

```sh
iptables -t filter -I INPUT -p icmp -i eth4 -j DROP
iptables -t filter -I INPUT -p icmp ! -i eth4 -j DROP
```

-o用于匹配报文将要从哪个网卡接口流出本机，于匹配条件只是用于匹配报文流出的网卡，所以在INPUT链与PREROUTING链中不能使用此选项。

```sh
iptables -t filter -I OUTPUT -p icmp -o eth4 -j DROP
iptables -t filter -I OUTPUT -p icmp ! -o eth4 -j DROP
```

##### 扩展匹配条件

* tcp扩展模块

常用的扩展匹配条件如下：
-p tcp -m tcp --sport 用于匹配tcp协议报文的源端口，可以使用冒号指定一个连续的端口范围
-p tcp -m tcp --dport 用于匹配tcp协议报文的目标端口，可以使用冒号指定一个连续的端口范围

```sh
iptables -t filter -I OUTPUT -d 192.168.1.146 -p tcp -m tcp --sport 22 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m tcp --dport 22:25 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m tcp --dport :22 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m tcp --dport 80: -j REJECT
iptables -t filter -I OUTPUT -d 192.168.1.146 -p tcp -m tcp ! --sport 22 -j ACCEPT
```

* multiport扩展模块

常用的扩展匹配条件如下：
-p tcp -m multiport --sports 用于匹配报文的源端口，可以指定离散的多个端口号,端口之间用"逗号"隔开
-p udp -m multiport --dports 用于匹配报文的目标端口，可以指定离散的多个端口号，端口之间用"逗号"隔开

```sh
iptables -t filter -I OUTPUT -d 192.168.1.146 -p udp -m multiport --sports 137,138 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m multiport --dports 22,80 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m multiport ! --dports 22,80 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m multiport --dports 80:88 -j REJECT
iptables -t filter -I INPUT -s 192.168.1.146 -p tcp -m multiport --dports 22,80:88 -j REJECT
```

* iprange模块
包含的扩展匹配条件如下

--src-range：指定连续的源地址范围

--dst-range：指定连续的目标地址范围

```sh
iptables -t filter -I INPUT -m iprange --src-range 192.168.1.127-192.168.1.146 -j DROP
iptables -t filter -I OUTPUT -m iprange --dst-range 192.168.1.127-192.168.1.146 -j DROP
iptables -t filter -I INPUT -m iprange ! --src-range 192.168.1.127-192.168.1.146 -j DROP
```

* string模块
常用扩展匹配条件如下

--algo：指定对应的匹配算法，可用算法为bm、kmp，此选项为必需选项。

--string：指定需要匹配的字符串

```sh
iptables -t filter -I INPUT -p tcp --sport 80 -m string --algo bm --string "OOXX" -j REJECT
iptables -t filter -I INPUT -p tcp --sport 80 -m string --algo bm --string "OOXX" -j REJECT
```

time模块
常用扩展匹配条件如下

--timestart：用于指定时间范围的开始时间，不可取反

--timestop：用于指定时间范围的结束时间，不可取反

--weekdays：用于指定"星期几"，可取反

--monthdays：用于指定"几号"，可取反

--datestart：用于指定日期范围的开始日期，不可取反

--datestop：用于指定日期范围的结束时间，不可取反

```sh
iptables -t filter -I OUTPUT -p tcp --dport 80 -m time --timestart 09:00:00 --timestop 19:00:00 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 443 -m time --timestart 09:00:00 --timestop 19:00:00 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 80  -m time --weekdays 6,7 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 80  -m time --monthdays 22,23 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 80  -m time ! --monthdays 22,23 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 80  -m time --timestart 09:00:00 --timestop 18:00:00 --weekdays 6,7 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 80  -m time --weekdays 5 --monthdays 22,23,24,25,26,27,28 -j REJECT
iptables -t filter -I OUTPUT -p tcp --dport 80  -m time --datestart 2017-12-24 --datestop 2017-12-27 -j REJECT
```

* connlimit 模块
常用的扩展匹配条件如下

--connlimit-above：单独使用此选项时，表示限制每个IP的链接数量。

--connlimit-mask：此选项不能单独使用，在使用--connlimit-above选项时，配合此选项，则可以针对"某类IP段内的一定数量的IP"进行连接数量的限制，如果不明白可以参考上文的详细解释。

```sh
iptables -I INPUT -p tcp --dport 22 -m connlimit --connlimit-above 2 -j REJECT
iptables -I INPUT -p tcp --dport 22 -m connlimit --connlimit-above 20 --connlimit-mask 24 -j REJECT
iptables -I INPUT -p tcp --dport 22 -m connlimit --connlimit-above 10 --connlimit-mask 27 -j REJECT
```

* limit模块
常用的扩展匹配条件如下

--limit-burst：类比"令牌桶"算法，此选项用于指定令牌桶中令牌的最大数量，上文中已经详细的描述了"令牌桶"的概念，方便回顾。

--limit：类比"令牌桶"算法，此选项用于指定令牌桶中生成新令牌的频率，可用时间单位有second、minute 、hour、day。

```sh
#注意，如下两条规则需配合使用
iptables -t filter -I INPUT -p icmp -m limit --limit-burst 3 --limit 10/minute -j ACCEPT
iptables -t filter -A INPUT -p icmp -j REJECT
```

[更多参考](http://www.zsythink.net/archives/tag/iptables/)


未完待续