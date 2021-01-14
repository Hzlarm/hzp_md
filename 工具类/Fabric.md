==未完成，以后需要的时候再深入研究==

### 安装Fabric

```bash
#安装
# fabric3支持python3
pip3 install fabric3

#查看帮助
fab --help
```



参考[CSDN博客](https://blog.csdn.net/freeking101/article/details/81103945)

>Fabric 是一个 Python 的库，同时它也是一个命令行工具。它提供了丰富的同 SSH 交互的接口，可以用来在本地或远程机器上自动化、流水化地执行 Shell 命令。使用 fabric 提供的命令行工具，可以很方便地执行应用部署和系统管理等操作。因此它非常适合用来做应用的远程部署及系统维护。其上手也极其简单，你需要的只是懂得基本的 Shell 命令。
>
>fabric 依赖于 paramiko 进行 ssh 交互，fabric 的设计思路是通过几个 API 接口来完成所有的部署，因此 fabric 对系统管理操作进行了简单的封装，比如执行命令，上传文件，并行操作和异常处理等。
>
>paramiko 是一个用于做远程控制的模块，使用该模块可以对远程服务器进行命令或文件操作，**fabric** 和 **ansible** 内部的远程管理就是使用的paramiko来现实。
>
>Fabric是一个用于应用（批量）部署和系统（批量）管理的Python库和命令行工具，关于Fabric的介绍请参考：<http://www.fabfile.org/>。 Capistrano是一个用Ruby语言编写的远程服务器自动化和部署工具，关于Capistrano的介绍请参考：<http://capistranorb.com/>。
>
>本文仅使用Python语言和部分Linux或Windows系统命令，借助Fabric模块和Capistrano的部署思路，实现在Linux平台和Windows平台的自动化部批量署应用或实现批量系统管理（批量执行命令，批量上传文件等），其中Fabric部分利用Fabric的模块，Capistrano部分用Python语言按照Capistrano的部署思路“重写（Python实现Capistrano）”。
>
><http://capistranorb.com/documentation/getting-started/structure/#>

From：<http://python.jobbole.com/87241/>

From：Python模块学习 - fabric（Python3）：<https://www.cnblogs.com/xiao-apple36/p/9124292.html>

**fabric** 官网英文文档：<<http://www.fabfile.org/>

**fabric** 中文站点：<http://fabric-chs.readthedocs.io/zh_CN/chs/>

python三大神器之一fabric使用：<https://www.cnblogs.com/rufus-hua/p/5144210.html>

如何用Fabric实现无密码输入提示的远程自动部署：<https://blog.csdn.net/slvher/article/details/50414675>

fabric实现远程操作和部署：<http://python.jobbole.com/83716/>

自动化运维管理 fabric：<http://www.ttlsa.com/python/automation-operation-and-maintenance-tool-fabric/>

Python3自动化运维之Fabric模版详解：<https://www.imooc.com/article/38448>

《Python自动化运维技术与最佳实践》