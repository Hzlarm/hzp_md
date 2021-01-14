# Lua01-介绍安装Lua、运行Lua程序

### Lua介绍（[Lua官网](http://www.lua.org)）

* Lua 是一种轻量小巧的脚本语言，用标准C语言编写并以源代码形式开放， **其设计目的是为了嵌入应用程序中，从而为应用程序提供灵活的扩展和定制功能 。**  

* **Lua 是一种很容易和传统的 C/C++整合的语言。**  Lua 所提供的机制是 C 不善于的：高级语言、动态结构、简洁、易于测试和 调试等。正因为如此，Lua 具有良好的安全保证，自动内存管理，简便的字符串处理功 能及其他动态数据的改变。

* **Lua 大部分强大的功能来自于他的s类库。** Lua 的长处之一就是可以通 过新类型和函数来扩展其功能。动态类型检查最大限度允许多态出现，并自动简化调用 内存管理的接口，因为这样不需要关心谁来分配内存谁来放内存，也不必担心数据溢 出。高级函数和匿名函数均可以接受高级参数，使函数更为通用。 Lua 自带一个小规模的类库。在受限系统中使用 Lua，如嵌入式系统，我们可以有 选择地安装这些类库。若运行环境十分严格，我们甚至可以直接修改类库源代码，仅保 留需要的函数。记住：Lua 是很小的（即使加上全部的标库）并且在大部分系统下你 仍可以不用担心的使用全部的功能。

- **Lua语言除了是一门可扩展的语言外，还是一门胶水语言（glue language）**。Lua 语言支 持组件化的软件开发方式，通过整合已有的高级组件构建新的应用。这些组件通常是通过 C/C++等编译型强类型语言编写的， Lua语言充当了整合和连接这些组件的角色。通常，组件（或对象）是对程序开发过程中相对稳定逻辑的具体底层（如小部件和数据结构）的抽象，这些逻辑占用了程序运行时的大部分 CPU 时间，而产品生命周期中可能经常发生变化的逻辑则可以使用 Lua 语言来实现。当然，除了整合组件外 Lua 语言也可以用来适配和改 造组件，甚至创建全新的组件
- **Lua语言的很多特性使它成为解决许多问题的首选：**
   - **可扩展性：** Lua 语言具有卓越的可扩展’性 Lua 的可扩展性好到很多人认为 Lua 超越了编 程语言的范畴，其甚至可以成为一种用于构建领域专用语言（ Domain-Specific Language，DSL ）的工具包 Lua 从一开始就被设计为可扩展的，既支持使用 Lua 语言代码来扩展， 也支持使用外部的C语言代码来扩展。在这一点上有一个很好的例证： Lua 语言的大部分基础功能都是通过外部库实现的。我们可以很容易地将 Lua与C/C++、Java、C#和Python等结合在一起使用
  - **简单：** Lua 语言是一门精简的语言。尽管它本身具有的概念并不多，但每个概念都很强大。这样的特性使得 Lua 语言的学习成本很低，也有助于减小其本身的大小（其包含所有标准库的 Linux 64 位版本仅220 KB）
   - **高效率： ** Lua 语言的实现极为高效。独立的性能测试说明 Lua 语言是脚本语言中最快的语言之一
  - **可移植：** Lua 语言可以运行在我们昕说过的几乎所有平台之上， 包括所有的 UNIX 操作系统（Linux FreeBSD等）、 Window、Android、iOS、OS X、IBM大型机、游戏终端（ PlayStation、Xbox、Wii 等） 、微处理器（如 Arduino ）等、针对所有这些平台的 源码本质上是一样的， Lua 语言遵循 ANSI（ISO）C标准，并未使用条件编译来对不同平台进行代码的适配。因此，当需要适配新平台时，只要使用对应平台下的 ISO C 编译器重新编译 Lua 语言的源码就可以了

[lua英文手册](http://www.lua.org/manual/5.4/)

###  安装Lua解释器

[参考官网安装](http://www.lua.org/start.html)

Lua解释器是用来运行Lua程序的。

* [Window 系统上安装 Lua,下载安装包](https://github.com/rjpcomputing/luaforwindows/releases)

* ubuntu安装Lua解释器

```shell
curl -R -O http://www.lua.org/ftp/lua-5.4.1.tar.gz
tar zxf lua-5.4.1.tar.gz
cd lua-5.4.1
make all test
sudo make install
```

```shell
# sudo make install安装 头文件、可执行文件、动态库以及man手册
cd src && mkdir -p /usr/local/bin /usr/local/include /usr/local/lib /usr/local/man/man1 /usr/local/share/lua/5.4 /usr/local/lib/lua/5.4
cd src && install -p -m 0755 lua luac /usr/local/bin
cd src && install -p -m 0644 lua.h luaconf.h lualib.h lauxlib.h lua.hpp /usr/local/include
cd src && install -p -m 0644 liblua.a /usr/local/lib
cd doc && install -p -m 0644 lua.1 luac.1 /usr/local/man/man1
```

### 运行lua程序

#### 交互式编程

Lua 交互式编程模式可以通过命令 lua -i 或 lua 来启用： 

```shell
$ lua -i
Lua 5.4.1  Copyright (C) 1994-2020 Lua.org, PUC-Rio
#执行代码
> print("Hello World！")
Hello World！
#加载lua文件或者lua库
> dofile("xx.lua")
#退出
> os.exit()
#或 Ctrl + D 退出
```

#### 脚本式编程

```shell
# vi helloworld.lua
print('Hello World')

#lua helloworld.lua
```

或者：
```shell
# vi helloworld.lua
#!/usr/local/bin/lua
print('Hello World')

#chmod +x helloworld.lua
#./helloworld.lua
```



