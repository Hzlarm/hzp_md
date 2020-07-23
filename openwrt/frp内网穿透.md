###  [frp官方带教程]( https://github.com/fatedier/frp/blob/master/README_zh.md )

frp 下载地址： [https://github.com/fatedier/frp/releases](https://github.com/fatedier/frp/releases)

分别下载 两个frp (根据操作系统与位数选择),一个在云服务器，一个在本地。

解压后都是以下文件：

```shell
frpc  frpc_full.ini  frpc.ini  frps  frps_full.ini  frps.ini  LICENSE  systemd
```

### 分别设置

##### 云服务器端下载的是 [frp_0.30.0_linux_amd64.tar.gz](https://github.com/fatedier/frp/releases/download/v0.30.0/frp_0.30.0_linux_amd64.tar.gz)


```bash
# vi frps.ini 
[pcommon]
bind_port = 7000
vhost_http_port = 8800 #这个端口号对应本地的端口号，因为80被博客占了所以改为8800
```
启动frps：	`./frps -c ./frps.ini`

##### 客户端下载的是 [frp_0.30.0_windows_amd64.zip](https://github.com/fatedier/frp/releases/download/v0.30.0/frp_0.30.0_windows_amd64.zip)

windows需要使用cmd运行。因为安装科git bash，所以使用git bash

```bash
[common]
server_addr = 106.53.21.193 #这个是云服务器的公网ip
server_port = 7000

[web01]
type = http
local_ip = 192.168.0.54 #本地的ip
local_port = 8800	#本地的端口号
#也就是通过192.168.0.54:8800就可以访问本地页面
custom_domains = hilili.xyz #这个是云服务器的公网域名
```

启动frpc：	`./frpc -c ./frpc.ini`

### 访问

拿起手机，在浏览器输入 `hilili.xyz:8800`即可访问本地的页面