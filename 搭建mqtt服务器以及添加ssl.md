### 自己搭建mqtt服务器

[mosquitto](https://mosquitto.org/download/)是 一款实现了消息推送)协议 MQTT v3.1 的开源消息代理软件，提供轻量级的，支持可发布/可订阅的

的消息推送模式，使设备对设备之间的短消息通信变得简单，比如现在应用广泛的低功耗传感器，手机、嵌入式计

算机、微型控制器等移动设备。 

官网有各种安装方式教程，这里安装在ubuntu18.04中采用[ppa]( https://blog.csdn.net/hzlarm/article/details/99486804 )方式： [mosquitto-dev PPA](https://launchpad.net/~mosquitto-dev/+archive/mosquitto-ppa/) 。

执行  

```sh
sudo apt-add-repository ppa:mosquitto-dev/mosquitto-ppa
sudo apt-get update
sudo apt-get install mosquitto 
```

安装完毕后会自动运行。默认端口号为1883。

就可以使用了。

如何在使用mosquito SSL时配置自签名证书

### 为了安全起见，使用openssl生成根证书.

自己生成的证书不被有权威的CA根证书信任

##### 生成自签名CA根证书 

* 生成密钥使用des3加密rsa的 private key，生成2048 位密码:

  ​	`openssl genrsa -des3 -out ca.key 2048` 

* 用上面的密钥给 CA 根证书加密:	

  `openssl req -new -x509 -days 3650 -key  ca.key -out  ca.crt` 

or 一条命令直接生成：

`openssl req -new -x509 -days 3650 -key  ca.key -out  ca.crt -subj "/C=CN/ST=GuangDong/L=ShenZhen/O=Company/OU=Gateway/CN=Root CA/"`



##### 服务器

生成服务器的证书，使用上面生成的CA证书给MQTT broker代理服务器的证书签名: 	

* 生成服务器端的key

  `openssl genrsa -out server.key 2048`

* 生成 csr 文件: 	

  `openssl req -new -out server.csr -key server.key`

or一条命令直接生成：

`openssl req -new -out   server.csr -key   server.key -subj "/C=CN/ST=GuangDong/L=ShenZhen/O=Server/OU=Gateway/CN=localhost"`

* 签名生成crt

`openssl x509 -req -in   server.csr -CA  ca.crt -CAkey  ca.key -CAcreateserial -out   server.crt -days 3650`

##### 客户端

* 生成客户端的key

`openssl genrsa -out  client.key 2048`

* 生成 csr 文件: 	

`openssl req -new -out  client.csr -key  client.key -subj "/C=CN/ST=GuangDong/L=ShenZhen/O=Server/OU=Gateway/CN=client cert"`

* 签名生成crt

`openssl x509 -req -in  client.csr -CA  ca.crt -CAkey  ca.key -CAcreateserial -out  client.crt -days 3650`

##### 报错解决

`Can't load /home/xxxx/.rnd into RNG`

 `cd /xxxx`
`openssl rand -writerand .rnd` 

[https://jamielinux.com/docs/openssl-certificate-authority/introduction.html ](https://jamielinux.com/docs/openssl-certificate-authority/introduction.html )

##### 使用证书

生成的文件：

`ca.crt  ca.key  ca.srl  client.crt  client.csr  client.key  server.crt  server.csr  server.key`

mosquitto服务器配置文件修改

```shell
#vi /etc/mosquitto/mosquitto.conf
pid_file /var/run/mosquitto.pid

persistence true
persistence_location /var/lib/mosquitto/

log_dest file /var/log/mosquitto/mosquitto.log

#以下为添加内容
#################################################
port 1883
bind_address 0.0.0.0
sys_interval 1
listener 8883 0.0.0.0
#capath
cafile /etc/mosquitto/ca_certificates/ca.crt

#Path to the PEM encoded server certificate
certfile /etc/mosquitto/certs/server.crt

#Path to the PEM encoded keyfile
keyfile /etc/mosquitto/certs/server.key
#################################################

include_dir /etc/mosquitto/conf.d
```

添加：将生成的文件拷贝到配置文件所写的对应的位置。

将客户端对应的`ca.crt		client.crt		client.key`分别添加到客户端。以及生成ca.ky时的密码。

















