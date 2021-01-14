# Lua04-循环、流程控制与函数

### Lua循环

* Lua 语言提供了以下几种循环处理方式：

| 循环类型       | 描述                                                         |
| :------------- | :----------------------------------------------------------- |
| while 循环     | 在条件为 true 时，让程序重复地执行某些语句。执行语句前会先检查条件是否为 true。 |
| for 循环       | 重复执行指定语句，重复次数可在 for 语句中控制。              |
| repeat...until | 重复执行循环，直到 指定的条件为真时为止                      |
| 循环嵌套       | 可以在循环内嵌套一个或多个循环语句（while、for、do..while）  |

* `break` 语句  退出当前循环或语句，并开始脚本执行紧接着的语句。

#### while 循环

* Lua 编程语言中 while 循环语句在判断条件为 true 时会重复执行循环体语句。 

* Lua 编程语言中 while 循环语法：

```lua
while(condition)
do
   statements
end
```

例如：

```lua
a=10
while (a>0)
do
        print("a:"..a)
        a=a-1
end
```

#### for循环

* Lua 编程语言中 for 循环语句可以重复执行指定语句，重复次数可在 for 语句中控制。

* Lua 编程语言中 for语句有两大类：数值for循环、泛型for循环

##### 数值for循环

* Lua 编程语言中数值for循环语法格式: 

```lua
for var=exp1,exp2,exp3 do  
    <执行体>  
end  
```

* var从exp1变化到exp2，每次变化以exp3为步长递增var，并执行一次"执行体"。exp3是可选的，如果不指定，默认为1。 

* for的三个表达式在循环开始前一次性求值，以后不再进行求值。

示例：

```lua
#!/usr/local/bin/lua  
function f(x)  
    print("function")  
    return x*2   
end  
for i=1,f(3) do print(i)  
end 

--执行结果
--[[
function
1
2
3
4
5
6
--]]
```

##### 泛型for循环

* 泛型for循环通过一个迭代器函数来遍历所有值，类似java中的foreach语句。

* Lua 编程语言中泛型for循环语法格式:

```lua
--打印数组a的所有值  
for i,v in ipairs(a) 
	do print(v) 
end  
```

* i是数组索引值，v是对应索引的数组元素值。ipairs是Lua提供的一个迭代器函数，用来迭代数组。

实例:

循环数组 days：

```lua
#!/usr/local/bin/lua  
days = {"Suanday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}  
for i,v in ipairs(days) do  print(v) end   

--输出结果
--[[
Suanday
Monday
Tuesday
Wednesday
Thursday
Friday
Saturday
--]]
```

#### repeat...until 循环

* Lua 编程语言中 repeat...until 循环语句不同于 for 和 while循环，for 和 while循环d的条件语句在当前循环执行开始时判断，而 repeat...until 循环的条件语句在当前循环结束后判断。 

* Lua 编程语言中 repeat...until 循环语法格式:

```lua
repeat
   statements
while( condition )
```

 repeat...until 是条件后行,所以repeat...until 的循环体里面至少要运行一次。 

示例：

```lua
#!/usr/local/bin/lua 
a = 0
repeat
  print("a:"..a)
  a = a + 1
until( a > 3 )
```

### Lua 流程控制

Lua 提供了以下控制结构语句：

* if语句：**if 语句** 由一个布尔表达式作为条件判断，其后紧跟其他语句组成。

```lua
if(布尔表达式) then    --[ 在布尔表达式为 true 时执行的语句 --] end
```

* if...else 语句：**if 语句** 可以与 **else 语句**搭配使用, 在 if 条件表达式为 false 时执行 else 语句代码。

```lua
if(布尔表达式)
then
   --[ 布尔表达式为 true 时执行该语句块 --]
else
   --[ 布尔表达式为 false 时执行该语句块 --]
end
```

* if 嵌套语句:可以在**if** 或 **else if**中使用一个或多个 **if** 或 **else if** 语句 。

```lua
if( 布尔表达式 1)
then
   --[ 布尔表达式 1 为 true 时执行该语句块 --]
   if(布尔表达式 2)
   then
      --[ 布尔表达式 2 为 true 时执行该语句块 --]
   end
end
```

**注意：** Lua认为false和nil为假，true 和非nil为真。要注意的是Lua中 0 为 true。

### Lua函数

#### 函数定义

Lua 编程语言函数定义格式如下： 

```lua
--默认为全局函数，加关键字local为局部函数
function 函数名称(函数参数)	--多个函数参数','隔开，
   --函数体
 return 函数返回值 --可以为多个返回值用','隔开
end
```

#### 函数调用注意事项

* 当函数只有一个参数(且是字符串常量或者表构造器)，可以不使用`()`，其余情况均需要。例如：

```lua
-- 等价于print("Hello World")
print "Hello World"
 
-- 等价于dofile('a.lua')
dofile 'a.lua'
 
-- 等价于print([[a multi-line
-- message]])
print [[a multi-line
 message]]


-- 等价于f({x = 10, y = 20})
f{x = 10, y = 20}
 
-- 等价于type({})
type{}
```

- Lua语言也为 **面向对象风格的调用** 提供了一种特殊的语法，即  **冒号调用操作符**

  ```lua
  -- 其中o是对象, foo是o的方法
  o::foo(x)
  ```
  
- 调用函数时传递的参数个数可以与定义函数时定义的参数个数不一致，Lua会通过**抛弃多余参数和将不足的参数设为nil的方式**来调整参数的格式

  ```lua
  $lua
  > function f(a,b) print(a,b) end
  > f()
  nil     nil
  > f(1)
  1       nil
  > f(1,2)
  1       2
  > f(1,2,3)
  1       2
  > 
  ```

#### 多返回值

- **函数多返回值的使用会根据函数被调用的方式来返回:**

   - 当函数被作为一条单独语句调用时，**其所有返回值都会被丢弃**
   - 当函数被作为表达式（例如，加法的操作数）调用时，**将只保留函数的第一个返回值**
   - 只有当函数调用是一系列表达式中的最后一个表达式（或者唯一一个表达式）时， **其所有的返回值才能被获取到** 。这里的“一系列表达式”在Lua中表现为4种情况： **多重赋值、函数调用时传入的实参列表、表构造器、return语句**
   
##### 多重赋值 

   ```lua
   --当函数调用是一系列表达式中的最后（或者是唯一）一个表达式时尽可能多的返回值以匹配待赋值变量
   --多余的返回值被丢弃。没有返回值或者返回值个数不够多，那么Lua会用nil来补充缺失的值
   function f() return "a","b" end
   x=f() 				--x=a,b丢弃
   x,y=f()				--x=a,y=b
   x,y,z='c',f()		--x=c,y=a,z=b
   x,y,z=f() 			--x=a,y=b,z=nil
   --只有当函数调用不是一系列表达式中的最后（或者是唯一）一个表达式则只返回一个结果
   x,y=f(),'c'			--x=a,y=c,b丢弃
   x,y,z=f(),'c'		--x=a,y=c,z=nil,b丢弃
   x,y,z=f(),'c','d'	--x=a,y=c,z=d,b丢弃
   x,y,z='c',f(),'d'	--x=c,y=a,z=d,b丢弃
   --只返回一个结果，如果没有返回值,nil来补
   function f0() end
   x,y=f0(),'c','d'	--x=nil,y=c,d丢弃
   ```

   ##### 函数调用时传入的实参列表

   ```lua
   --原理同上
   --当一个函数调用是另一个函数调用的最后一个（或者唯一）实参时，函数的所有返回值都会被作为实参传给第二个函数
   function f0() end
   function f2() return "a","b" end
   print(f0())		--  
   print(1,f0())	--1
   print(f0(),1)	--nil 1
   print(f2())		--a b
   print(1,f2())	--1 a b
   --当一个函数调用是另一个函数调用的实参时，但是如果这个函数调用后面还有参数，那么这个函数只返回第一个返回值给第二个函数
   print(f2(),1)	--a 1 
   print(f2()..'c')--ac
   ```

#####   表构造器

   ```lua
   --原理同上
   --当这个函数是表构造器中的最后一个（或者唯一）实参时，函数的所有返回值都会返回给表构造器
   function f0() end
   function f2() return "a","b" end
   t1 = {f0()}		--{}
   t2 = {f2()}		--{"a","b"}
   t3 = {'c',f0()}	--{"c"}
   t4 = {'c',f2()}	--{"c","a","b"}
   for i,line in ipairs(t7) do print(line) end
   --当这个函数用来表构造器中，但是函数后面还有元素时，那么函数只返回第一个返回值
   t5 = {f2(),"c"}			--{"a","c"}
   t6 = {f0(),f2(),"c"}	--{nil,"a","c"}
   t7 = {f2(),f0(),"c"}	--{"a",nil,"c"}
   ```

#####  return语句

   ```lua
   --原理同上
   --当这个函数作为其他函数return的返回值返回时，如果是return的最后一个（或者唯一）实参时，函数的所有返回值都会返回
   --当这个函数作为其他函数return的返回值返回时，如果其后面还有别的返回值，那么只返回其第一个返回值
   #!/usr/local/bin/lua
   function f0() end
   function f2() return "a","b" end
   function f(i)
       if i==0 then return f0()
       elseif i==1 then return f2()
       elseif i==2 then return 1,2,f0()
   	elseif i==3 then return 1,2,f2()
       elseif i==4 then return f0(),1,2
   	elseif i==5 then return f2(),1,2
       end
   end
   
   x=0
   while (x < 6) 
   do 
   	print(f(x))
   	x=x+1
   end
   
   $./lua.test 
   
   a       b
   1       2
   1       2       a       b
   nil     1       2
   a       1       2
   
   --函数外加()强制返回一个值。
   ```

   - 如果一个函数返回多个返回值，我们可以在调用该函数时，  **在外面加一层圆括号，这样该函数只会返回一个返回值** 。

#### 可变长参数

* Lua支持可变长参数函数， **可变长参数** 是使用三个点（...）组成的可变长参数表达式
* 要遍历可变长参数，可以 **使用表达式{...}将可变长参数放在一个表中**

```lua
#!/usr/local/bin/lua

function add(...)
    local a={...}
    local sum=0
    for i=1, #a do
        sum = sum + a[i]
    end
    print("num is",#a,"sum is",sum)
	return
end

add(1)
add(1,2)
add(1,2,3,4,5)
--[[
num is  1       sum is  1
num is  2       sum is  3
num is  5       sum is  15
--]]
```

##### table.pack()函数

* 在Lua 5.2中引入了table.pack()函数，该函数像表达式{...}一样保存了所有参数，然后将其放在一个表中返回，但是这个表还有一个保存了参数个数的额外字段"n"

* 例如：下面使用函数table.pack()来检测参数中是否有nil

```lua
function nonils(...)
    local arg = table.pack(...)
    for i = 1, arg.n do
        if arg[i] == nil then return false end
    end
    return true
end
 
print(nonils(2, 3, nil)) --false
print(nonils(2, 3))		 --true
print(nonils())			 --false
print(nonils(nil))		 --true
```

##### select()函数）

- 另一种遍历可变长参数的方式 **使用select()函数**
-  **select()函数的参数1决定了该函数的行为：**
  - 如果参数1是一个数值n，则select()返回第n个参数后的所有参数
  - 如果参数1是#，则select()返回参数1后面所有参数的个数

* 例如：

```lua
print(select(1, "a", "b", "c")) 	--a b c
print(select(2, "a", "b", "c")) 	--b c
print(select(3, "a", "b", "c")) 	--c
print(select("#", "a", "b", "c"))	--3
```

##### table.unpack()

- 多重返回值还涉及一个特殊的函数table.unpack()，该函数的 **参数是一个数组，返回值为数组内的所有元素**

```lua
>a, b = table.unpack{1, 2, 3}
>print(a, b)
1       2
> 
```

#### 正确的尾调用

- Lua语言中有关函数的另一个有趣的特性是， **Lua原因是支持尾调用消除的** 。这意味着Lua **可以正确地尾递归，虽然尾递归调用消除的概念并没有直接涉及递归**
- **尾调用也就是递归**

##### 尾调用

- **尾调用是被当作函数调用使用的跳转**
- 当一个函数的**最后一个动作是调用另一个函数而没有进行其它工作时**，就形成了***\*尾调用\****

* 例如：

```lua
--对函数g()的调用就是尾调用
function f(x)
    x = x + 1
    return g(x)
end
```

##### 尾调用消除

- 在上面的代码中，当函数f()调用完g()之后**，f()不再需要进行其它的工作**。这样，当被调用的函数执行结束后，程序就不再需要返回最初的调用者。因此，在尾调用之后，**程序也就不需要在调用栈中保存有关调用函数的任何信息**。当g()返回时，程序的执行路径会直接返回到调用f()的位置
- 在一些语言的实现中，例如Lua语言解释器中，就利用了这个特点， **使得在进行尾调用时不使用任何额外的栈空间** ，我们将这种实现称为 **“尾调用消除”**

- 由于**尾调用不会使用栈空间**，所以一个程序中 **能够嵌套的尾调用的数量是无限的** 。例如，下面的函数永远不会发生栈溢出

  ```lua
  function foo(n)
      if n > 0 then
          return foo(n - 1)
      end
  end
  ```

##### 判断尾调用

```lua
--当调用完g(x)之后，f在返回前还不得不丢弃g()返回的所有结果,所以不是尾调用
function f(x)
    g(x)
end

-- 必须进行加法
return g(x) + 1
-- 必须把返回值限制为1个
return x or g(x)
-- 必须把返回值限制为1个
reutn (g(x))

-- 只有形如"return func(args)"的调用才是尾调用
-- func()及其参数都可以是复杂的表达式
return x[i].f(x[j] + a * b, i + j)
```

