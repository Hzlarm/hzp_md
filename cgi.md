### 在uHTTPd下使用bash shell编写cgi

#### 什么是[uHTTPd](https://openwrt.org/zh-cn/doc/howto/http.uhttpd )

 **uHTTPd** 是一个 OpenWrt/LUCI 开发者从头编写的 Web 服务器。 它着力于实现一个稳定高效的服务器，能够满足嵌入式设备的轻量级任务需求，且能够与 OpenWrt 的配置框架 (UCI) 整合。默认情况下它被用于 OpenWrt 的 Web 管理接口 [LuCI](https://openwrt.org/zh/docs/techref/luci)。当然，uHTTPd 也能提供一个常规 Web 服务器所需要的所有功能。  它的 UCI 配置文件为 `/etc/config/uhttpd` 

#### 参考文档

 [Bash CGI](https://oinkzwurgl.org/hacking/bash_cgi/) 

 [Web CGI with Bash Script](http://www.yolinux.com/TUTORIALS/BashShellCgi.html) 

 [PostMan Tester](https://www.getpostman.com/docs/) 

#### 测试

`uHTTPd passes ‘GET’ paramter to bash by '$QUERY_STRING’`

`uHTTPd passes ‘POST’ conent to bash by STDIN, so bash use ‘POST_STRING=$(cat)’ to get them `

`vi /www/cgi-bin/test.cgi `

```bash
#!/bin/sh                    
POST_STRING=$(cat)                    
echo "Content-type: application/json" 
echo    
echo POST_STRING = $POST_STRING
echo SERVER_SOFTWARE = $SERVER_SOFTWARE #服务器软件
echo SERVER_NAME = $SERVER_NAME         #服务器主机名
echo GATEWAY_INTERFACE = $GATEWAY_INTERFACE    #CGI版本
echo SERVER_PROTOCOL = $SERVER_PROTOCOL  #通信使用的协议
echo SERVER_PORT = $SERVER_PORT         #服务器的端口号
echo REQUEST_METHOD = $REQUEST_METHOD   #请求方法(GET/POST/PUT/DELETE..)
echo HTTP_ACCEPT = $HTTP_ACCEPT         #HTTP定义的浏览器能够接受的数据类型
echo SCRIPT_NAME = $SCRIPT_NAME         #当前运行的脚本名称(包含路径)
echo QUERY_STRING = $QUERY_STRING       #地址栏中传的数据（get方式）url中?后面
echo REMOTE_ADDR = $REMOTE_ADDR         #客户端的ip
echo .............................
echo SERVER_INTERFACE = $SERVER_INTERFACE	#WWW服务器的类型，如：CERN型或NCSA型。
echo HTTP_REFERER = $HTTP_REFERER	#发送表单的文件URL。（并非所有的浏览器都传送这一变量）
echo HTTP_USER-AGENT = $HTTP_USER-AGENT	#发送表单的浏览的有关信息。
echo GETWAY_INTERFACE = $GETWAY_INTERFACE	#CGI程序的版本，在UNIX下为 CGI/1.1。
echo PATH_TRANSLATED = $PATH_TRANSLATED	#PATH_INFO中包含的实际路径名。
echo PATH_INFO = $PATH_INFO	#浏览器用GET方式发送数据时的附加路径。
echo REMOTE_HOST = $REMOTE_HOST	#发送程序的主机名，不能确定该值。
echo REMOTE_USER = $REMOTE_USER	#发送程序的人名。
echo CONTENT_TYPE = $CONTENT_TYPE	#POST发送，一般为application/xwww-form-urlencoded。
echo CONTENT_LENGTH = $CONTENT_LENGTH	#POST方法输入的数据的字节数。
echo POST_STRING = $POST_STRING	#
```

```bash
#!/bin/ash 

echo "Content-type: text/html" 
echo ""

echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>Environment Variables</title>'
echo '</head>'
echo '<body>'
echo '<h1> Environment Variables: </h1>'
echo '<pre>'
/usr/bin/env
echo '</pre>'
echo '</body>'
echo '</html>'

exit 0
```

