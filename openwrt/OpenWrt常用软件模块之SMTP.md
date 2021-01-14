## OpenWrt 常用软件模块之SMTP

### SMTP简介

- SMTP（Simple Mail Transfer Protocol）即**简单邮件传输协议**，它是用于由源地址到目 的地址传送邮件的传输协议，由它来控制电子邮件的传输方式
- SMTP协议**建立在TCP协议之上**，它帮助每台计算机在发送或中转信件时找到目的地址
- 路由器**通过SMTP协议所指定的服务器，**就可以把电子邮件寄到收信人的服务器上

### 邮件的格式

- 邮件的内容格式：包含邮件**消息头和消息体**，消息头和消息体之间**由一个空行分隔**

### sSMTP软件包

- OpenWrt使用sSMTP 软件包来支持邮件发送。sSMTP是一个简单的**邮件发送客户端**， 它不需要一个后台进程，不能接收邮件**仅可以发送邮件**

>  ①在系统中安装
>
> - 通过以下命令进行安装：
>
`opkg update opkg install ssmtp`
>
> - 在安装完成后 sSMTP 会链接到 sendmail，配置文件会安装到以下位置
>
>   ` /etc/ssmtp/ssmtp.conf /etc/ssmtp/revaliases`
>  ②在编译源码时安装
>
> - sSMTP 并不会默认选择编译，首先将 sSMTP 软件包从可选仓库中加入到选择列表中
>
> `./scripts/feeds install ssmtp`
> 
> - 然后在make nenuconfig时，通过“Mail→ssmtp”进行选择
>
>   ` < > ssmtp.................. A minimal and secure mail sender with ssl support   `
>
> - sSMTP编译脚本位于package/feeds/packages/ssmtp目录下，编译完成后的软件包名称为ssmtp
>

### ssmtp命令格式

- 发送命令接口格式如下：

```
ssmtp [ flags ] 目的地址 < file
```

- **选项如下：**
  - -t：从消息内容中读取目的接收者
  - -v：详细输出程序执行步骤
  - -au username：指定 SMTP 认证用户名
  - -ap password：指定 SMTP 认证密码
  - -Cfile：不读取默认配置，使用指定配置文件

### 演示案例

- 如下所示的是一个示例邮件内容（msg.txt），包含收件人和抄送收件人，邮件主题为“Hello OpenWrt route”，邮件消息头和邮件内容之间有一个空行，最后是邮件正文

```
To:zyz323@163.comCC:zyz323@sohu.comSubject: Hello OpenWrt route test. Hello Openwrt bjbook.net
```

- 在发送邮件之前，我们需要**配置邮件账户和服务器信息：**

```
echo "mainhub=smtp.163.com" >> /etc/ssmtp/ssmtp.conf echo "rewriteDomain=163.com" >> /etc/ssmtp/ssmtp.conf echo "root:zyz323@163.com:smtp.163.com" >> /etc/ssmtp/revaliases
```

- 写好邮件之后我们使用命令来发送邮件，发送命令接口格式如下：（请替换为实际的账号和密码）

```
ssmtp -f username au username@163.com -ap password -s zyz323@163.com -v <msg.txt
```