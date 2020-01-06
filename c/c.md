

#### fflush(stdin)与fflush(stdout)

 fflush函数被广泛使用在多线程、网络编程的消息处理中。 

##### fflush(stdin)：

作用：清理标准输入流，把多余的未被保存的数据丢掉。已经淘汰

用 `scanf(“%*[^\n]%*c”)`来替代。解释：

> ％*〔^\n〕将逐个读取缓冲区中的’\n’字符之前的其它字符，％后面的*表示将读取的这些字符丢弃，前遇到’\n’字符时便停止读取操作，此时，缓冲区中尚有一个’\n’字符遗留，所以后面的％*c将读取并丢弃这个遗留的换行符，这里的星号和前面的星号作用相同。由于所有从键盘的输入都是以回车结束的，而回车会产生一个’\n’字符，所以将’\n’连同它之前的字符全部读取并丢弃之后，也就相当于清除了输入缓冲区。 

##### 关于fflush(stdout)

 fflush(stdout)： 刷新标准输出缓冲区，把输出缓冲区里的东西打印到标准输出设备上  

 如果成功刷新,fflush返回0。指定的流没有缓冲区或者只读打开时也返回0值。返回EOF指出一个错误。 

#### dup与dup2

 在linux下，一切皆文件。当文件被打开时，会返回文件描述符用于操作该文件，从shell中运行一个进程，默认会有3个文件描述符存在(0、１、2)；）0表示标准输入，1表示标准输出，2表示标准错误。一个进程当前有哪些打开的文件描述符可以通过/proc/进程ID/fd目录查看。 

#####  dup函数

```c
#include <unistd.h>
int dup(int oldfd);
//调用dup(oldfd)等效于 fcntl(oldfd, F_DUPFD, 0)
```

dup用来复制参数oldfd所指的文件描述符。当复制成功是，返回最小的尚未被使用过的文件描述符，若有错误则返回-1.错误代码存入errno中返回的新文件描述符和参数oldfd指向同一个文件，这两个描述符共享同一个数据结构，共享所有的锁定，读写指针和各项全现或标志位。

##### dup2函数
头文件及其定义：


```c
 #include <unistd.h>
 int dup2(int oldfd, int newfd);
//dup2(oldfd, newfd)等效于		close(newfd);	fcntl(oldfd, F_DUPFD, newfd);如果old_fd是无效的，new_fd不会被close。
```

dup2与dup区别是dup2可以用参数newfd指定新文件描述符的数值。若参数newfd已经被程序使用，则系统就会将newfd所指的文件关闭，若newfd等于oldfd，则返回newfd,而不关闭newfd所指的文件。dup2所复制的文件描述符与原来的文件描述符共享各种文件状态。共享所有的锁定，读写位置和各项权限或flags等.
返回值：
若dup2调用成功则返回新的文件描述符，出错则返回-1.

在shell的重定向功能中，(输入重定向”<”和输出重定向”>”)就是通过调用dup或dup2函数对标准输入和标准输出的操作来实现的。



```c
ssize_t system_with_result(const char *cmd, void *buf, size_t count)
{
    int len = -1;
    int old_fd, new_fd;
    int fd[2];
    if (pipe(fd)) {
        printf("pipe failed\n");
        return -1;
    }
    int rfd = fd[0];
    int wfd = fd[1];
    if (EOF == fflush(stdout)) {
        printf("fflush failed: %s\n", strerror(errno));
        return -1;
    }
    if (-1 == (old_fd = dup(STDOUT_FILENO))) {
        printf("dup STDOUT_FILENO failed: %s\n", strerror(errno));
        return -1;
    }
    if (-1 == (new_fd = dup2(wfd, STDOUT_FILENO))) {
        //no need to check failed??
        //printf("dup2 STDOUT_FILENO failed: %s\n", strerror(errno));
        //return -1;
    }
    if (-1 == system(cmd)) {
        printf("system call failed!\n");
        return -1;
    }
    if (-1 == read(rfd, buf, count-1)) {
        printf("read buffer failed!\n");
        return -1;
    }
    len = strlen(buf);
    *((char *)buf + len - 1) = '\0';
    if (-1 == dup2(old_fd, new_fd)) {
        printf("dup2 failed: %s\n", strerror(errno));
        return -1;
    }
    return len;
}
```





 文件描述符表

 每种信号的处理方式(SIG_IGN、SIG_DFL或者自定义的信号处理函数)  

 当前工作目录

 用户id和组id

 但有些资源是每个线程各有一份的:

线程ID

 上下文信息,包括各种寄存器的值、程序计数器和栈指针

 栈空间

 errno变量

 信号屏蔽字

 调度优先级







 多线程程序的优点（相对进程比较而言）：

多个线程，它们彼此之间使用相同的地址空间，共享大部分数据，启动一个线程所花费的空间远远小于启动一个进程所花费的空间，而且，线程间彼此切换所需的时间也远远小于进程间切换所需要的时间，创建销毁速度快。

是线程间方便的通信机制。由于同一进程下的线程之间共享数据空间，所以一个线程的数据可以直接为其它线程所用，这不仅快捷，而且方便。





linux中可以使用clock_gettime系统调用来获取系统时间（秒数与纳秒数）。 纳秒为一秒的十亿分之一。
`#include <time.h>`

`int clock_gettime(clockid_t clk_id, struct timespec *tp); `
clockid_t clk_id 用于指定计时时钟的类型，有以下4种：  

CLOCK_REALTIME:系统实时时间,随系统实时时间改变而改变。
即从UTC1970-1-1 0:0:0开始计时,中间时刻如果系统时间被用户该成其他,则对应的时间相应改变  

CLOCK_MONOTONIC:从系统启动这一刻起开始计时,不受系统时间被用户改变的影响  

CLOCK_PROCESS_CPUTIME_ID:本进程到当前代码系统CPU花费的时间  

CLOCK_THREAD_CPUTIME_ID:本线程到当前代码系统CPU花费的时间  

struct timespect *tp用来存储当前的时间，其结构如下：        

```c
struct timespec  
{  
    time_t tv_sec; /* seconds */  
    long tv_nsec; /* nanoseconds */  
};
```
返回值。0成功，-1失败 



https://lxr.openwrt.org/source/uci/

常用API
1、uci_alloc_context: 动态申请一个uci上下文结构
struct uci_context *uci_alloc_context(void);

2、uci_free_context: 释放由uci_alloc_context申请的uci上下文结构且包括它的所有数据
void uci_free_context(struct uci_context *ctx);

3、uci_lookup_ptr：由给定的元组查找元素
int uci_lookup_ptr(struct uci_context *ctx, struct uci_ptr *ptr, char *str, bool extended);

4、uci_set ：写入配置
int uci_set(struct uci_context *ctx, struct uci_ptr *ptr);

5、uci_unload : 卸载包
int uci_unload(struct uci_context *ctx, struct uci_package *p);

6、uci_commit : 将缓冲区的更改保存到配置文件 还有uci_save ,有区别
int uci_commit(struct uci_context *ctx, struct uci_package **p, bool overwrite);

7、uci_foreach_element : 遍历uci的每个节点

8、uci_perror : 获取最后一个uci错误的错误字符串
void uci_perror(struct uci_context *ctx, const char *str);


9、uci_add_section：配置一个节点的值，如果节点不存在则创建
int uci_add_section(struct uci_context *ctx, struct uci_package *p, const char *type, struct uci_section **res);

10、uci_add_list : 追加一个list类型到节点
int uci_add_list(struct uci_context *ctx, struct uci_ptr *ptr);

11、uci_lookup_section : 查看一个节点
uci_section *uci_lookup_section(struct uci_context *ctx, struct uci_package *p, const char *name)

12、uci_lookup_option : 查看一个选项
 uci_option *uci_lookup_option(struct uci_context *ctx, struct uci_section *s, const char *name)


13、int uci_load ：加载配置文件
int uci_load(struct uci_context *ctx, const char *name, struct uci_package **package)