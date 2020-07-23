



[freeradius官网](https://freeradius.org/)

[freeradius的github](https://github.com/FreeRADIUS/freeradius-server)

[安装办法](https://github.com/FreeRADIUS/freeradius-server/blob/master/doc/antora/modules/installation/pages/index.adoc)

[非源码安装](https://networkradius.com/freeradius-packages/)

例如ubuntu：

For Bionic Beaver (18.04), add to your apt source list (/etc/apt/sources.list):

```bash
deb http://packages.networkradius.com/releases/ubuntu-bionic bionic main
```

```shell
sudo apt-key adv --keyserver keys.gnupg.net --recv-key 0x41382202
sudo apt-get update
sudo apt-get install freeradius
```

启动服务：`/etc/init.d/freeradius start`

调试启动：`freeradius -X`

源码安装：

`git clone https://github.com/FreeRADIUS/freeradius-server.git`

进入目录

切换到3.0版本

git checkout -b git checkout -b release_3_0_20

git pull

执行

`./configure`

发现少了两个依赖，一次安装。

`sudo apt-get install libtalloc-dev`

`sudo apt-get install libkqueue-dev`

make 

sudo make install

使用ubtuntu的apt-get方式来安装freeradius的位置会和源码不同、源码安装的默认位置是

/usr/local/etc/raddb/

而使用ubuntu的apt-get方式的配置文件则安置在

/etc/freeradius/

官方给的简单测试方式：

 然后修改/etc/freeradius/下的users文件把这段注释去掉 

```shell
steve   Cleartext-Password := "testing"
    Service-Type = Framed-User,
    Framed-Protocol = PPP,
    Framed-IP-Address = 172.16.3.33,
    Framed-IP-Netmask = 255.255.255.0,
    Framed-Routing = Broadcast-Listen,
    Framed-Filter-Id = "std.ppp",
    Framed-MTU = 1500,
    Framed-Compression = Van-Jacobsen-TCP-IP
```

执行`freeradius -X`

在另一个终端：`radtest testing localhost 1812 testing123`

#### 其他配置方案测试：

```bash
## vi users 用户配置
#两个字符串分别是验证时输入的身份和密码
"hzlarm" Cleartext-Password := "hzlarm123"

 
## clients.conf 配置客户端的密码以下是默认的,本机测试，配置这个点即可：client localhost 
 secret      = testing123
##如果是联网测试，往下找类似字段进行修改，指定的外网ip以及设定一个密码。
##这个密码是配置fitap时的密码，同样要输入的是radius服务器的ip与端口。这ip不清楚地话可以随意设置，
##等开启freeradius -X以及配置好fitap指向radius，服务器端会报错忽略某某ip，然后填入这个ip即可。
##设置为0.0.0.0/0任何ip都可以
client private-network-1 {
       ipaddr          = 113.87.99.12/24
       secret          = testing123

 
## etc/raddb/sites-enabled/default or etc/freeradius/sites-enabled/default
## 配置验证和授权的方式，计费可不考虑，这次不测是到这个点；确认开启了以下几个方式
pap
eap
chap
mschap
# 其中 authorize 字段下 filter_username 代表验证身份与密码
 
```

##### pap： 

`radtest hzlarm hzlarm123 127.0.0.1 1812 testing123`

##### eap-md5：

```shell
#   radeapclient -x 127.0.0.1 auth testing123 < eap-md5.txt
#	以下内容写在eap-md5.txtf文件

User-Name = "hzlarm "
Cleartext-Password = "hzlarm123"
EAP-Code = Response
EAP-Id = 210
EAP-Type-Identity = "ufiletest"
Message-Authenticator = 0x00
```



#####  peap-mschapv2： 

```bash
#   eapol_test -c peap-mschapv2.conf -s testing123
#	以下内容写在peap-mschapv2.conf文件

network={
        ssid="example"
        key_mgmt=WPA-EAP
        eap=PEAP
        identity="hzlarm"
        anonymous_identity="anonymous"
        password="hzlarm123"
        phase2="autheap=MSCHAPV2"

#  Uncomment the following to perform server certificate validation.
#  ca_cert="/etc/freeradius/certs/ca.der"
}
```



 安装测试工具eapol_test 

```shell
cd /usr/local/src/
wget https://w1.fi/releases/wpa_supplicant-2.9.tar.gz
tar -xzvf wpa_supplicant-2.9.tar.gz
cd wpa_supplicant-2.9/wpa_supplicant/
cp defconfig .config
make eapol_test
#报错执行
#sudo apt-get install libdbus-1-dev
#sudo apt-get install libnl-3-dev libnl-genl-3-200 libnl-genl-3-dev libnl-idiag-3-dev
cp eapol_test /usr/local/bin/
```



#####  eap-tls: 

```bash
# 	sudo eapol_test -c eap-tls.conf -a 127.0.0.1 -p 1812 -s testing123 -r 1
# 	以下内容写在eap-tls.conf文件

network={
    eap=TLS
    eapol_flags=0
    key_mgmt=IEEE8021X
    identity="hzlarm"
    password="hzlarm123"

    # client 
    #ca_cert="/etc/freeradius/certs/ca.pem"
    #client_cert="/etc/freeradius/certs/client.pem"
    #private_key="/etc/freeradius/certs/client.key"
    #private_key_passwd="whatever"

    # self cert client 
    ca_cert="/home/ubuntu/client_ssl/radius_client_zhengshu/251zhengshu/certs/ca.crt"
	client_cert="/home/ubuntu/client_ssl/radius_client_zhengshu/251zhengshu/certs/client.crt"
	private_key="/home/ubuntu/client_ssl/radius_client_zhengshu/251zhengshu/certs/client.key"
    private_key_passwd="whatever"
    anonymous_identity="anonymous"
    # server
    #ca_cert="/etc/freeradius/certs/ca.pem"
    #client_cert="/etc/freeradius/certs/server.pem"
    #private_key="/etc/freeradius/certs/server.key"
    #private_key_passwd="whatever"
}
```

#####  ttls-chap: 

```bash
#   eapol_test -c ttls-chap.conf -s testing123
#	以下内容写在ttls-chap.conf文件
network={
        ssid="example"
        key_mgmt=WPA-EAP
        eap=TTLS
        identity="hzlarm"
        anonymous_identity="anonymous"
        password="hzlarm123"
        phase2="auth=CHAP"

#  Uncomment the following to perform server certificate validation.
#		ca_cert="/etc/freeradius/certs/ca.der"
}
```



#####  ttls-eapmd5: 

```bash
#
#   eapol_test -c ttls-eapmd5.conf -s testing123
#
network={
        ssid="example"
        key_mgmt=WPA-EAP
        eap=TTLS
        identity="hzlarm"
        anonymous_identity="anonymous"
        password="hzlarm123"
        phase2="autheap=MD5"

#  Uncomment the following to perform server certificate validation.
#		ca_cert="/etc/freeradius/certs/ca.der"
}
```



#####  ttls-mschapv2:

```bash
#
#   eapol_test -c ttls-mschapv2.conf -s testing123
#
network={
    ssid="example"
    key_mgmt=WPA-EAP
    eap=TTLS
    identity="hzlarm"
    anonymous_identity="anonymous"
    password="hzlarm123"
    phase2="autheap=MSCHAPV2"

    #  Uncomment the following to perform server certificate validation.
    #ca_cert="/etc/freeradius/certs/ca.pem"
}
```



#####  ttls-pap: 

```bash
#
#   eapol_test -c ttls-pap.conf -s testing123
#
network={
        ssid="example"
        key_mgmt=WPA-EAP
        eap=TTLS
        identity="hzlarm"
        anonymous_identity="anonymous"
        password="hzlarm123"
        phase2="auth=PAP"
 
#  Uncomment the following to perform server certificate validation.
#		ca_cert="/etc/freeradius/certs/ca.der"
}
```



```bash
#eap的配置文件，默认tls，ttls,peap都包含，不需要的可以把相应的字段注释掉即可。
## /etc/raddb/eap.conf or/etc/freeradius/mods-available/eap

# -*- text -*-
##
##  eap.conf -- Configuration for EAP types (PEAP, TTLS, etc.)
##
##      $Id$


eap {
    #eap未指定时，默认的类型。
    default_eap_type = peap
    #default_eap_type = ttls
    #default_eap_type = tls

    #关联EAP请求数据包的列表，超时会被删除。
    timer_expire     = 60

    #是否忽略不支持的eap请求。
    ignore_unknown_eap_types = no

    # Cisco 用户名bug
    cisco_accounting_username_bug = no

    #限制服务器正在跟踪的会话数，有助于防止DoS攻击。此命令取自radiusdus.conf中的“max_requests”指令。
    max_sessions = ${max_requests}

    # Supported EAP-types
    ## EAP-TLS
    tls {
        #
        #  These is used to simplify later configurations.
        #
        certdir = ${confdir}/certs
        cadir = ${confdir}/certs

        #private_key_password = whatever
        private_key_file = ${certdir}/srv.key

        certificate_file = ${certdir}/srv.crt

        CA_file = ${cadir}/ca.crt

        #
        #  For DH cipher suites to work, you have to
        #  run OpenSSL to create the DH file first:
        #
        #       openssl dhparam -out certs/dh 1024
        #
        dh_file = ${certdir}/dh
        random_file = /dev/urandom

        #       fragment_size = 1024
        #       include_length = yes
        #       check_crl = yes

        #       check_all_crl = yes

        CA_path = ${cadir}

        #       check_cert_issuer = "/C=GB/ST=Berkshire/L=Newbury/O=My Company Ltd"
        #       check_cert_cn = %{User-Name}
        cipher_list = "DEFAULT"
        #       virtual_server = check-eap-tls

        #使用freeradius -X调试时,默认使用该命令生成证书。
        make_cert_command = "${certdir}/bootstrap"
        ecdh_curve = "prime256v1"
        cache {
            enable = no
            lifetime = 24 # hours
            max_entries = 255
        }
        verify {
            #tmpdir = /tmp/radiusd
            #client = "/path/to/openssl verify -CApath ${..CA_path} %{TLS-Client-Cert-Filename}"
        }
        ocsp {
            enable = no
            override_cert_url = yes
            url = "http://127.0.0.1/ocsp/"
        }
    }

    #PEAP模块需要安装TLS模块并进行配置，以便使用TLS隧道在EAP数据包内。TTLS不需要客户端证书
    #  You can make PEAP require a client cert by setting
    #       EAP-TLS-Require-Client-Cert = Yes
    peap {
        default_eap_type = mschapv2
        copy_request_to_tunnel = no
        use_tunneled_reply = no
        #       proxy_tunneled_request_as_eap = yes
        virtual_server = "inner-tunnel"
        #      soh = yes
        #      soh_virtual_server = "soh-server"
    }
    
    #TTLS模块需要安装TLS模块并进行配置，以便使用TLS隧道在EAP数据包内。TTLS不需要客户端证书
    #  You can make TTLS require a client cert by setting
    #       EAP-TLS-Require-Client-Cert = Yes
    ttls {
        default_eap_type = md5 
        # allowed values: {no, yes}
        copy_request_to_tunnel = no
        # allowed values: {no, yes}
        use_tunneled_reply = no

        virtual_server = "inner-tunnel"
        #       include_length = yes
    }   

    #
    #  This takes no configuration.
    #
    mschapv2 {
    # send_error = no
    }
    md5 {
    }
    gtc{
    }
}


```





