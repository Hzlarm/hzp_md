

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


