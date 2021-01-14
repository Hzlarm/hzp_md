# Lua03-数据类型

*  Lua是动态类型语言，变量不要类型定义,只需要为变量赋值。 值可以存储在变量中，作为参数传递或结果返回。 

*  Lua中有8个基本类型分别为：`nil`、`boolean`、`number`、`string`、`userdata`、`function`、`thread`和`table`。 

| 数据类型 | 描述                                                         |
| :------- | :----------------------------------------------------------- |
| nil      | 这个最简单，只有值nil属于该类，表示一个无效值（在条件表达式中相当于false）。 |
| boolean  | 包含两个值：false和true。                                    |
| number   | 表示双精度类型的实浮点数                                     |
| string   | 字符串由一对双引号或单引号来表示                             |
| function | 由 C 或 Lua 编写的函数                                       |
| userdata | 表示任意存储在变量中的C数据结构                              |
| thread   | 表示执行的独立线路，用于执行协同程序                         |
| table    | Lua 中的表（table）其实是一个"关联数组"（associative arrays），数组的索引可以是数字、字符串或表类型。在 Lua 里，table 的创建是通过"构造表达式"来完成，最简单构造表达式是{}，用来创建一个空表。 |

-  **使用type()函数可以获取一个值对应的类型名称** ，该函数的返回值为string类型：

```lua
print(type(nil))                --> nil
print(type(true))               --> boolean
print(type(10.4*3))             --> number
print(type("Hello world"))      --> string
print(type(io.stdin))			--> userdate
print(type(print))              --> function
print(type(type))               --> function
print(type({}))					--> table
print(type(type(X)))            --> string
```

#### nil(空)

* nil 类型表示一种没有任何有效值，它只有一个值 -- nil，例如打印一个没有赋值的变量，便会输出一个 nil 值： 

```lua
> print(type(a))
nil
>
```

*  对于全局变量和 table，nil 还有一个"删除"作用，给全局变量或者 table 表里的变量赋一个 nil 值，等同于把它们删掉，执行下面代码就知： 

```lua
tab1 = { key1 = "val1", key2 = "val2", "val3" }
for k, v in pairs(tab1) do
    print(k .. " - " .. v)
end
 
tab1.key1 = nil
for k, v in pairs(tab1) do
    print(k .. " - " .. v)
end
```

*  使用 nil 作比较时应该加上双引号： 

```lua
> type(X)
nil
> type(X)==nil
false
> type(X)=="nil"
true
>
```

#### boolean(布尔)

* boolean 类型只有两个可选值：true（真） 和 false（假），Lua 把 false 和 nil 看作是"假"，其他的都为"真": 

#### number（数字）

* **在Lua 5.2及之前的版本中，**所有的数值 **都以双精度浮点格式表示**
* **从Lua 5.3版本开始，Lua语言为数值格式提供了两种选择：**
  - 整型值：称为interger的64位整型
  - 浮点型值：称为float的双精度浮点类型
* 以下几种写法都被看作是 number 类型： 

```lua
print(type(2))
print(type(2.2))
print(type(0.2))
print(type(2e+1))
print(type(0.2e-1))
print(type(7.8263692594256e-06))
--结果均为number

-- 如果想要区分整型值和浮点型值，可以使用math.type()函数
math.type(3)  		-- integer
math.type(3.5)		-- float
math.type(3.14e3)	-- float
```

* Lua不仅支持十六进制的整型、还支持十六进制的浮点数

```lua
0xff	-- 255
0x1A3	-- 419
0x0.2	-- 0.125
```

* 十六进制浮点数还可以由小数部分和以p或P开头的指数部分组成（Lua 5.2引入的）

```lua
0x1p-1		-- 0.5
0xa.bp2		-- 42.75
```

#### string（字符串）

* 字符串由一对双引号或单引号来表示。

```lua
str1 = "this is string1"
str2 = 'this is string2'
```

* 也可以用 2 个方括号 "[[]]" 来表示"一块"字符串。

```lua
str0 = [[
this
is
str0
]]
print(str0)
```

* 在对一个数字字符串上进行算术操作时，Lua 会尝试将这个数字字符串转成一个数字:

```lua
> print("2" + 6)
8.0
> print("2" + "6")
8.0
> print("2 + 6")
2 + 6
> print("-2e2" * "6")
-1200.0
> print("error" + 1)
stdin:1: attempt to perform arithmetic on a string value
stack traceback:
 stdin:1: in main chunk
    [C]: in ?
> 
```

* 以上代码中"error" + 1执行报错了，字符串连接使用的是` ..` ，如：

```lua
> print("a" .. 'b')
ab
> print(157 .. 428)
157428
> 
```

* 使用` #` 来计算字符串的长度，放在字符串前面，如下实例：

```lua
> len = "hello!"
> print(#len)
6
> print(#"hello!")
6
> 
```

#### table（表）

* 在 Lua 里，table 的创建是通过"构造表达式"来完成，最简单构造表达式是{}，用来创建一个空表。也可以在表里添加一些数据，直接初始化表:

```lua
-- 创建一个空的 table
local tbl1 = {}
 
-- 直接初始表
local tbl2 = {"apple", "pear", "orange", "grape"}
```

* Lua 中的表（table）其实是一个"关联数组"（associative arrays），数组的索引可以是数字或者是字符串。

```lua
-- table_test.lua 脚本文件
a = {}
a["key"] = "value"
key = 10
a[key] = 22
a[key] = a[key] + 11
for k, v in pairs(a) do
    print(k .. " : " .. v)
end
```

脚本执行结果为：

```lua
$ lua table_test.lua 
key : value
10 : 33
```

* 不同于其他语言的数组把 0 作为数组的初始索引，在 Lua 里表的默认初始索引一般以 1 开始。

```lua
-- table_test2.lua 脚本文件
local tbl = {"apple", "pear", "orange", "grape"}
for key, val in pairs(tbl) do
    print("Key", key)
end
```

脚本执行结果为：

```lua
$ lua table_test2.lua 
Key  1
Key  2
Key  3
Key  4
```

* table 不会固定长度大小，有新数据添加时 table 长度会自动增长，没初始的 table 都是 nil。

```lua
-- table_test3.lua 脚本文件
a3 = {}
for i = 1, 10 do
    a3[i] = i
end
a3["key"] = "val"
print(a3["key"])
print(a3["none"])
```

脚本执行结果为：

```lua
$ lua table_test3.lua 
val
nil
```

------

* 对 table 的索引使用方括号 `[]`。Lua 也提供了` . `操作。 

```lua
t[i]
t.i                 -- 当索引为字符串类型时的一种简化写法
gettable_event(t,i) -- 采用索引访问本质上是一个类似这样的函数调用
```

#### function（函数）

* 在 Lua 中，函数是被看作是"第一类值（First-Class Value）"，函数可以存在变量里:

```lua
-- function_test.lua 脚本文件
function factorial1(n)
    if n == 0 then
        return 1
    else
        return n * factorial1(n - 1)
    end
end
print(factorial1(5))
factorial2 = factorial1
print(factorial2(5))
```

脚本执行结果为：

```lua
$ lua function_test.lua 
120
120
```

* function 可以以匿名函数（anonymous function）的方式通过参数传递:

```lua
-- function_test2.lua 脚本文件
function anonymous(tab, fun)
    for k, v in pairs(tab) do
        print(fun(k, v))
    end
end
tab = { key1 = "val1", key2 = "val2" }
anonymous(tab, function(key, val)
    return key .. " = " .. val
end)
```

脚本执行结果为：

```lua
$ lua function_test2.lua 
key1 = val1
key2 = val2
```

------

#### thread（线程）

* 在 Lua 里，最主要的线程是协同程序（coroutine）。它跟线程（thread）差不多，拥有自己独立的栈、局部变量和指令指针，可以跟其他协同程序共享全局变量和其他大部分东西。

* 线程跟协程的区别：线程可以同时多个运行，而协程任意时刻只能运行一个，并且处于运行状态的协程只有被挂起（suspend）时才会暂停。

------

#### userdata（自定义类型）

* userdata 是一种用户自定义数据，用于表示一种由应用程序或 C/C++ 语言库所创建的类型，可以将任意 C/C++ 的任意数据类型的数据（通常是 struct 和 指针）存储到 Lua 变量中调用。
