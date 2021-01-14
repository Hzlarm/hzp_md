# Lua06-迭代器、table、模块与包

### Lua迭代器

迭代器（iterator）是一种对象，它能够用来遍历标准模板库容器中的部分或全部元素，每个迭代器对象代表容器中的确定的地址

在Lua中迭代器是一种支持指针类型的结构，它可以遍历集合的每一个元素。

##### 泛型 for 迭代器
泛型 for 在自己内部保存迭代函数，实际上它保存三个值：迭代函数、状态常量、控制变量。

泛型 for 迭代器提供了集合的 key/value 对，例如：

```lua
array = {"Lua", "Tutorial"}

for key,value in ipairs(array) 
do
   print(key, value)
end
```

范性for的执行过程：

- 首先，初始化，计算in后面表达式的值，表达式应该返回范性for需要的三个值：迭代函数、状态常量、控制变量；与多值赋值一样，如果表达式返回的结果个数不足三个会自动用nil补足，多出部分会被忽略。
- 第二，将状态常量和控制变量作为参数调用迭代函数（注意：对于for结构来说，状态常量没有用处，仅仅在初始化时获取他的值并传递给迭代函数）。
- 第三，将迭代函数返回的值赋给变量列表。
- 第四，如果返回的第一个值为nil循环结束，否则执行循环体。
- 第五，回到第二步再次调用迭代函数

在Lua中我们常常使用函数来描述迭代器，每次调用该函数就返回集合的下一个元素。Lua 的迭代器包含以下两种类型：

- 无状态的迭代器
- 多状态的迭代器

##### 无状态的迭代器

无状态的迭代器是指不保留任何状态的迭代器，因此在循环中我们可以利用无状态迭代器避免创建闭包花费额外的代价。

每一次迭代，迭代函数都是用两个变量（状态常量和控制变量）的值作为参数被调用，一个无状态的迭代器只利用这两个值可以获取下一个元素。

这种无状态迭代器的典型的简单的例子是ipairs，他遍历数组的每一个元素。

以下实例我们使用了一个简单的函数来实现迭代器，实现 数字 n 的平方：

```lua
function square(iteratorMaxCount,currentNumber)
   if currentNumber<iteratorMaxCount
   then
      currentNumber = currentNumber+1
   return currentNumber, currentNumber*currentNumber
   end
end

for i,n in square,3,0
do
   print(i,n)
end

-- 结果
1	1
2	4
3	9
```

迭代的状态包括被遍历的表（循环过程中不会改变的状态常量）和当前的索引下标（控制变量），ipairs和迭代函数都很简单，我们在Lua中可以这样实现：

```lua
function iter (a, i)
    i = i + 1
    local v = a[i]
    if v then
       return i, v
    end
end
 
function ipairs (a)
    return iter, a, 0
end
```

当Lua调用ipairs(a)开始循环时，他获取三个值：迭代函数iter、状态常量a、控制变量初始值0；然后Lua调用iter(a,0)返回1,a[1]（除非a[1]=nil）；第二次迭代调用iter(a,1)返回2,a[2]……直到第一个nil元素。

##### 多状态的迭代器

很多情况下，迭代器需要保存多个状态信息而不是简单的状态常量和控制变量，最简单的方法是使用闭包，还有一种方法就是将所有的状态信息封装到table内，将table作为迭代器的状态常量，因为这种情况下可以将所有的信息存放在table内，所以迭代函数通常不需要第二个参数。



以下实例我们创建了自己的迭代器：

```lua
array = {"Lua", "Tutorial"}

function elementIterator (collection)
   local index = 0
   local count = #collection
   -- 闭包函数
   return function ()
      index = index + 1
      if index <= count
      then
         --  返回迭代器的当前元素
         return collection[index]
      end
   end
end

for element in elementIterator(array)
do
   print(element)
end
```

### Lua table(表)

- **表（Table）** 是Lua语言中最主要（事实上也是唯一的）和强大的数据结构

- 使用表，Lua语言可以以一种简单、统一且高效的方式 **表示数组、集合、记录和其他许多数据结构** 。也可以       **使用表来表示模块（module）、包（package）和对象（Object）**（例如当调用math.sin时，对于Lua来说，实际上是以“字符串sin”为键检索“表math”）

* Lua table 使用关联型数组，你可以用任意类型的值来作数组的索引，但这个值不能是 nil。

* Lua table 是不固定大小的，你可以根据自己需要进行扩容。

#### 表的基本使用

- 可以 **使用构造器表达式来创建表** 。例如:

```lua
-- 创建一个表a
a = {}
-- 返回表的首地址
a
--[[
> a = {}
> a
table: 0x55d910408480
]]
```

* **可以向表中添加元素，并通过索引来获取值** 。例如：

```lua
k = "x"
 
a[k] = 10       -- 键为"x", 值为10
a[20] = "great" -- 键为20, 值为"great"
 
a["x"]   -- 获取键"x"的值10
a[k]     -- 获取键"x"的值10
a[20]    -- 获取键20的值"great"
 
k = 20   
a[k]     -- 获取键20的值"great"
 
a["x"] = a["x"] + 1 --将键"x"的值加1
a["x"]	-- 获取键"x"的值11
```

*  **可以有多个表名引用于同一个表,当最后一个引用释放时，垃圾收集器会最终删除这个表.** 

```lua
-- 通过a引用于一个表
a = {}
a["x"] = 10
 
-- b引用与a，指向于同一个表
b = a
b["x"]		-- 10
 
-- b改变表, a也改变
b["x"] = 20
a["x"]		-- 20
 
-- 释放a的引用，此时表还在
a = nil
b			-- table:0x*
 
-- 释放a的引用，现在没有引用引用于这个表，表释放
b = nil
```

#### 表索引

- 同一个表存储的值 **可以具有不同的类型索引** ，并且可以 **按需求增长以容纳新的元素**
- **未初始化的表元素的值为nil，将nil赋值给表元素可以将其删除**

```lua
-- 空的表
a = {}
 
-- 创建1000个新元素
for i = 1, 100 do a[i] = i*2 end
 
-- 得到索引9的值
a[9]
 
-- 设置"x"索引的值为10
a["x"] = 10
a["x"]
 
-- 表中没有名为"y"的索引, 返回nil
a["y"]
```

##### 把表当做结构体使用

- 当 **把表当做结构体使用** 时，可以把表名当做结构体名，然后 **使用"."调用表的元素** ，类似于C语言的结构体用法

```lua
-- 创建一个空的表
a = {}
 
-- 等价于a["name"] = "luaer"
a.name = "luaer"
-- 等价于a["age"] = 18
a.age = 18
 
-- 调用两个结构体成员
a.name
a.age
 
-- 没有这个成员, 索引返回nil
a.hourse
```

##### 索引类型的注意事项

- **索引也是有类型的。**例如0和"0"不是同一样，前者是数字类型，后者是字符串类型。  **可以进行显示类型的转换来调用** 。

```lua
a = {}
 
-- 定义两个不同的索引键
a[0] = 0
a["0"] = "0"
 
-- 这两个索引对应的值是不一样的
type(a[0])
type(a["0"])
 
-- 获取索引值为0的值
a[0]
-- 同上
a[tonumber("0")]
 
-- 获取索引值为"0"的值
a["0"]
-- 同上
a[tostring(0)]
```

* **对于整型和浮点型的表索引不会出现上面的问题** 。如果  **整型和浮点型之间能够进行转换** ，那么两者指向的是同一个索引。例如 

```lua
a = {}

a[2] = 666
a[2]		-- 666
a[2.0]		-- 666
 
a[2.0] = 777
a[2]		-- 777
a[2.0]		-- 777
```

#### table(表)的构造

构造器是 **创建和初始化表的表达式** 。

##### 空构造器

- **最简单的构造器是空{}**,如： `a = {}`。这种构造器初始化的表内容是空的。

##### 列表式构造器

- **类似于C语言的数组，** 可以指定元素，其中每个元素对应一个默认的索引
- **默认的索引从1开始** （而不是0），并且依次类推

```lua
-- 列表式构造器，每个元素都有默认的索引, 从1开始
days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thuray", "Friday", "Saturday"}
```

##### 纪录式构造器

- 纪录式构造器可以 **在定义的时候同时指定索引和对应的值**。索引的名字必须与Lua变量的命名规则一样，也就是说必须由下划线、字母、数字组成（不能以数字开头），并且定义的时候不能加双引号或者单引号

```lua
-- 正确定义
a = {x = 10, y =20, z = "HelloWorld"}
-- 错误定义
a = {"x" = 10}


-- 这样是正确的调用
a["x"]		-- 10
-- 这样是错误的, 当前作用域没有名为x的变量
a[x]		-- nil
 
-- 同上
a["y"]		-- 20
a[y]		-- nil
 
a["z"]		-- "HelloWorld"
```

##### 纪录式与列表式混合使用

- 对于列表式的元素，元素默认索引为1，然后依次类推
- 纪录式元素的索引以其定义的为准

```lua
polyline = {
    color = "blue", thickness = 2, npoints = 4,
    {x = 0, y = 0},  -- polyline[1]
    {x = 10, y = 0}, -- polyline[2]
    666,             -- polyline[3]
    value = 5, 
    "HelloWorld"     -- polyline[4]
}
 
 
print(polyline["color"]) -- blue
print(polyline["value"]) -- 5
 
print(polyline[1].x) -- 0
print(polyline[2].x) -- 10
print(polyline[3])   -- 666
print(polyline[4])   -- HelloWorld
```

##### 表构造注意事项

*  不论是哪种方式创建表， **都可以随时增加或删除表元素**  

* **列表式构造器和纪录式构造器有一些局限性** , **可以使用方括号括起来的表达式显式地指定每一个索引** 。
  - 不能使用负数索引初始化元素（索引必须是以1作为开始）
  - 纪录式构造器中不能使用不符合规范的标识符作为索引（规定索引的名字必须与变量命名规则一样，见上）
  - 纪录式构造器中的索引名不需要使用双引号或者单引号

```lua
-- 错误的, +和-不符合索引命名规则
opnames = { + = "add", - = "sub" }
 
-- 错误的，索引虽然正确，但是不需要使用双引号
opnames = { "a" = "add", "b" = "sub" }

-- 正确的，使用方括号指明索引
opnames = { ["+"] = "add", ["-"] = "sub"}
 
-- 调用
opnames["+"]	-- add
s = "-"
opnames[s]		-- sub


-- 可以使用数字作为索引, 并且索引值还可以为负的
i = 1
a = {[-1] = "A", [0] = "A".."A", [i] = "A".."A".."A"}
 
a[-1]
a[0]
a[1]

{x = 0, y = 0}   -- 等价于{["x"] = 0, ["y"] = 0}
{"r", "g", "b"}  -- 等价于{[1] = "r", [2] = "g", [3] = "b"}
```

- **构造器的最后一个元素后面可以跟着一个逗号，**但是是可选的，可以不添加. **构造器中的逗号可以用分号代替，**这主要是为了 **兼容Lua语言的旧版本**  

```lua
-- 尾部逗号默认省略
a = {[1] = "read", [2] = "green"}
 
-- 同上, 尾部有一个逗号
a = {[1] = "read", [2] = "green",}
```



#### Table 操作-表标准库

##### table.insert()

- 该函数的一种形式为：**向序列的指定位置插入一个元素，其他元素依次后移。**  **插入时不指定位置，那么会把新元素插入到序列的尾部** 

```lua
-- 创建一个表, 并打印所有元素
t = {10, 20, 30}
for k = 1, #t do
    print(k, t[k])
end
 
-- 在索引1处插入1个元素
table.insert(t, 1, 15)
-- 不指定位置插入尾部
table.insert(t, 25)
for k = 1, #t do
    print(k, t[k])
end
```

##### table.remove()

* 该函数的一种形式为： **该函数删除并返回序列指定位置的元素，然后将后面的元素向前移动填充。** **删除时不指定位置，那么会把末尾元素删除**

```lua
t = {111, 222, 333}
for k = 1, #t do
    print(k, t[k])
end
 
-- 删除第2个元素
table.remove(t, 2)
-- 删除第末尾元素
table.remove(t)
for k = 1, #t do
    print(k, t[k])
end

```

##### 利用table.insert()和table.remove()实现堆、队列、双端队列

- 借助这两个函数，可以 **很容易地实现栈、队列和双端队列**
- **以栈为例：**

```lua
-- 创建一个空栈
t = {}
 
-- 入栈, 在尾部插入元素(push)
table.insert(t, x)
 
-- 出栈, 删除尾部的元素(pop)
table.remove(t)
```

##### table.move()

* table.move(t,a, b, d)。调用该函数可以将表t中从索引a到b的元素（包括a和b本身）拷贝到位置d上 

*  table.move(t1, a, b, t2, d)。意思为：把表t1从索引a到b的元素（包括a和b本身）移动到表t2位置d上，函数返回表d的位置 

```lua
a = {1, 2}
b = {3, 4}
-- 表a的元素移动到另一个空表中，并返回该空表的地址
table.move(a, 1, #a, 1, {})

-- 表a的所有元素拷贝到表b的尾部
table.move(a, 1, #a, #b + 1, b)
```

##### table.concat()

concat(table , step , start , end) ，concat是concatenate(连锁, 连接)的缩写. table.concat()函数列出参数中指定table的数组部分从start位置到end位置的所有元素, 元素间以指定的分隔符(sep)隔开。

```lua
fruits = {"banana","orange","apple"}
-- 返回 table 连接后的字符串
print("连接后的字符串 ",table.concat(fruits))

-- 指定连接字符
print("连接后的字符串 ",table.concat(fruits,", "))

-- 指定索引来连接 table
print("连接后的字符串 ",table.concat(fruits,", ", 2,3))

--[[
连接后的字符串 	bananaorangeapple
连接后的字符串 	banana, orange, apple
连接后的字符串 	orange, apple
]]
```

#####   sort()  

对给定的table进行升序排序。

```lua
fruits = {"banana","orange","apple","grapes"}
print("排序前")
for k,v in ipairs(fruits) do
  print(k,v)
end

table.sort(fruits)
print("排序后")
for k,v in ipairs(fruits) do
   print(k,v)
end
```

执行以上代码输出结果为：

```lua
排序前
1   banana
2   orange
3   apple
4   grapes
排序后
1   apple
2   banana
3   grapes
4   orange
```

### 模块与包

模块类似于一个封装库，从 Lua 5.1 开始，Lua 加入了标准的模块管理机制，可以把一些公用的代码放在一个文件里，以 API 接口的形式在其他地方调用，有利于代码的重用和降低代码耦合度。

Lua 的模块是由变量、函数等已知元素组成的 table，因此创建一个模块很简单，就是创建一个 table，然后把需要导出的常量、函数放入其中，最后返回这个 table 就行。以下为创建自定义模块 module.lua，文件代码格式如下：

```lua
-- 文件名为 module.lua
-- 定义一个名为 module 的模块
module = {}
 
-- 定义一个常量
module.constant = "这是一个常量"
 
-- 定义一个函数
function module.func1()
    io.write("这是一个公有函数！\n")
end
 
local function func2()
    print("这是一个私有函数！")
end
 
function module.func3()
    func2()
end
 
return module
```

由上可知，模块的结构就是一个 table 的结构，因此可以像操作调用 table 里的元素那样来操作调用模块里的常量或函数。

上面的 func2 声明为程序块的局部变量，即表示一个私有函数，因此是不能从外部访问模块里的这个私有函数，必须通过模块里的公有函数来调用.

##### require()

 Lua提供了一个名为require的函数用来加载模块。要加载一个模块，只需要简单地调用就可以了。例如： 

```lua
require("<模块名>")
-- 或者
require "<模块名>"
```

 执行 require 后会返回一个由模块常量或函数组成的 table，并且还会定义一个包含该 table 的全局变量。 

```lua
-- test_module.php 文件
-- module 模块为上文提到到 module.lua
require("module")
 
print(module.constant)
 
module.func3()

-- 执行结果
--[[
这是一个常量
这是一个私有函数！
]]
```

 或者给加载的模块定义一个别名变量，方便调用： 

```lua
-- test_module2.php 文件
-- module 模块为上文提到到 module.lua
-- 别名变量 m
local m = require("module")
 
print(m.constant)
 
m.func3()

-- 执行结果
--[[
这是一个常量
这是一个私有函数！
]]
```

##### 加载机制

对于自定义的模块，模块文件不是放在哪个文件目录都行，函数 require 有它自己的文件路径加载策略，它会尝试从 Lua 文件或 C 程序库中加载模块。

require 用于搜索 Lua 文件的路径是存放在全局变量 package.path 中，当 Lua 启动后，会以环境变量 LUA_PATH 的值来初始这个环境变量。如果没有找到该环境变量，则使用一个编译时定义的默认路径来初始化。

当然，如果没有 LUA_PATH 这个环境变量，也可以自定义设置，在当前用户根目录下打开 .profile 文件（没有则创建，打开 .bashrc 文件也可以），例如把 "~/lua/" 路径加入 LUA_PATH 环境变量里：

```shell
#LUA_PATH
export LUA_PATH="~/lua/?.lua;;"
```

文件路径以 ";" 号分隔，最后的 2 个 ";;" 表示新加的路径后面加上原来的默认路径。

接着，更新环境变量参数，使之立即生效。`source ~/.profile`

这时假设 package.path 的值是：

```shell
/Users/dengjoe/lua/?.lua;./?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua
```

那么调用 require("module") 时就会尝试打开以下文件目录去搜索目标。

```shell
/Users/dengjoe/lua/module.lua;
./module.lua
/usr/local/share/lua/5.1/module.lua
/usr/local/share/lua/5.1/module/init.lua
/usr/local/lib/lua/5.1/module.lua
/usr/local/lib/lua/5.1/module/init.lua
```

如果找过目标文件，则会调用 package.loadfile 来加载模块。否则，就会去找 C 程序库。

搜索的文件路径是从全局变量 package.cpath 获取，而这个变量则是通过环境变量 LUA_CPATH 来初始。

搜索的策略跟上面的一样，只不过现在换成搜索的是 so 或 dll 类型的文件。如果找得到，那么 require 就会通过 package.loadlib 来加载它。

##### C包

Lua和C是很容易结合的，使用C为Lua写包。

与Lua中写包不同，C包在使用以前必须首先加载并连接，在大多数系统中最容易的实现方式是通过动态连接库机制。

Lua在一个叫loadlib的函数内提供了所有的动态连接的功能。这个函数有两个参数:库的绝对路径和初始化函数。所以典型的调用的例子如下:

```lua
local path = "/usr/local/lua/lib/libluasocket.so"
local f = loadlib(path, "luaopen_socket")
```

loadlib函数加载指定的库并且连接到Lua，然而它并不打开库（也就是说没有调用初始化函数），反之他返回初始化函数作为Lua的一个函数，这样我们就可以直接在Lua中调用他。

如果加载动态库或者查找初始化函数时出错，loadlib将返回nil和错误信息。我们可以修改前面一段代码，使其检测错误然后调用初始化函数：

```lua
local path = "/usr/local/lua/lib/libluasocket.so"
-- 或者 path = "C:\\windows\\luasocket.dll"，这是 Window 平台下
local f = assert(loadlib(path, "luaopen_socket"))
f()  -- 真正打开库
```

一般情况下我们期望二进制的发布库包含一个与前面代码段相似的stub文件，安装二进制库的时候可以随便放在某个目录，只需要修改stub文件对应二进制库的实际路径即可。

将stub文件所在的目录加入到LUA_PATH，这样设定后就可以使用require函数加载C库了。
