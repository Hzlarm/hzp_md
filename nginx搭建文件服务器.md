### nginx搭建文件服务器

#### windows环境

##### 官网下载nginx

[http://nginx.org/en/download.html](http://nginx.org/en/download.html)

解压缩之后编辑`nginx-1.17.7\conf\nginx.conf`文件

在server部分添加以下内容

```bash
#在server中的servername下面添加
	root	E:\download; #指定目录所在路径	

#autoindex for nginx
	location ~ ^(.*)/$ {
        allow all;		
        autoindex       on;			#开启目录浏览
        autoindex_localtime on;		#以服务器的文件时间作为显示的时间
        autoindex_exact_size off; 	#切换为 off 后，以可读的方式显示文件大小，单位为 KB、MB 或者 GB
        charset utf-8,gbk; 		 	#展示中文文件名
        #这一段是为了美化界面，需要先下载插件然后添加以下这行配置,不嫌丑的话直接注释即可
        add_after_body /.autoindex/footer.html;
    }
#添加这一段，点击任何文件都是下载。
    location ~ ^/(.*)$ {
        add_header Content-Disposition "attachment; filename=$1";  
    }
```

保存后用cmd进入nginx目录执行:启动服务命令

`start nginx.exe`  	启动服务

`nginx.exe -s stop ` 	停止服务

`nginx.exe -s reload`		重新加载配置文件

在浏览器输入`localhost`回车。界面略丑.



美化界面：

[下载插件](https://github.com/Hzlarm/autoindex.git)

只需要将里面的`.autoindex`目录放到资源所在目录。比如这里应该是`E:\download\.autoindex`

到这里可能会出现问题，比如我出现的不加`charset utf-8,gbk;`显示正常，加上反而乱码。但是不管加不加。点击中文的目录或者文件都会出现错误。要么还能把文件名改成英文的。

其实还有一个好的办法就是在windows中点击左下角win图标或者键盘按一下win键，---> 电脑设置 --->管理语言设置 ---> 更改系统区域设置(C)... --->  Beta版:使用Unicode UTF-8提供全球语言支持(U)前面勾选上。然后重启即可。

最后一步设置为开机启动。

这里采用一种简单方便的办法。新建一个nginx快捷方式放到`C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`目录即可。

[linux系统参考博客](https://segmentfault.com/a/1190000012606305)

