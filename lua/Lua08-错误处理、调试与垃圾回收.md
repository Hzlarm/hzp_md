# Lua08-错误处理、调试与垃圾回收

### Lua错误处理

程序运行中错误处理是必要的，在我们进行文件操作，数据转移及web service 调用过程中都会出现不可预期的错误。如果不注重错误信息的处理，就会造成信息泄露，程序无法运行等情况。

任何程序语言中，都需要错误处理。错误类型有：

- 语法错误
- 运行错误

------

#### 语法错误

语法错误通常是由于对程序的组件（如运算符、表达式）使用不当引起的。一个简单的实例如下：

```lua
-- test.lua 文件
a == 2
```

以上代码执行结果为：

```lua
lua: test.lua:2: syntax error near '=='
```

正如你所看到的，以上出现了语法错误，一个 "=" 号跟两个 "=" 号是有区别的。一个 "=" 是赋值表达式两个 "=" 是比较运算。

另外一个实例:

```lua
for a= 1,10
   print(a)
end
```

执行以上程序会出现如下错误：

```lua
lua: test2.lua:2: 'do' expected near 'print'
```

语法错误比程序运行错误更简单，运行错误无法定位具体错误，而语法错误我们可以很快的解决，如以上实例我们只要在for语句下添加 do 即可：

```lua
for a= 1,10
do
   print(a)
end
```

------

#### 运行错误

运行错误是程序可以正常执行，但是会输出报错信息。如下实例由于参数输入错误，程序执行时报错：

```lua
function add(a,b)
   return a+b
end

add(10)
```

当我们编译运行以下代码时，编译是可以成功的，但在运行的时候会产生如下错误：

```lua
lua: test2.lua:2: attempt to perform arithmetic on local 'b' (a nil value)
stack traceback:
 test2.lua:2: in function 'add'
  test2.lua:5: in main chunk
    [C]: ?
```

以下报错信息是由于程序缺少 b 参数引起的。

------

#### 错误处理

我们可以使用两个函数：assert 和 error 来处理错误。实例如下：

```lua
local function add(a,b)
   assert(type(a) == "number", "a 不是一个数字")
   assert(type(b) == "number", "b 不是一个数字")
   return a+b
end
add(10)
```

执行以上程序会出现如下错误：

```lua
lua: test.lua:3: b 不是一个数字
stack traceback:
	[C]: in function 'assert'
	test.lua:3: in local 'add'
	test.lua:6: in main chunk
	[C]: in ?
```

实例中assert首先检查第一个参数，若没问题，assert不做任何事情；否则，assert以第二个参数作为错误信息抛出。

#### error函数

语法格式：

```lua
error (message [, level])
```

功能：终止正在执行的函数，并返回message的内容作为错误信息(error函数永远都不会返回)

通常情况下，error会附加一些错误位置的信息到message头部。

Level参数指示获得错误的位置:

- Level=1[默认]：为调用error位置(文件+行号)
- Level=2：指出哪个调用error的函数的函数
- Level=0:不添加错误位置信息

------

#### pcall 和 xpcall、debug

Lua中处理错误，可以使用函数pcall（protected call）来包装需要执行的代码。

pcall接收一个函数和要传递个后者的参数，并执行，执行结果：有错误、无错误；返回值true或者或false, errorinfo。

语法格式如下

```lua
if pcall(function_name, ….) then
-- 没有错误
else
-- 一些错误
end
```

简单实例：

```lua
> =pcall(function(i) print(i) end, 33)
33
true
   
> =pcall(function(i) print(i) error('error..') end, 33)
33
false        stdin:1: error..
> function f() return false,2 end
> if f() then print '1' else print '0' end
0
```



pcall以一种"保护模式"来调用第一个参数，因此pcall可以捕获函数执行中的任何错误。

通常在错误发生时，希望落得更多的调试信息，而不只是发生错误的位置。但pcall返回时，它已经销毁了调用桟的部分内容。

Lua提供了xpcall函数，xpcall接收第二个参数——一个错误处理函数，当错误发生时，Lua会在调用桟展看（unwind）前调用错误处理函数，于是就可以在这个函数中使用debug库来获取关于错误的额外信息了。

debug库提供了两个通用的错误处理函数:

- debug.debug：提供一个Lua提示符，让用户来价差错误的原因
- debug.traceback：根据调用桟来构建一个扩展的错误消息

`\>=xpcall(function(i) print(i) error('error..') end, function() print(debug.traceback()) end, 33) 33 stack traceback: stdin:1: in function [C]: in function 'error' stdin:1: in function [C]: in function 'xpcall' stdin:1: in main chunk [C]: in ? false nil`

xpcall 使用实例 2:

```lua
function myfunction ()
   n = n/nil
end

function myerrorhandler( err )
   print( "ERROR:", err )
end

status = xpcall( myfunction, myerrorhandler )
print( status)
```

执行以上程序会出现如下错误：

```lua
ERROR: test2.lua:2: attempt to perform arithmetic on global 'n' (a nil value)
false
```

### Lua 调试(Debug)

Lua 提供了 debug 库用于提供创建我们自定义调速器的功能。Lua 本身并未有内置的调速器，但很多开发者共享了他们的 Lua 调速器代码。

Lua 中 debug 库包含以下函数：

**sethook ([thread,] hook, mask [, count]):**

| 序号 | 方法 & 用途                                                  |
| :--- | :----------------------------------------------------------- |
| 1.   | **debug():**进入一个用户交互模式，运行用户输入的每个字符串。 使用简单的命令以及其它调试设置，用户可以检阅全局变量和局部变量， 改变变量的值，计算一些表达式，等等。 输入一行仅包含 cont 的字符串将结束这个函数， 这样调用者就可以继续向下运行。 |
| 2.   | **getfenv(object):**返回对象的环境变量。                     |
| 3.   | **gethook(optional thread):**返回三个表示线程钩子设置的值： 当前钩子函数，当前钩子掩码，当前钩子计数 |
| 4.   | **getinfo ([thread,] f [, what]):**返回关于一个函数信息的表。 你可以直接提供该函数， 也可以用一个数字 f 表示该函数。 数字 f 表示运行在指定线程的调用栈对应层次上的函数： 0 层表示当前函数（getinfo 自身）； 1 层表示调用 getinfo 的函数 （除非是尾调用，这种情况不计入栈）；等等。 如果 f 是一个比活动函数数量还大的数字， getinfo 返回 nil。 |
| 5.   | **debug.getlocal ([thread,] f, local):**此函数返回在栈的 f 层处函数的索引为 local 的局部变量 的名字和值。 这个函数不仅用于访问显式定义的局部变量，也包括形参、临时变量等。 |
| 6.   | **getmetatable(value):**把给定索引指向的值的元表压入堆栈。如果索引无效，或是这个值没有元表，函数将返回 0 并且不会向栈上压任何东西。 |
| 7.   | **getregistry():**返回注册表表，这是一个预定义出来的表， 可以用来保存任何 C 代码想保存的 Lua 值。 |
| 8.   | **getupvalue (f, up)**此函数返回函数 f 的第 up 个上值的名字和值。 如果该函数没有那个上值，返回 nil 。 以 '(' （开括号）打头的变量名表示没有名字的变量 （去除了调试信息的代码块）。 |
| 10.  | 将一个函数作为钩子函数设入。 字符串 mask 以及数字 count 决定了钩子将在何时调用。 掩码是由下列字符组合成的字符串，每个字符有其含义：**'`c`':** 每当 Lua 调用一个函数时，调用钩子；**'`r`':** 每当 Lua 从一个函数内返回时，调用钩子；**'`l`':** 每当 Lua 进入新的一行时，调用钩子。 |
| 11.  | **setlocal ([thread,] level, local, value):**这个函数将 value 赋给 栈上第 level 层函数的第 local 个局部变量。 如果没有那个变量，函数返回 nil 。 如果 level 越界，抛出一个错误。 |
| 12.  | **setmetatable (value, table):**将 value 的元表设为 table （可以是 nil）。 返回 value。 |
| 13.  | **setupvalue (f, up, value):**这个函数将 value 设为函数 f 的第 up 个上值。 如果函数没有那个上值，返回 nil 否则，返回该上值的名字。 |
| 14.  | **traceback ([thread,] [message [, level]]):**如果 message 有，且不是字符串或 nil， 函数不做任何处理直接返回 message。 否则，它返回调用栈的栈回溯信息。 字符串可选项 message 被添加在栈回溯信息的开头。 数字可选项 level 指明从栈的哪一层开始回溯 （默认为 1 ，即调用 traceback 的那里）。 |

上表列出了我们常用的调试函数，接下来我们可以看些简单的例子：

```lua
function myfunction ()
print(debug.traceback("Stack trace"))
print(debug.getinfo(1))
print("Stack trace end")
    return 10
end
myfunction ()
print(debug.getinfo(1))
```

执行以上代码输出结果为：

```lua
Stack trace
stack traceback:
   test2.lua:2: in function 'myfunction'
   test2.lua:8: in main chunk
    [C]: ?
table: 0054C6C8
Stack trace end
```

在以实例中，我们使用到了 debug 库的 traceback 和 getinfo 函数， getinfo 函数用于返回函数信息的表。

#### 另一个实例

我们经常需要调试函数的内的局部变量。我们可以使用 getupvalue 函数来设置这些局部变量。实例如下：

```lua
function newCounter ()
  local n = 0
  local k = 0
  return function ()
    k = n
    n = n + 1
    return n
    end
end

counter = newCounter ()
print(counter())
print(counter())

local i = 1

repeat
  name, val = debug.getupvalue(counter, i)
  if name then
    print ("index", i, name, "=", val)
    if(name == "n") then
        debug.setupvalue (counter,2,10)
   end
    i = i + 1
  end -- if
until not name

print(counter())
```

执行以上代码输出结果为：

```lua
1
2
index   1   k   =   1
index    2   n   =   2
11
```

在以上实例中，计数器在每次调用时都会自增1。实例中我们使用了 getupvalue 函数查看局部变量的当前状态。我们可以设置局部变量为新值。实例中，在设置前 n 的值为 2,使用 setupvalue 函数将其设置为 10。现在我们调用函数，执行后输出为 11 而不是 3。

------

#### 调试类型

- 命令行调试
- 图形界面调试

命令行调试器有：RemDebug、clidebugger、ctrace、xdbLua、LuaInterface - Debugger、Rldb、ModDebug。

图形界调试器有：SciTE、Decoda、ZeroBrane Studio、akdebugger、luaedit。

### Lua 垃圾回收

Lua 采用了自动内存管理。 这意味着你不用操心新创建的对象需要的内存如何分配出来， 也不用考虑在对象不再被使用后怎样释放它们所占用的内存。

Lua 运行了一个**垃圾收集器**来收集所有**死对象** （即在 Lua 中不可能再访问到的对象）来完成自动内存管理的工作。 Lua 中所有用到的内存，如：字符串、表、用户数据、函数、线程、 内部结构等，都服从自动管理。

Lua 实现了一个增量标记-扫描收集器。 它使用这两个数字来控制垃圾收集循环： 垃圾收集器间歇率和垃圾收集器步进倍率。 这两个数字都使用百分数为单位 （例如：值 100 在内部表示 1 ）。

垃圾收集器间歇率控制着收集器需要在开启新的循环前要等待多久。 增大这个值会减少收集器的积极性。 当这个值比 100 小的时候，收集器在开启新的循环前不会有等待。 设置这个值为 200 就会让收集器等到总内存使用量达到 之前的两倍时才开始新的循环。

垃圾收集器步进倍率控制着收集器运作速度相对于内存分配速度的倍率。 增大这个值不仅会让收集器更加积极，还会增加每个增量步骤的长度。 不要把这个值设得小于 100 ， 那样的话收集器就工作的太慢了以至于永远都干不完一个循环。 默认值是 200 ，这表示收集器以内存分配的"两倍"速工作。

如果你把步进倍率设为一个非常大的数字 （比你的程序可能用到的字节数还大 10% ）， 收集器的行为就像一个 stop-the-world 收集器。 接着你若把间歇率设为 200 ， 收集器的行为就和过去的 Lua 版本一样了： 每次 Lua 使用的内存翻倍时，就做一次完整的收集。

------

#### 垃圾回收器函数

Lua 提供了以下函数**collectgarbage ([opt [, arg]])**用来控制自动内存管理:

- **collectgarbage("collect"):** 做一次完整的垃圾收集循环。通过参数 opt 它提供了一组不同的功能：
- **collectgarbage("count"):** 以 K 字节数为单位返回 Lua 使用的总内存数。 这个值有小数部分，所以只需要乘上 1024 就能得到 Lua 使用的准确字节数（除非溢出）。
- **collectgarbage("restart"):** 重启垃圾收集器的自动运行。
- **collectgarbage("setpause"):** 将 arg 设为收集器的 间歇率 （参见 §2.5）。 返回 间歇率 的前一个值。
- **collectgarbage("setstepmul"):** 返回 步进倍率 的前一个值。
- **collectgarbage("step"):** 单步运行垃圾收集器。 步长"大小"由 arg 控制。 传入 0 时，收集器步进（不可分割的）一步。 传入非 0 值， 收集器收集相当于 Lua 分配这些多（K 字节）内存的工作。 如果收集器结束一个循环将返回 true 。
- **collectgarbage("stop"):** 停止垃圾收集器的运行。 在调用重启前，收集器只会因显式的调用运行。

以下演示了一个简单的垃圾回收实例:

```lua
mytable = {"apple", "orange", "banana"}

print(collectgarbage("count"))

mytable = nil

print(collectgarbage("count"))

print(collectgarbage("collect"))

print(collectgarbage("count"))
```

执行以上程序，输出结果如下(注意内存使用的变化)：

```lua
20.9560546875
20.9853515625
0
19.4111328125
```

