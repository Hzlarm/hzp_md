

### OSI，TCP/IP，五层协议的体系结构

##### 网络层次划分

![](E:\gateway_git\openwrt-database\note\hzp\pic\网络层次划分.jpg)

#####  **每层对应的功能及协议**

|                      | 功能                                                         | 常见                            | 协议                                                         |
| -------------------- | ------------------------------------------------------------ | ------------------------------- | ------------------------------------------------------------ |
| 物理层(比特Bit)      | 设备间接收或发送比特流；说明电压、线速和线缆等。             | 中继器、网线、集线器、HUB等     | RJ45、CLOCK、IEEE802.3等                                     |
| 数据链路层(帧Frame)  | 将比特组合成字节，进而组合成帧；用MAC地址访问介质；错误可以被发现但不能被纠正。 | 网卡、网桥、二层交换机等        | PPP、FR、HDLC、VLAN、MAC等                                   |
| 网络层(数据包Packet) | 负责数据包从源到宿的传递和网际互连                           | 路由器、多层交换机、防火墙等    | IP(因特网互联协议)、ICMP(因特网控制报文协议)、ARP(地址解析协议)、PARP(逆地址解析协议)、OSPF、IPX、RIP、IGRP等 |
| 传输层               | 可靠或不可靠数据传输；数据重传前的错误纠正。                 | 进程、端口（socket）            | TCP协议（Transmission Control Protocol，传输控制协议）、UDP协议（User Datagram Protocol，用户数据报协议）、SPX |
| 会话层               | 保证不同应用程序的数据独立；建立、管理和终止会话。           | 服务器验证用户登录、断点续传    | NFS、SQL、NetBIOS、RPC                                       |
| 表示层               | 数据表示；加密与解密、数据的压缩与解压缩、图像编码与解码等特殊处理过程 | URL加密、口令加密、图片编解码等 | JPEG、MPEG、ASCII                                            |
| 应用层               | 用户接口                                                     | --                              | FTP(文件传输协议）、DNS(域名解析协议)、Telnet(远程登陆协议)、SNMP、SMTP(邮件传送协议)、HTTP(超文本传输协议)、WWW、NFS等 |

**注明：ARP和RAPR两个到底属于哪一层呢？**

​     由于IP协议使用了ARP协议，所以经常把ARP协议划到网络层，但是ARP协议是为了从网络层使用的IP地址解析出在数据链路层使用的MAC地址，所以有些地方也把ARP协议划分到数据链路层，但是一般情况下，我们还是把ARP和RARP协议划分到网络层。

​     这个没有明确的界限，不用太过纠结。



  ### OSI七层网络模型

TCP/IP协议是互联网的基础协议，没有它就根本不可能上网，任何和互联网有关的操作都离不开TCP/IP协议。不管是OSI七层模型还是TCP/IP的四层、五层模型，每一层中都有自己的专属协议，完成自己相应的工作以及与上下层级之间进行沟通 。 TCP/IP不是一个协议，而是一个协议族的统称。里面包括IP协议、IMCP协议、TCP协议。 

##### 应用层

 应用层是操作系统或网络应用程序提供访问网络服务的接口。 

##### 表示层

表示层对上层数据或信息进行变换，保证一个主机应用层信息可以被另一个主机的应用程序理解。表示层的数据转换包括数据的加密、压缩、格式转换等。

##### 会话层

会话层管理主机之间的会话进程，负责建立、管理、终止进程之间的会话。会话层还利用在数据中插入校验点来实现数据的同步。

**对应四层模型五层模型中的应用层**： 数据传输基本单位为**报文** 。

##### 传输层

运输层协议的首要任务是提供进程到进程的通信。本地主机与远程主机是通过IP地址定义的，进程是端口号定义的。熟知端口`0~1023`，注册端口`1024~49151`，动态端口`49152~65535`。所谓的socket address 套接字地址就是IP地址与端口号的组合。

 第一个端到端（主机到主机）的层次。**传输层负责将上层数据分段并提供端到端的、可靠的或不可靠的传输。此外，传输层还要处理端到端的差错控制和流量控制问题**。 

传输层的任务是根据通信子网的特性，利用最佳的网络资源，为两个端系统的会话层之间提供建立、维护和取消传输连接的功能，负责端到端的可靠数据传输。在这一层，信息传送的协议数据单元称为段或报文。

网络层只是根据网络地址将源结点发出的数据包传送到目的结点，而传输层则负责将数据可靠地传送到相应地端口。

##### 网络层

网络层的目的是实现两端系统之间的数据透明传送，具体功能包括寻址和路由选择、连接的建立、保持和终止等。它提供的服务使传输层不需要了解网络中的数据传输和交换技术。用少量的词来记忆网络层，那就是“路径选择，路由及逻辑寻址”。

网络层涉及众多的协议，其中包括最重要的协议，也是TCP/IP的核心协议——IP协议。IP协议仅仅提供不可靠、无连接的传送服务。IP协议的主要功能有：无连接数据报传输、数据报路由选择和差错控制。与IP协议配套使用实现其功能的还有地址解析协议ARP、逆地址解析协议RARP、因特网报文协议ICMP、因特网组管理协议IGMP。
##### 数据链路层
数据链路层在物理层提供的服务的基础上再向网络层提供服务，最基本的服务是将原子网络层来的数据可靠地传输到相邻结点的目标机网络层，为达到这一目的，数据链路必须具备一系列相应的功能，主要有：如何将数组合成数据块，在数据链路层中这种数据块为帧（frame），帧是数据链路层的传送单位；如何控制帧再物理信道上的传输，包括如何处理传输差错，如何调节发送速率以使与接收方相匹配；以及在两个网络实体之间提供数据链路通路的建立、维持和释放的管理。数据链路层在不可靠的物理介质上提供可靠的传输。该层的作用包括：物理地址寻址、数据成帧、流量控制、数据检错、重发等。

##### 物理层

激活、维持、关闭通信端点之间的机械特性、电气特性、功能特性以及过程特性。该层为上层协议提供了一个传数据的可靠物理媒体。简单的说，物理层确保原始的数据可在各种物理媒体上传输。物理层记住两个重要的设备名称，中继器（Repeater，也叫放大器）和集线器

### IP协议

 剖析IP协议，大部分时间就是深入剖析IP头部协议 。[参考自]( https://blog.csdn.net/qq_42058590/article/details/82918678 )

![](E:\gateway_git\openwrt-database\note\hzp\pic\IP数据报格式.png)



 在IP协议中，IP协议是面向非连接的，所谓的非连接就是在数据的传递过程中，不需要检测网络是否连通，所以是不可靠的数据报协议。IP协议主要用于在主机之间的寻址和选择数据包路由。  IP协议头当中，最重要的就是生存时间TTL（IP允许通过的最大网段数量）字段（八位），规定该数据包能穿过几个路由之后才会被抛弃。 



ip协议是不可靠的、无连接的网络协议。

不可靠是指它不提供段对端或者逐跳的确认机制，不保证数据包成功传输到对端，其可靠性由上层来保证。

无连接是指ip报文不保存后续报文信息。

IP协议的二个功能：寻址和分片

IP协议使用4个主要机制来提供服务：服务类型，生存时间，选项和校验和。



#### TCP/IP的三次握手，四次挥手

TCP报文段，[copy自](https://blog.csdn.net/qq_38950316/article/details/81087809)

![](E:\gateway_git\openwrt-database\note\hzp\pic\TCP报文.jpg)



重要的标志位。

F : FIN - 结束; 结束会话，释放一个连接。

S : SYN -  请求建立连接，并在其序列号的字段进行序列号的初始值设定。建立连接，设置为1 

R : RST - 复位;中断一个连接。重置连接

P : PUSH -  提示接收端应用程序立即从TCP缓冲区把数据读走。 

A : ACK - 应答，确认序号有效

U : URG -  紧急指针是否有效。为1，表示某一位需要被优先处理 

 序列号seq：占4个字节，用来标记数据段的顺序，TCP把连接中发送的所有数据字节都编上一个序号，第一个字节的编号由本地随机产生；给字节编上序号后，就给每一个报文段指派一个序号；序列号seq就是这个报文段中的第一个字节的数据编号。

确认号ack：占4个字节，期待收到对方下一个报文段的第一个数据字节的序号；序列号表示报文段携带数据的第一个字节的编号；而确认号指的是期望接收到下一个字节的编号；因此当前报文段最后一个字节的编号+1即为确认号。
确认ACK：占1位，仅当ACK=1时，确认号字段才有效。ACK=0时，确认号无效
同步SYN：连接建立时用于同步序号。当SYN=1，ACK=0时表示：这是一个连接请求报文段。若同意连接，则在响应报文段中使得SYN=1，ACK=1。因此，SYN=1表示这是一个连接请求，或连接接受报文。SYN这个标志位只有在TCP建产连接时才会被置1，握手完成后SYN标志位被置0。
终止FIN：用来释放一个连接。FIN=1表示：此报文段的发送方的数据已经发送完毕，并要求释放运输连接
PS：ACK、SYN和FIN这些大写的单词表示标志位，其值要么是1，要么是0；ack、seq小写的单词表示序号。

##### 三次握手

![](E:\gateway_git\openwrt-database\note\hzp\pic\三次握手.png)



第一次握手：建立连接时，客户端发送syn包（syn=x）到服务器，并进入SYN_SENT状态，等待服务器确认；SYN：同步序列编号（Synchronize Sequence Numbers）。

第二次握手：服务器收到syn包，必须确认客户的SYN（ack=x+1），同时自己也发送一个SYN包（syn=y），即SYN+ACK包，此时服务器进入SYN_RECV状态；

第三次握手：客户端收到服务器的SYN+ACK包，向服务器发送确认包ACK(ack=y+1），此包发送完毕，客户端和服务器进入ESTABLISHED（TCP连接成功）状态，完成三次握手。

##### 四次挥手

![](E:\gateway_git\openwrt-database\note\hzp\pic\四次挥手.png)



1）客户端进程发出连接释放报文，并且停止发送数据。释放数据报文首部，FIN=1，其序列号为seq=u（等于前面已经传送过来的数据的最后一个字节的序号加1），此时，客户端进入FIN-WAIT-1（终止等待1）状态。 TCP规定，FIN报文段即使不携带数据，也要消耗一个序号。
2）服务器收到连接释放报文，发出确认报文，ACK=1，ack=u+1，并且带上自己的序列号seq=v，此时，服务端就进入了CLOSE-WAIT（关闭等待）状态。TCP服务器通知高层的应用进程，客户端向服务器的方向就释放了，这时候处于半关闭状态，即客户端已经没有数据要发送了，但是服务器若发送数据，客户端依然要接受。这个状态还要持续一段时间，也就是整个CLOSE-WAIT状态持续的时间。
3）客户端收到服务器的确认请求后，此时，客户端就进入FIN-WAIT-2（终止等待2）状态，等待服务器发送连接释放报文（在这之前还需要接受服务器发送的最后的数据）。
4）服务器将最后的数据发送完毕后，就向客户端发送连接释放报文，FIN=1，ack=u+1，由于在半关闭状态，服务器很可能又发送了一些数据，假定此时的序列号为seq=w，此时，服务器就进入了LAST-ACK（最后确认）状态，等待客户端的确认。
5）客户端收到服务器的连接释放报文后，必须发出确认，ACK=1，ack=w+1，而自己的序列号是seq=u+1，此时，客户端就进入了TIME-WAIT（时间等待）状态。注意此时TCP连接还没有释放，必须经过2∗∗MSL（最长报文段寿命）的时间后，当客户端撤销相应的TCB后，才进入CLOSED状态。
6）服务器只要收到了客户端发出的确认，立即进入CLOSED状态。同样，撤销TCB后，就结束了这次的TCP连接。可以看到，服务器结束TCP连接的时间要比客户端早一些。

常见面试题
【问题1】为什么连接的时候是三次握手，关闭的时候却是四次握手？

答：因为当Server端收到Client端的SYN连接请求报文后，可以直接发送SYN+ACK报文。其中ACK报文是用来应答的，SYN报文是用来同步的。但是关闭连接时，当Server端收到FIN报文时，很可能并不会立即关闭SOCKET，所以只能先回复一个ACK报文，告诉Client端，"你发的FIN报文我收到了"。只有等到我Server端所有的报文都发送完了，我才能发送FIN报文，因此不能一起发送。故需要四步握手。

【问题2】为什么TIME_WAIT状态需要经过2MSL(最大报文段生存时间)才能返回到CLOSE状态？

答：虽然按道理，四个报文都发送完毕，我们可以直接进入CLOSE状态了，但是我们必须假象网络是不可靠的，有可以最后一个ACK丢失。所以TIME_WAIT状态就是用来重发可能丢失的ACK报文。在Client发送出最后的ACK回复，但该ACK可能丢失。Server如果没有收到ACK，将不断重复发送FIN片段。所以Client不能立即关闭，它必须确认Server接收到了该ACK。Client会在发送出ACK之后进入到TIME_WAIT状态。Client会设置一个计时器，等待2MSL的时间。如果在该时间内再次收到FIN，那么Client会重发ACK并再次等待2MSL。所谓的2MSL是两倍的MSL(Maximum Segment Lifetime)。MSL指一个片段在网络中最大的存活时间，2MSL就是一个发送和一个回复所需的最大时间。如果直到2MSL，Client都没有再次收到FIN，那么Client推断ACK已经被成功接收，则结束TCP连接。

【问题3】为什么不能用两次握手进行连接？

答：3次握手完成两个重要的功能，既要双方做好发送数据的准备工作(双方都知道彼此已准备好)，也要允许双方就初始序列号进行协商，这个序列号在握手过程中被发送和确认。

现在把三次握手改成仅需要两次握手，死锁是可能发生的。作为例子，考虑计算机S和C之间的通信，假定C给S发送一个连接请求分组，S收到了这个分组，并发 送了确认应答分组。按照两次握手的协定，S认为连接已经成功地建立了，可以开始发送数据分组。可是，C在S的应答分组在传输中被丢失的情况下，将不知道S 是否已准备好，不知道S建立什么样的序列号，C甚至怀疑S是否收到自己的连接请求分组。在这种情况下，C认为连接还未建立成功，将忽略S发来的任何数据分 组，只等待连接确认应答分组。而S在发出的分组超时后，重复发送同样的分组。这样就形成了死锁。

【问题4】如果已经建立了连接，但是客户端突然出现故障了怎么办？

TCP还设有一个保活计时器，显然，客户端如果出现故障，服务器不能一直等下去，白白浪费资源。服务器每收到一次客户端的请求后都会重新复位这个计时器，时间通常是设置为2小时，若两小时还没有收到客户端的任何数据，服务器就会发送一个探测报文段，以后每隔75秒钟发送一次。若一连发送10个探测报文仍然没反应，服务器就认为客户端出了故障，接着就关闭连接。



### ARP协议

 ARP(地址解析协议)。根据主机IP地址查询其网卡的MAC地址

把分组交付给主机或路由器需要有两级地址：逻辑地址(IP)网络级和物理地址(MAC)物理级。

逻辑地址到物理地址的映射可以是静态也可以是动态的。维护静态需要很大的开销。
ARP是一种动态映射方法，ARP请求用广播的方式发送给网络上的所有设备。ARP回答用单播方式发送给请求映射的主机。

ARP软件包的五个构件组成：高速缓存列表、队列、输出模块、输入模块以及高速缓存控制模块。 





### ICMP协议

ICMP是（Internet Control Message Protocol）网际控制报文协议

ICMP协议使用IP协议进行传输报文，是一种面向无连接的协议，用于报告传输出错以及控制信息。

ICMP总是把差错报文报告给最初的数据源。

一共有5种类型的差错要处理：终点不可达、源点抑制、超时、参数问题以及改变路由(重定向)。

ICMP差错报文一些要点：

* 对于携带ICMP差错报文的数据报，不再产生ICMP差错报文。
* 分片数据报对非第一个分片，不产生ICMP差错报文。
* 对于具有多播地址的数据报，不产生ICMP差错报文。
* 对于特殊地址(127.0.0.0或0.0.0.0)，不产生差错报文。

ICMP除了差错报文以外还能通过查询报文对网络问题进行诊断：

**回送请求**(echo-request)与**回送回答**(echo-reply)报文就是为了诊断而设计的，类型8请求0响应。可以被网络管理员用来检查IP协议的工作情况。也可以测试某个主机的可达性(Ping命令)。还有一种工具是traceroute。

ICMP报文有两种类型：差错报告报文和查询报文。差错报告报文报告路由器或主机在处理IP数据时可能遇到的问题。查询报文总是成对出现，帮助主机或管理员从某个路由器或对方主机获取特定信息。

### 传输层协议

TCP/UDP。路由器一般工作在IP层,不处理传输层协议。

#### UDP

用户数据报协议(User Datagram Protocol，UDP),位于应用层与IP层之间，它提供介于应用程序与网络功能之间的服务。

UDP是一种无连接、不可靠的运输协议，它除了在IP服务的基础上增加了进程到进程的通信之外，就再也没什么了。

UDP格式：`首部(8字节)+数据=8~65535字节`。

首部格式：源端口号(16)+目的端口号(16)+总长度(16)+检验和(16)。

因为UDP被封装在IP数据报(最大65535)之中，所以 **UDP长度 = IP长度 -IP首部长度**。

UDP报文长度小于65507字节(65535-8字节的UDP首部-20字节的IP首部)。

**检验和**

UDP检验和的计算与IP检验和不同。分为三部分：伪首部、UDP首部以及数据部分

伪首部是封装用户数据报的IP分组的首部的一部分：32位源IP地址+32位目的IP地址+8位全零+8位协议+16位UDP总长度。









