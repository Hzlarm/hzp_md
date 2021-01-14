# Lua07-元表、协同与文件I/O

### Lua元表(Metatable)

在 Lua table 中我们可以访问对应的key来得到value值，但是却无法对两个 table 进行操作。

因此 Lua 提供了元表(Metatable)，允许我们改变table的行为，每个行为关联了对应的元方法。

例如，使用元表我们可以定义Lua如何计算两个table的相加操作a+b。

当Lua试图对两个表进行相加时，先检查两者之一是否有元表，之后检查是否有一个叫`__add` 的字段，若找到，则调用对应的值。`__add` 等即时字段，其对应的值（往往是一个函数或是table）就是"元方法"。

有两个很重要的函数来处理元表：

- **setmetatable(table,metatable):**  对指定table设置元表(metatable)，如果元表(metatable)中存在__metatable键值，setmetatable会失败 。
- **getmetatable(table):**  返回对象的元表(metatable)。

以下实例演示了如何对指定的表设置元表：

```lua
mytable = {}                          -- 普通表 
mymetatable = {}                      -- 元表
setmetatable(mytable,mymetatable)     -- 把 mymetatable 设为 mytable 的元表 
```

以上代码也可以直接写成一行：

```lua
mytable = setmetatable({},{})
```

以下为返回对象元表：

```lua
getmetatable(mytable)                 -- 这回返回mymetatable
```

以下为元表常用的字段：

- 算术类元方法:   字段:`__add(+)`, `__mul(*)`,` __ sub(-)`,` __div(/)`,` __unm, __mod(%)`, `__pow`, `(__concat)`
- 关系类元方法： 字段：`__eq`,` __lt(<)`, `__le(<=)`，其他Lua自动转换 `a~=b -- not(a == b)`  `a  b -- b < a`   `a = b -- b <= a `(注意NaN的情况)
- table访问的元方法： 字段: `__index`, `__newindex`
- __index:  查询：访问表中不存的字段&
  `rawget(t, i)`

- __newindex： 更新：向表中不存在索引赋值 

  `rawset(t, k, v)`

#### __index 元方法

这是 metatable 最常用的键。

当你通过键来访问 table 的时候，如果这个键没有值，那么Lua就会寻找该table的metatable（假定有metatable）中的`__index `键。如果`__index`包含一个表格，Lua会在表格中查找相应的键。

```lua
$lua
Lua 5.4.1  Copyright (C) 1994-2020 Lua.org, PUC-Rio
 other = {foo = 3}
 t = setmetatable({},{__index = other})
 t.foo
3
 t.bar
nil
 
```

如果`__index`包含一个函数的话，Lua就会调用那个函数，table和键会作为参数传递给函数。

`__index` 元方法查看表中元素是否存在，如果不存在，返回结果为 nil；如果存在则由 __index 返回结果。

```lua
mytable = setmetatable({key1 = "value1"}, {
  __index = function(mytable, key)
    if key == "key2" then
      return "metatablevalue"
    else
      return nil
    end
  end
})

print(mytable.key1,mytable.key2)
-- value1	metatablevalue
```

实例解析：

- mytable 表赋值为  **{key1 = "value1"}** 。
- mytable 设置了元表，元方法为 __index。
- 在mytable表中查找 key1，如果找到，返回该元素，找不到则继续。
- 在mytable表中查找 key2，如果找到，返回该元素，找不到则继续。
- 判断元表有没有`__index`方法，如果`__index`方法是一个函数，则调用该函数。
- 元方法中查看是否传入 "key2" 键的参数（mytable.key2已设置），如果传入 "key2" 参数返回 "metatablevalue"，否则返回 mytable 对应的键值。

我们可以将以上代码简单写成：

```lua
mytable = setmetatable({key1 = "value1"}, { __index = { key2 = "metatablevalue" } })
print(mytable.key1,mytable.key2)
```

#### __newindex 元方法

`__newindex `元方法用来对表更新，`__index`则用来对表访问 。

当你给表的一个缺少的索引赋值，解释器就会查找`__newindex `元方法：如果存在则调用这个函数而不进行赋值操作。

以下实例演示了 `__newindex `元方法的应用：

```lua
mymetatable = {}
mytable = setmetatable({key1 = "value1"}, { __newindex = mymetatable })

print(mytable.key1)

mytable.newkey = "新值2"
print(mytable.newkey,mymetatable.newkey)

mytable.key1 = "新值1"
print(mytable.key1,mymetatable.newkey1)
```

以上实例执行输出结果为：

```lua
value1
nil    新值2
新值1    nil
```

以上实例中表设置了元方法` __newindex`，在对新索引键（newkey）赋值时（mytable.newkey = "新值2"），会调用元方法，而不进行赋值。而如果对已存在的索引键（key1），则会进行赋值，而不调用元方法` __newindex`。

以下实例使用了 rawset 函数来更新表：

```lua
mytable = setmetatable({key1 = "value1"}, {
  __newindex = function(mytable, key, value)
       rawset(mytable, key, "\""..value.."\"")

  end
})

mytable.key1 = "new value"
mytable.key2 = 4

print(mytable.key1,mytable.key2)

-- new value  "4"
```

#### 为表添加操作符

以下实例演示了两表相加操作：

```lua
-- 计算表中最大Key值，table.maxn在Lua5.2以上版本中已无法使用
-- 自定义计算表中最大Key值函数 table_maxn
function table_maxn(t)
    local mn = 0
    for k, v in pairs(t) do
        if mn < k then
            mn = k
        end
    end
    return mn
end

-- 两表相加操作
mytable = setmetatable({ 1, 2, 3 }, {
  __add = function(mytable, newtable)
    for i = 1, table_maxn(newtable) do
      table.insert(mytable, table_maxn(mytable)+1,newtable[i])
    end
    return mytable
  end
})

secondtable = {4,5,6}

mytable = mytable + secondtable
	for k,v in ipairs(mytable) do
print(k,v)
end
```

以上实例执行输出结果为：

```
1	1
2	2
3	3
4	4
5	5
6	6
```

__add 键包含在元表中，并进行相加操作。 表中对应的操作列表如下：

| 模式     | 描述               |
| :------- | :----------------- |
| __add    | 对应的运算符 '+'.  |
| __sub    | 对应的运算符 '-'.  |
| __mul    | 对应的运算符 '*'.  |
| __div    | 对应的运算符 '/'.  |
| __mod    | 对应的运算符 '%'.  |
| __unm    | 对应的运算符 '-'.  |
| __concat | 对应的运算符 '..'. |
| __eq     | 对应的运算符 '=='. |
| __lt     | 对应的运算符 '<'.  |
| __le     | 对应的运算符 '<='. |

------

#### __call 元方法

__call 元方法在 Lua 调用一个值时调用。以下实例演示了计算表中元素的和：

```lua
-- 计算表中最大Key值，table.maxn在Lua5.2以上版本中已无法使用
-- 自定义计算表中最大Key值函数 table_maxn
function table_maxn(t)
    local mn = 0
    for k, v in pairs(t) do
        if mn < k then
            mn = k
        end
    end
    return mn
end

-- 定义元方法__call
mytable = setmetatable({10}, {
  __call = function(mytable, newtable)
	sum = 0
	for i = 1, table_maxn(mytable) do
		sum = sum + mytable[i]
	end
    for i = 1, table_maxn(newtable) do
		sum = sum + newtable[i]
	end
	return sum
  end
})
newtable = {10,20,30}
print(mytable(newtable))

-- 70
```

#### __tostring 元方法

`__tostring` 元方法用于修改表的输出行为。以下实例我们自定义了表的输出内容：

```lua
mytable = setmetatable({ 10, 20, 30 }, {
  __tostring = function(mytable)
    sum = 0
    for k, v in pairs(mytable) do
        sum = sum + v
 end
    return "表所有元素的和为 " .. sum
  end
})
print(mytable)

-- 表所有元素的和为 60
```

### Lua 协同程序(coroutine)

#### 什么是协同(coroutine)？

Lua 协同程序(coroutine)与线程比较类似：拥有独立的堆栈，独立的局部变量，独立的指令指针，同时又与其它协同程序共享全局变量和其它大部分东西。

协同是非常强大的功能，但是用起来也很复杂。

#### 线程和协同程序区别

线程与协同程序的主要区别在于，一个具有多个线程的程序可以同时运行几个线程，而协同程序却需要彼此协作的运行。

在任一指定时刻只有一个协同程序在运行，并且这个正在运行的协同程序只有在明确的被要求挂起的时候才会被挂起。

协同程序有点类似同步的多线程，在等待同一个线程锁的几个线程有点类似协同。

#### 基本语法

| 方法                | 描述                                                         |
| :------------------ | :----------------------------------------------------------- |
| coroutine.create()  | 创建coroutine，返回coroutine， 参数是一个函数，当和resume配合使用的时候就唤醒函数调用 |
| coroutine.resume()  | 重启coroutine，和create配合使用                              |
| coroutine.yield()   | 挂起coroutine，将coroutine设置为挂起状态，这个和resume配合使用能有很多有用的效果 |
| coroutine.status()  | 查看coroutine的状态 注：coroutine的状态有三种：dead，suspend，running，具体什么时候有这样的状态请参考下面的程序 |
| coroutine.wrap（）  | 创建coroutine，返回一个函数，一旦你调用这个函数，就进入coroutine，和create功能重复 |
| coroutine.running() | 返回正在跑的coroutine，一个coroutine就是一个线程，当使用running的时候，就是返回一个corouting的线程号 |

**以下实例演示了以上各个方法的用法：**

```lua
-- coroutine_test.lua 文件
co = coroutine.create(
    function(i)
        print(i);
    end
)
 
coroutine.resume(co, 1)   -- 1
print(coroutine.status(co))  -- dead
 
print("----------")
 
co = coroutine.wrap(
    function(i)
        print(i);
    end
)
 
co(1)
 
print("----------")
 
co2 = coroutine.create(
    function()
        for i=1,10 do
            print(i)
            if i == 3 then
                print(coroutine.status(co2))  --running
                print(coroutine.running()) --thread:XXXXXX
            end
            coroutine.yield()
        end
    end
)
 
coroutine.resume(co2) --1
coroutine.resume(co2) --2
coroutine.resume(co2) --3
 
print(coroutine.status(co2))   -- suspended
print(coroutine.running())   --nil
 
print("----------")


-- 结果
1
dead
----------
1
----------
1
2
3
running
thread: 0x7fb801c05868    false
suspended
thread: 0x7fb801c04c88    true
----------
```

coroutine.running就可以看出来,coroutine在底层实现就是一个线程。

当create一个coroutine的时候就是在新线程中注册了一个事件。

当使用resume触发事件的时候，create的coroutine函数就被执行了，当遇到yield的时候就代表挂起当前线程，等候再次resume触发事件。

接下来我们分析一个更详细的实例：

```lua
function foo (a)
    print("foo 函数输出", a)
    return coroutine.yield(2 * a) -- 返回  2*a 的值
end
 
co = coroutine.create(function (a , b)
    print("第一次协同程序执行输出", a, b) -- co-body 1 10
    local r = foo(a + 1)
     
    print("第二次协同程序执行输出", r)
    local r, s = coroutine.yield(a + b, a - b)  -- a，b的值为第一次调用协同程序时传入
     
    print("第三次协同程序执行输出", r, s)
    return b, "结束协同程序"                   -- b的值为第二次调用协同程序时传入
end)
        
print("main", coroutine.resume(co, 1, 10)) -- true, 4
print("--分割线----")
print("main", coroutine.resume(co, "r")) -- true 11 -9
print("---分割线---")
print("main", coroutine.resume(co, "x", "y")) -- true 10 end
print("---分割线---")
print("main", coroutine.resume(co, "x", "y")) -- cannot resume dead coroutine
print("---分割线---")

-- 结果
第一次协同程序执行输出 1   10
foo 函数输出    2
main true    4
--分割线----
第二次协同程序执行输出   r
main true    11  -9
---分割线---
第三次协同程序执行输出  x   y
main true    10  结束协同程序
---分割线---
main false   cannot resume dead coroutine
---分割线---
```

以上实例接下如下：

- 调用resume，将协同程序唤醒,resume操作成功返回true，否则返回false；
- 协同程序运行；
- 运行到yield语句；
- yield挂起协同程序，第一次resume返回；（注意：此处yield返回，参数是resume的参数）
- 第二次resume，再次唤醒协同程序；（注意：此处resume的参数中，除了第一个参数，剩下的参数将作为yield的参数）
- yield返回；
- 协同程序继续运行；
- 如果使用的协同程序继续运行完成后继续调用 resumev方法则输出：cannot resume dead coroutine

resume和yield的配合强大之处在于，resume处于主程中，它将外部状态（数据）传入到协同程序内部；而yield则将内部的状态（数据）返回到主程中。

### 生产者-消费者问题

使用Lua的协同程序来完成生产者-消费者这一经典问题。

```lua
local newProductor

function productor()
     local i = 0
     while true do
          i = i + 1
          send(i)     -- 将生产的物品发送给消费者
     end
end

function consumer()
     while true do
          local i = receive()     -- 从生产者那里得到物品
          print(i)
     end
end

function receive()
     local status, value = coroutine.resume(newProductor)
     return value
end

function send(x)
     coroutine.yield(x)     -- x表示需要发送的值，值返回以后，就挂起该协同程序
end

-- 启动程序
newProductor = coroutine.create(productor)
consumer()
```

以上实例执行输出结果为：

```
1
2
3
4
5
6
7
8
9
10
11
12
13
……
```

### Lua 文件 I/O

- 由于Lua语言强调可移植性和嵌入型，所以 **Lua本身并没有提供太多与外部交互的机制** 。在真实的Lua程序中，从图形、数据库到网络的访问等大多数I/O操作，要么由宿主机实现，要么通过不包括在发行版中的外部库实现

- 单就Lua语言而言，只提供了ISO C语言标准支持的功能，即基本的文件操作等

* **对于文件操作来说，I/O库提供了两种不同的模型** 
  * **简单模型** （simple model）拥有一个当前输入文件和一个当前输出文件，并且提供针对这些文件相关的操作。
  * **完整模型** （complete model） 使用外部的文件句柄来实现。它以一种面对对象的形式，将所有的文件操作定义为文件句柄的方法

- io库中的 **所有函数在遇到错误时都会返回nil外加一条错误信息和一个错误码**

#### 简单模型

- 简单I/O模型虚拟了一个当前输入流和一个当前输出流，其I/O操作是通过这些流实现的

- I/O库把当前输入流初始化为进程的标准输入（C语言中的stdin），将当前输出流初始化为进程的标准输出（C语言中的stdout）

- **简单I/O模型提供的接口有：io.input()、io.output()、io.write()、io.read()。**

#####  io.input()
io.read()默认是从标准输入读取内容。

调用io.input()之后，程序后面的 **所有输入都来自该函数指定的输入流** 如`io.input("test.txt")` 将程序的输入流定向到test.txt文件中。

如果想要改变当前的输入流，再次调用io.input()即可。

##### io.uotput()
io.write()默认将内容输出到标准输出中 。

 调用io.output()之后，程序后面的 **所有的内容都输出到该函数指定的输出流中**  如`io.output("test.txt")` 将程序的输出流定向到test.txt文件中。

如果想要改变当前的输出流,再次调用io.output()即可。

##### io.write()
该函数可以 **将任意数量的字符串（或者数字）写入到输出流中** ,  **io.write(args)是io.output():write(args)的简写** , 即函数write使用在当前输出流上。
格式：`io.write(a, b, c...)` ,所有内容会拼接在一起输出。

```lua
$ lua
Lua 5.4.1  Copyright (C) 1994-2020 Lua.org, PUC-Rio
 
 io.write("sin(3) = ", math.sin(3), "\n")
sin(3) = 0.14112000805987
file (0x7ff4e600d760)
 io.write(string.format("sin(3) = %.4f\n", math.sin(3)))
sin(3) = 0.1411
file (0x7ff4e600d760)
 
```

##### io.read()
io.read() **可以从输入流中读取字符串** ，其参数决定了要读取的数据。
| 参数          | 描述                                                         |
| :------------ | :----------------------------------------------------------- |
| `"n"`         | 读取一个数字并返回它。例：`file.read("n")`                   |
| `"a"`         | 从当前位置读取整个文件。例：`file.read("a")`                 |
| "L"           | 读取下一行(保留换行符)，在文件尾 (EOF) 处返回 nil。例：`file.read("L")` |
| `"l"`（默认） | 读取下一行(丢弃换行符)，在文件尾 (EOF) 处返回 nil。例：`file.read("l")` |
| `num`         | 返回一个指定字符个数num的字符串，或在 EOF 时返回 nil。例：`file.read(5)` |

**io.read(0)是一个特例，** 它常用于检测是否到达了文件末尾。如果仍然有数据可供读取，它会返回一个空字符串；否则，返回nil

**io.read(args)实际上是io.input():read(args)的简写** ，即函数read使用在当前输入流上的



#### 完整模型

简单I/O模型对简单的需求而言还算适用，但对于诸如同时读写多个文件等更高级的文件操作来说就不够了。对于这些文件操作，我们需要用到完整I/O模型 。

##### io.open()

io.open()**用来打开一个文件**，该函数仿造了C语言中的fopen()函数

```lua
file = io.open (filename [, mode])
```

| mode | 描述                                                         |
| :--- | :----------------------------------------------------------- |
| r    | 以只读方式打开文件，该文件必须存在。                         |
| w    | 打开只写文件，若文件存在则文件长度清为0，即该文件内容会消失。若文件不存在则建立该文件。 |
| a    | 以附加的方式打开只写文件。若文件不存在，则会建立该文件，如果文件存在，写入的数据会被加到文件尾，即文件原先的内容会被保留。（EOF符保留） |
| r+   | 以可读写方式打开文件，该文件必须存在。                       |
| w+   | 打开可读写文件，若文件存在则文件长度清为零，即该文件内容会消失。若文件不存在则建立该文件。 |
| a+   | 与a类似，但此文件可读可写                                    |
| b    | 二进制模式，如果文件是二进制文件，可以加上b                  |
| +    | 号表示对文件既可以读也可以写                                 |

返回值：

- 正确：返回打开文件的文件流
- 失败：返回nil，同时返回一条错误消息以及一个系统相关的错误码

```lua
 io.open("non-existent-file", "r")
nil     non-existent-file: No such file or directory    2
```

- **检查错误的一种典型方法是使用函数assert()** ，如下所示，如果io.open()执行失败，错误信息会作为函数assert()的第二个参数被传入，之后函数assert()会将错误信息展示出来

```lua
local f = assert(io.open(filename, mode))
```

##### read()、write()

- 当使用io.open()打开文件之后，我们就可以使用read()和write()来读写流，与C语言的read()和write()类似
- 例如，下面打开一个文件读取其中的所有内容

```lua
-- 打开流
local f = assert(io.open("filename", "r"))
 
-- 读取流中的所有内容
local t = f:read("a")
 
-- 关闭流
f:close()
```

##### 内置句柄

- **I/O库提供了3个预定义的C语言流的句柄：** io.stdin、io.stdout、io.stderr
- 例如，可以使用下面的代码 **将信息直接写到标准错误流中**

```lua
io.stderr:write("Error", "\n")
```

##### io.input()、io.output()

- 在上面的简单I/O模型中我们介绍过了这两个函数，在完整I/O模型中也可以使用这两个函数
- **调用无参数的io.input()可以获得当前输入流，调用io.input(handle)可以设置当前输入流** 。如下所示

```lua
-- 保存当前的输入流
local temp = io.input()
 
-- 打开一个新的输入流
io.input("newinput")
 
-- 对新的输入流进行一系列操作
 
-- 操作完成之后关闭输入流
io.input():close()
 
-- 恢复之前的输入流
io.input("temp")
```

##### io.read()、io/write()

- 在上面的简单I/O模型中我们介绍过了这两个函数，在完整I/O模型中也可以使用这两个函数

##### io.lines()

- 在上面的简单I/O模型中我们介绍过了这个函数，在完整I/O模型中也可以使用这个函数
- 该函数返回一个可以从流中不断读取内容的迭代器
- **给函数io.lines()提供一个文件名，** 它就会 **以只读方式打开对应流文件的输入流** ，并在到达文件末尾后关闭该输入流
- **若调用时不带参数，** 函数io.lines()就从当前输入流读取
- 我们可以把函数lines当做句柄的一个方法
- 此外， **从Lua 5.2开始，io.read()的参数也可以在io.lines()中使用。** 例如，下面的代码会以在8KB为块迭代，将当前输入流中的内容复制到当前输出流中：

```lua
for block in io.input()::lines(2^13) do
    io.write(block)
end
```

#### 其他文件操作

##### io.tmpfile()

 - 该函数 **返回一个操作临时文件的句柄** ，该句柄是 **以读/写模式打开的** 
 - 当程序运行结束后，该 **临时文件会被自动移除（删除）** 

 ##### flush()

 - 函数flush **将所有缓冲数据写入文件** 
 - 与函数write类似，我们也可以把它当做 **io.flush()使用，以刷新当前输出流** 
 - 或者把它当做方法 **f:flush()使用，以刷新流f** 

 ##### setvbuf()

 - 该函数  **用于设置流的穿冲模式** 
 - **参数：**
   - **参数1：** 是一个字符串。"no"表示无缓冲；"full"表示在缓冲区满时或者显式地刷新文件时才写入数据；"line"表示输出一直被缓冲直到遇到换行符或从一些特定文件（例如终端设备）中读取到了数据
   - **参数2：** 如果参数1位"full"或"line"，则可以设置参数2，参数2代表缓冲区的大小
 - 在大多数系统中， **标准错误流（io.stderr）是不被缓冲的，而标准输出流（io.stdout）按行缓冲区**  。因此，当向标准输出中写入了不完整的行（例如进度条）时，可能需要刷新这个输出流才能看到输出结果

 ##### seek()

 - 该函数 **用来获取和设置文件的当前位置** ，常常使用f:seek(whence, offset)的形式来调用

 - **函数参数：**

   - whence参数：

     该参数是一个指定如何使用偏移的字符串，可以设置的值如下

     - set：表示相对于文件开头的偏移，以字节为单位
     - cur：表示相对于文件当前位置的偏移，以字节为单位
     - end：表示相对于文件尾部的偏移，以字节为单位

   - **offset参数：** 根据参数whence，设置偏移值

 - **返回值：** 返回当前新位置在流中相对于文件开头的偏移

 - **whence的默认值为"cur"，offset的默认值为0。因此：**

   - 调用f:seek()：不以任何参数调用该函数，该函数返回流在文件中的当前位置
   - 调用f:seek("set")：会将位置重置到文件开头并返回0
   - 调用f:seek("end")：会将位置重置到文件结尾并返回文件的大小

 - **下面是一些演示案例：**

 ```lua
function fsize(file)
    local current = file:seek()    -- 保存当前流偏移位置
    local size = file:seek("end")  -- 获取文件大小
    file:seek("set", current)      -- 恢复当前位置
    return size
end
 ```

##### io.popen()

- 由于部分依赖的机制不是ISO C标准的一部分，因此该函数并非在所有的Lua版本中都能使用。不过，尽管标准C中没有该函数，但由于其在主流操作系统中的普遍性，所以Lua语言标准库还是提供了该函数
- **该函数与os.execute()是一样的，该函数运行一条系统命令，** 但是该函数还可以重定向命令的输入/输出，从而使得程序可以向命令中写入或从命令的输出中读取

### OS库

 ##### os.rename()

 - 该函数 **用于文件重命名** 
 - 这个函数处理的是真实文件而非流，所以它们位于os库而非io库

 ##### os.remove()

 - 该函数**用于移除（删除）文件**
 - 这个函数处理的是真实文件而非流，所以它们位于os库而非io库

##### os.exit()

- 该函数 **用于终止程序的执行**
- **参数：**
  - **参数1：** 可选的，表示该程序的返回状态，可以是一个数值（0表示执行成功）或者一个布尔值（true表示执行成功）
  - **参数2：** 可选的，当值为true时会关闭LUa状态并调用所有析构器释放所占用的所有内存（这种终止方式通常是非必要的，因为大多数操作系统会在进程退出时释放其占用的所有资源）

##### os.getenv()

- 该函数 **用于获取某个环境变量**
- 该函数的 **参数是环境变量的名称，返回值是保存了该环境变量对应值的字符串**
- **例如：**

```lua
print(os.getenv("HOME"))
```

- 对于未定义的环境变量，该函数返回nil

##### os.exectue()

- 该函数 **用于运行系统命令** ，它等价于C语言中的system()函数
- **参数：** 表示待执行命令的字符串
- **该函数会返回3个返回值：**
  - 返回值1：是一个布尔类型。返回true时表示程序运行成功
  - 返回值2：是一个字符串。当为"exit"时表示程序正常运行结束，当为"signal"时表示因信号而中断
  - 返回值3：是返回状态（若该程序正常终结）或者终结该程序的信号代码
- 例如，在POSIX和Windows中都可以 **使用如下的函数创建新目录：**

```lua
function createDir(dirname)
    os.execute("mkdir" .. dirname)
end
```
