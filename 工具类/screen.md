# Linux screen命令

>Linux screen命令用于多重视窗管理程序。
>screen为多重视窗管理程序。此处所谓的视窗，是指一个全屏幕的文字模式画面。通常只有在使用telnet登入主机或是使用老式的终端机时，才有可能用到screen程序。
>
> screen命令，实际上，他的作用可以形象的描述为：就像windows打开一个窗口，在窗口内运行一个任务，每个窗口的任务各不冲突，它可以保持任务在远程连接断开之后，依然在保持执行。这是一个极大的优点。 
>
> 使用screen创建会话，可以保证网络中断时候会话不会断开，对于需要长时间运行的命令比较有用。 

### 语法

`screen [-AmRvx -ls -wipe][-d <作业名称>][-h <行数>][-r <作业名称>][-s <shell>][-S <作业名称>]`

**参数说明**：

- `-A` 　将所有的视窗都调整为目前终端机的大小。
- `-d`<作业名称> 　将指定的screen作业离线。
- `-h`<行数> 　指定视窗的缓冲区行数。
- `-m `　即使目前已在作业中的screen作业，仍强制建立新的screen作业。
- `-r`<作业名称> 　恢复离线的screen作业。  原来的会话还在线，screen阻止再一个会话进入。`-rd`
- `-R` 　先试图恢复离线的作业。若找不到离线的作业，即建立新的screen作业。
- `-s ` < shell> 　指定建立新视窗时，所要执行的shell。
- `-S`<作业名称> 　指定screen作业的名称。
- `-v `　显示版本信息。
- `-x `　恢复之前离线的screen作业。
- `-ls或--list `　显示目前所有的screen作业。
- `-wipe `　检查目前所有的screen作业，并删除已经无法使用的screen作业。

 在每个screen session 下，所有命令都以 ctrl+a(C-a) 开始。 

```
C-a ? -> 显示所有键绑定信息
C-a c -> 创建一个新的运行shell的窗口并切换到该窗口
C-a n -> Next，切换到下一个 window 
C-a p -> Previous，切换到前一个 window 
C-a 0..9 -> 切换到第 0..9 个 window
Ctrl+a [Space] -> 由视窗0循序切换到视窗9
C-a C-a -> 在两个最近使用的 window 间切换 
C-a x -> 锁住当前的 window，需用用户密码解锁
C-a d -> detach，暂时离开当前session，将目前的 screen session (可能含有多个 windows) 丢到后台执行，并会回到还没进 screen 时的状态，此时在 screen session 里，每个 window 内运行的 process (无论是前台/后台)都在继续执行，即使 logout 也不影响。 
C-a z -> 把当前session放到后台执行，用 shell 的 fg 命令则可回去。
C-a w -> 显示所有窗口列表
C-a t -> time，显示当前时间，和系统的 load 
C-a k -> kill window，强行关闭当前的 window
C-a [ -> 进入 copy mode，在 copy mode 下可以回滚、搜索、复制就像用使用 vi 一样
    C-b Backward，PageUp 
    C-f Forward，PageDown 
    H(大写) High，将光标移至左上角 
    L Low，将光标移至左下角 
    0 移到行首 
    $ 行末 
    w forward one word，以字为单位往前移 
    b backward one word，以字为单位往后移 
    Space 第一次按为标记区起点，第二次按为终点 
    Esc 结束 copy mode 
C-a ] -> paste，把刚刚在 copy mode 选定的内容贴上
```

