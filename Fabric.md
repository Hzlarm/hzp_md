



fabric是一个Python的库，同时它也是一个命令行工具。使用fabric提供的命令行工具，可以很方便地执行应用部署和系统管理等操作。

fabric依赖于paramiko进行ssh交互，fabric的设计思路是通过几个API接口来完成所有的部署，因此fabric对系统管理操作进行了简单的封装，比如执行命令，上传文件，并行操作和异常处理等。

### 安装Fabric

```bash
#安装
# fabric3支持python3
pip3 install fabric3

#查看帮助
fab --help
```

