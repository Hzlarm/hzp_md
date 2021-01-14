### OpenWrt源码分析启动流程

##### [OpenWrt目录说明](https://blog.csdn.net/hzlarm/article/details/102920028)

OpenWrt源码目录中,在第一次执行make时，scripts目录下的download.pl脚本会下载编译软件包的源代码到dl目录下，包括linux内核源码。在执行编译时会将源码包解压到build_dir目录下的`target-*/linux-*/linux-*`。

以下用`linux内核版本/`代表`open-wrt/build_dir/target-*/linux-*/linux-4.14.151`

#### kernel_init

bootloader将kernel从flash中拷贝到RAM以后，bootloader将退出舞台，并将这个舞台交给了kernel。从kernel的启动开始分析。 

不同平台的kernel启动时，最开始部分的汇编脚本会有些不一样，但是从汇编跳转到C语言的代码过程中的第一条命令大多数都是start_kernel函数，比如arm平台，它汇编代码的最后一个跳转是“b   start_kernel” （`linux内核版本/arch/arm/kernel/head-common.S`）

然后执行**`start_kernel（linux内核版本/init/main.c）`**函数,这个函数完成一些cpu，内存等初始化以后就会执行**`rest_init（linux内核版本-/init/main.c）`**函数，该函数创建两个内核线程kernel_init(pid为1)和kthreadd(pid为2)之后，进入死循环，即所谓的0号进程。

```c
/*   
     * We need to spawn init first so that it obtains pid 1, however
     * the init task will end up wanting to create kthreads, which, if
     * we schedule it before we create kthreadd, will OOPS.
     */
//....  
    pid = kernel_thread(kernel_init, NULL, CLONE_FS);
//....
    pid = kernel_thread(kthreadd, NULL, CLONE_FS | CLONE_FILES);
```



**`kenrel_init（linux内核版本/init/main.c）`**函数首先会调用**`kernel_init_freeable（linux内核版本/init/main.c）`**函数,他主要完成以下工作：

1.打开/dev/console，而且该打开句柄的文件描述符是0（标准输出），接着调动sys_dup复制两个文件描述符，分别是1和2，用于标准输入和标准出错。因为它是第一个打开的文件，所以文件描述符是0，如果打开的是其他文件，标准输出就在是0了。

2.第二件事是看一下uboot有没有传启动ramdisk的命令过来，如果没有，就判断/init文件是否存在，如果存在则调用prepare_namespace函数，这个函数会完成根文件系统的挂载工作。

```c

        /* Open the /dev/console on the rootfs, this should never fail */
        if (sys_open((const char __user *) "/dev/console", O_RDWR, 0) < 0)
                pr_err("Warning: unable to open an initial console.\n");

        (void) sys_dup(0);
        (void) sys_dup(0);
        /*
         * check if there is an early userspace init.  If yes, let it do all
         * the work
         */

        if (!ramdisk_execute_command)
                ramdisk_execute_command = "/init";

        if (sys_access((const char __user *) ramdisk_execute_command, 0) != 0) {
                ramdisk_execute_command = NULL;
                prepare_namespace();
        }

        /*
         * Ok, we have completed the initial bootup, and
         * we're essentially up and running. Get rid of the
         * initmem segments and start the user-mode stuff..
         *
         * rootfs is available now, try loading the public keys
         * and default modules
         */

        integrity_load_keys();
        load_default_modules();
```

然后返回kernel_init函数，继续执行下面的代码，它首先会检查内核的启动参数中是否有设置init参数，如果有，则会使用该参数指定的程序作为init程序，否则会按照如下代码中所示的顺序依次尝试启动，如果都无法启动就会kernel panic。 

> 为了支持更多的路由器，更多的操作和openwrt特有的一些内核功能，linux源码是不具备的，这样openwrt为了增加这些功能，就需要在linux官网上面下载的源代码中做一些修改，给linux源码打补丁 。 Openwrt源码中的linux补丁文件放在target/linux/generic文件下面，有对于不同版本的linux内核补丁文件 。如果是3.18版本内核，则对应的补丁文件会在patches-3.18目录中

```diff
--- a/init/main.c
+++ b/init/main.c
@@ -963,7 +963,8 @@ static int __ref kernel_init(void *unuse
                pr_err("Failed to execute %s (error %d).  Attempting defaults...\n",
                        execute_command, ret);
        }   
-       if (!try_to_run_init_process("/sbin/init") ||
+       if (!try_to_run_init_process("/etc/preinit") ||
+           !try_to_run_init_process("/sbin/init") ||
            !try_to_run_init_process("/etc/init") ||
            !try_to_run_init_process("/bin/init") ||
            !try_to_run_init_process("/bin/sh"))
```

try_to_run_init_process一旦执行就不会再返回到此函数中了，而是作为linux 1号进程长期存活，直至关机时它关掉其他所有进行最后才会退出。 

执行到这里的时候OpenWrt会首先执行`/etc/preinit`（开发板的文件系统中） 

但是在该脚本的第一句命令为**`[ -z "$PREINIT" ] && exec /sbin/init`**第一次执行的时候这里PREINIT变量没有定义所以会转而执行/sbin/init。

> exec是以新的进程去代替原来的进程，但进程的PID保持不变, 运行完毕之后不回到原先的程序中去 。因此，可以这样认为，exec系统调用并没有创建新的进程，只是替换了原来进程上下文的内容。原进程的代码段，数据段，堆栈段被新的进程所代替

#### /sbin/init

/sbin/init程序源码位置在`build_dir/target-*/procd--2015-10-29.1/initd/`目录下，该目录属于proced目录。 在OpenWrt中，procd主要取代busybox(initd,klogd,syslogd,watchdog)等功能 。

```c
//proced*/init.d/init.c 中的main函数
int main(int argc, char **argv)
{
        pid_t pid;

        ulog_open(ULOG_KMSG, LOG_DAEMON, "init");

        sigaction(SIGTERM, &sa_shutdown, NULL);
        sigaction(SIGUSR1, &sa_shutdown, NULL);
        sigaction(SIGUSR2, &sa_shutdown, NULL);

        early(); 	// ./early.c  又调用了early_mounts()与early_env()
    					//挂载 /proc /sys /tmp /dev /dev/pts目录(early_mounts)
    					//创建设备节点和/dev/null文件结点(early_dev)
    					//设置PATH环境变量(early_env)
    					//初始化/dev/console

        cmdline();	//设置dubug全局变量，根据/proc/cmdline内容init_debug=([0-9]+)判断debug级别
        watchdog_init(1);		//  ./watchdog.c
									//初始化内核watchdog(/dev/watchdog)		
        pid = fork();
        if (!pid) {
                char *kmod[] = { "/sbin/kmodloader", "/etc/modules-boot.d/", NULL };

                if (debug < 3) {
                        int fd = open("/dev/null", O_RDWR);
                        if (fd > -1) {
                                dup2(fd, STDIN_FILENO);
                                dup2(fd, STDOUT_FILENO);
                                dup2(fd, STDERR_FILENO);
                                if (fd > STDERR_FILENO)
                                        close(fd);
                        }   
                }   
                execvp(kmod[0], kmod); // 创建子进程/sbin/kmodloader加载/etc/modules-boot.d/目录中的内核模块
                ERROR("Failed to start kmodloader\n");
                exit(-1);
        }   
        if (pid <= 0) {
                ERROR("Failed to start kmodloader instance\n");
        } else {
                int i;
                for (i = 0; i < 120; i++) {
                        if (waitpid(pid, NULL, WNOHANG) > 0)
                                break;
                        sleep(1);
                        watchdog_ping();
                }   
        }   
        uloop_init();
        preinit(); 		// 	../preinit.c中  见下代码
        uloop_run();

        return 0;
```

 /sbin/init 在执行的时候pid为1，最后会调用`preinit()`函数创建 2 个子进程：分别执行`/sbin/procd -h /etc/hotplug-preinit.json` 和`/bin/sh /etc/preinit`。

```c
//proced*/init.d/preinit.c 中的preinit函数
void preinit(void)
{
        char *init[] = { "/bin/sh", "/etc/preinit", NULL };
        char *plug[] = { "/sbin/procd", "-h", "/etc/hotplug-preinit.json", NULL };

        LOG("- preinit -\n");

        plugd_proc.cb = plugd_proc_cb;
        plugd_proc.pid = fork();
        if (!plugd_proc.pid) {
                execvp(plug[0], plug);//创建子进程执行/sbin/procd -h/etc/hotplug-preinit.json
                ERROR("Failed to start plugd\n");
                exit(-1);
        }   
        if (plugd_proc.pid <= 0) {
                ERROR("Failed to start new plugd instance\n");
                return;
        }   
        uloop_process_add(&plugd_proc);//主进程同时使用uloop_process_add()把/sbin/procd子进程加入uloop进行监控

        setenv("PREINIT", "1", 1); //再次执行/etc/preinit之前先将PREINIT变量设置为1

        preinit_proc.cb = spawn_procd;//当/sbin/procd进程结束时回调spawn_procd()函数。见下代码
        preinit_proc.pid = fork();
        if (!preinit_proc.pid) {
                execvp(init[0], init);//创建子进程执行/etc/preinit脚本
                ERROR("Failed to start preinit\n");
                exit(-1);
        }   
        if (preinit_proc.pid <= 0) {
                ERROR("Failed to start new preinit instance\n");
                return;
        }   
        uloop_process_add(&preinit_proc);//，主进程同时使用uloop_process_add()把/etc/preinit子进程加入uloop进行监控,当/etc/preinit执行结束时回调plugd_proc_cb()函数把监控/etc/preinit进程对应对象中pid属性设置为0，表示/etc/preinit已执行完成
        DEBUG(4, "Launched preinit instance, pid=%d\n", (int) preinit_proc.pid);
}
```

执行/etc/preinit之前会设置变量PREINIT，/sbin/procd会带-h的参数。系统启动完成后，ps命令显示的进程号为1的进程名最终为/sbin/procd。

```c
//proced*/init.d/preinit.c 中的spawn_procd函数
//spawn_procd()函数繁衍后继真正使用的/sbin/procd进程，从/tmp/debuglevel读出debug级别并设置到环境变量DBGLVL中，把watchdog fd设置到环境变量WDTFD中，最后调用execvp()繁衍后继真正使用的sbin/procd进程,使其成为用户空间的第一个进程（PID=1）。
static void spawn_procd(struct uloop_process *proc, int ret)
{       
        char *wdt_fd = watchdog_fd();
        char *argv[] = { "/sbin/procd", NULL};
        struct stat s;
        char dbg[2];
        
        if (plugd_proc.pid > 0)
                kill(plugd_proc.pid, SIGKILL);
        
        if (!stat("/tmp/sysupgrade", &s))
                while (true)
                        sleep(1);
        
        unsetenv("INITRAMFS");
        unsetenv("PREINIT");
        DEBUG(2, "Exec to real procd now\n");
        if (wdt_fd)
                setenv("WDTFD", wdt_fd, 1);
        check_dbglvl();
        if (debug > 0) {
                snprintf(dbg, 2, "%d", debug);
                setenv("DBGLVL", dbg, 1);
        }
        //从/tmp/debuglevel读出debug级别并设置到环境变量DBGLVL中，把watchdog fd设置到环境变量WDTFD中
        execvp(argv[0], argv);
}
```

#### /etc/preinit

/etc/preinit脚本(是一系列脚本的入口)它内容是：

```bash
#!/bin/sh
# Copyright (C) 2006 OpenWrt.org
# Copyright (C) 2010 Vertical Communications

[ -z "$PREINIT" ] && exec /sbin/init

export PATH=/usr/sbin:/usr/bin:/sbin:/bin

pi_ifname=
pi_ip=192.168.99.1
pi_broadcast=192.168.99.255
pi_netmask=255.255.255.0

fs_failsafe_ifname=
fs_failsafe_ip=192.168.99.1
fs_failsafe_broadcast=192.168.99.255
fs_failsafe_netmask=255.255.255.0

fs_failsafe_wait_timeout=0

pi_suppress_stderr="y"
pi_init_suppress_stderr="y"
pi_init_path="/usr/sbin:/usr/bin:/sbin:/bin"
pi_init_cmd="/sbin/init"
#  执行以下脚本，这样以下之后的函数函数才可以使用
. /lib/functions.sh
. /lib/functions/preinit.sh
. /lib/functions/system.sh
#初始化5个函数队列,相当于5种类型的脚本, boot_hook_init 在 preinit.sh 实现
boot_hook_init preinit_essential
boot_hook_init preinit_main
boot_hook_init failsafe
boot_hook_init initramfs
boot_hook_init preinit_mount_root
#循环执行 /lib/preinit 目录下面的脚本
for pi_source_file in /lib/preinit/*; do
 . $pi_source_file
done

boot_run_hook preinit_essential

pi_mount_skip_next=false
pi_jffs2_mount_success=false
pi_failsafe_net_message=false

boot_run_hook preinit_main
```

第二次执行/etc/preinit脚本

这个脚本前半部分定义了一些变量 。接下来是执行了三个脚本

. /lib/functions.sh
. /lib/functions/preinit.sh
. /lib/functions/system.sh 

注意“.”和“/”之间是有空格的，这里的点相当与souce命令，但souce是bash特有的，并不在POSIX标准中，“.”是通

用的用法。使用“.”的意思是在当前shell环境下运行，并不会在子shell中运行。

这几个shell脚本主要定义了shell函数，特别是preinit.sh中，定义了hook相关操作的函数：boot_hook_init和

boot_run_hook。boot_hook_init是初始化一个函数队列，boot_run_hook是运行一个函数队列，还有一个函数不在这里，boot_book_add这个是在一个函数队列中添加一个函数。

然后就是 循 环 执 行/lib/preinit 目录下面的脚本。由于脚本众多，因此openwrt的设计者将这些脚本分成下面5几类：

```bash
preinit_essential
preinit_main
failsafe
initramfs
preinit_mount_root
```

目前/lib/preinit/下的所有脚本只实现了 preinit_main 和 failsafe 这两类，如下所示：

```shell
preinit_main：					函数
02_default_set_state			define_default_set_state
03_preinit_do_ramips.sh			do_ramips
04_handle_checksumming			do_checksumming_disable
07_set_preinit_iface_ramips		ramips_set_preinit_iface
10_indicate_preinit				preinit_ip	&	pi_indicate_preinit
10_sysinfo						do_sysinfo_generic
50_indicate_regular_preinit		indicate_regular_preinit
70_initramfs_test				initramfs_test
80_mount_root					do_mount_root
99_10_run_init					run_init

failsafe： 					函数
10_indicate_failsafe		indicate_failsafe
30_failsafe_wait			failsafe_wait
40_run_failsafe_hook		run_failsafe_hook
99_10_failsafe_login		failsafe_netlogin  &	failsafe_shell
```

/lib/preinit/目录下的脚本具体类似的格式，定义要添加到hook结点的函数，然后通过boot_hook_add将该函数添加到对应的hook结点。
最后，/etc/preinit就会执行boot_run_hook函数执行对应hook结点上的函数。在当前环境下只执行了preinit_essential和preinit_main结点上的函数，如下：
                boot_run_hook preinit_essential
                boot_run_hook preinit_main

当运行preinit_main的时候，队列中的所有函数就会依次执行。每一类函数按照脚本的开头数字的顺序运行。

到此，/etc/preinit执行完毕并退出。

如果需要跟踪调试脚本，可以 在/etc/preinit的最开始添加一条命令set -x，这样就会在执行的时候打印出执行命令的过程。

例如：02_default_set_state的内容。 

```bash
#!/bin/sh
define_default_set_state() {
 . /etc/diag.sh
}
boot_hook_add preinit_main define_default_set_state
```

可以看到它就是在preinit_main函数队列中增加一个函数，这个函数就是简单的执行一个脚本，加载/etc/diag.sh 中的两个状态操作函数：get_status_led 和 set_state。 

其他一些函数功能：

```
do_ramips do_ramips（/lib/preinit/03_preinit_do_ramips.sh）
调用/lib/ramips.sh 中的 ramips_board_detect 函数探测板子名称，将其保存在
/tmp/sysinfo/board_name 和/tmp/sysinfo/model 这 2 个文件中，
我们可以通过  cat /tmp/sysinfo/board_name 查看板子名称， cat /tmp/sysinfo/model查看模块名称 

ramips_set_preinit_iface（/lib/preinit/07_set_preinit_iface_ramips）
初始化网络接口，设置 switch，针对RT5350|MT7628|MT7688的设置，为了避免 Failsafe 模式 TCP 连接超时。

preinit_ip（/lib/preinit/10_indicate_preinit）
预初始化 IP 地址

pi_indicate_preinit（/lib/preinit/10_indicate_preinit）
设置 LED，指示进入 preinit 过程

failsafe_wait（/lib/preinit/30_failsafe_wait）
根据内核参数/proc/cmdline 或者用户是否按下相应按键，决定是否进入 failsafe 模式（故障恢复模式）。
如果内核参数含有 FAILSAFE=true，则表示直接进入 failsafe 模式，否则调用 fs_wait_for_key 等待用户终端按键（默认为’F’+Enter），等待时间为 fs_failsafe_wait_timeout（在/etc/preinit 中设置,默认为 2s）
如果在等待时间内用户按下指定的按键，则表示要进入 failsafe 模式。接着再检测文件/tmp/failsafe_button 
是否存在，如果存在则表示要进入 failsafe 模式（该文件可通过设备上的实体按键来创建）。
如果要进入 failsafe 模式，则设置全局变量 FAILSAFE=true

run_failsafe_hook（/lib/preinit/40_run_failsafe_hook）
如果全局变量 FAILSAFE=true，则执行 failsafe 这类函数。

indicate_regular_preinit（/lib/preinit/50_indicate_regular_preinit）
设置 LED，指示进入正常模式

do_mount_root（/lib/preinit/80_mount_root）
执行/sbin/mount_root 挂载根文件系统，该命令来自于 Openwrt 软件包 package/system/fstools。  

indicate_failsafe（/lib/preinit/10_indicate_failsafe）
设置 LED,指示进入 failsafe 模式

failsafe_netlogin（/lib/preinit/99_10_failsafe_login）
启动 Telnet 服务器（telnetd）

failsafe_shell（/lib/preinit/99_10_failsafe_login）
启动 shell
```

#### /sbin/procd

init创建的另一个进程先调用了"/sbin/procd", "-h", "/etc/hotplug-preinit.json"，在其结束前又回调spawn_procd函数  再次执行/sbin/procd并且把继承1号id。

proced*/prod.c 中的 main 函数如下：

```c
int main(int argc, char **argv)
{
//…………
 //未带参数执行/sbin/procd 直接执行到这里
procd_state_next(); // 该函数在同目录的stat.c中，调用 state_enter
// …………
}
```

proced*/state.c中state_enter 函数如下：state_enter 函数根据不同的状态，执行相应的操作

```c
static void state_enter(void)
{
        char ubus_cmd[] = "/sbin/ubusd";

        switch (state) {
        case STATE_EARLY:				//STATE_EARLY状态 - init前准备工作
                LOG("- early -\n");  
                watchdog_init(0);		//初始化watchdog
                hotplug("/etc/hotplug.json"); //根据"/etc/hotplug.json"规则监听hotplug
                procd_coldplug(); //把/dev挂载到tmpfs中，fork udevtrigger进程产生冷插拔事件，以便让hotplug监听进行处理。udevstrigger进程处理完成后回调procd_state_next()函数把状态从STATE_EARLY转变为下一个状态
                break;

        case STATE_UBUS:
                // try to reopen incase the wdt was not available before coldplug
                watchdog_init(0);
                set_stdio("console");
                LOG("- ubus -\n");
                procd_connect_ubus(); //连接ubusd，此时实际上ubusd并不存在，所以procd_connect_ubus函数使用了定时器进行重连，而uloop_run()需在初始化工作完成后才真正运行。当成功连接上ubusd后，将注册servicemain_object对象，system_object对象、watch_event对象
                service_init();//初始化services（服务）和validators（服务验证器）全局AVL tree
                service_start_early("ubus", ubus_cmd);//把ubusd服务加入services管理对象中
                break;

        case STATE_INIT:			//STATE_INIT状态 - 初始化工作
                LOG("- init -\n");
                procd_inittab();	//根据/etc/inittab内容把cmd、handler对应关系加入全局链表actions中。inittab后面详细分析
//顺序加载respawn、askconsole、askfirst、sysinit命令
                procd_inittab_run("respawn");
                procd_inittab_run("askconsole");
                procd_inittab_run("askfirst");
                procd_inittab_run("sysinit");//sysinit命令把/etc/rc.d/目录下所有启动脚本执行完成后将回调rcdone()函数把状态从STATE_INIT转变为STATE_RUNNING

                // switch to syslog log channel
                ulog_open(ULOG_SYSLOG, LOG_DAEMON, "procd");
                break;

        case STATE_RUNNING:		//进入STATE_RUNNING状态后procd运行uloop_run()主循环
                LOG("- init complete -\n");
                break;

        case STATE_SHUTDOWN:
                /* Redirect output to the console for the users' benefit */
                set_console();//将输出重定向到控制台
                LOG("- shutdown -\n");
                procd_inittab_run("shutdown");
                sync();
                break;
         
        case STATE_HALT:
                // To prevent killed processes from interrupting the sleep
                signal(SIGCHLD, SIG_IGN);
                LOG("- SIGTERM processes -\n");
                kill(-1, SIGTERM);
                sync();
                sleep(1);
                LOG("- SIGKILL processes -\n");
                kill(-1, SIGKILL);
                sync();
                sleep(1);
                if (reboot_event == RB_POWER_OFF)
                        LOG("- power down -\n");
                else
                        LOG("- reboot -\n");

                /* Allow time for last message to reach serial console, etc */
                sleep(1);

                /* We have to fork here, since the kernel calls do_exit(EXIT_SUCCESS)
                 * in linux/kernel/sys.c, which can cause the machine to panic when
                 * the init process exits... */
                if (!vfork( )) { /* child */
                        reboot(reboot_event);
                        _exit(EXIT_SUCCESS);
                }

                while (1)
                        sleep(1);
                break;

        default:
                ERROR("Unhandled state %d\n", state);
                return;
        };
}
```

##### procd状态

procd的几种个状态，分别为`STATE_EARLY`、`STATE_UBUS`、`STATE_INIT`、`STATE_RUNNING`、`STATE_SHUTDOWN`、`STATE_HALT`，这6个状态将按顺序变化（以前的版本STATE_INIT拆分为STATE_UBUS与STATE_INIT），当前状态保存在全局变量`state`中，可通过`procd_state_next()`函数使用状态发生变化 。后两种状态暂不清楚。

##### inittab脚本分析

在STATE_INIT状态 - 初始化工作中执行inittab的脚本，该脚本在`package/base-files/files/etc/inittab`

在系统中的/etc目录下。

 如果存在/etc/inittab文件，按照它的指示创建各种子进程，否则使用默认的配置创建子进程。 

/etc/inittab文件中每个条目用来定义一个子进程，并确定它的启动方法，格式如下
< id> : < runlevels>:< action>:< process>
1、id:表示这个子进程要使用的控制台，如果省略，则使用与procd进程一样的控制台.
2、runlevels:这个字段没有意义，可以省略。在linux有意义.
3、action:表示procd进程如何控制这个子进程，具体取值见下表.
4、process:要执行的程序，它可以是可执行程序，也可以是脚本.如果process字段前有“-”字符，这个程序被称为“交互的”

【action取值】

| 名称         | 执行条件                | 说明                                                         |
| ------------ | ----------------------- | ------------------------------------------------------------ |
| sysinit      | 系统启动后最先执行      | 指定初始化脚本路径，只执行一次，procd进程等待它结束才继续执行其它动作 |
| wait         | 系统执行完sysinit进程后 | 只执行一次，procd进程等待它结束才继续执行其它动作            |
| once         | 系统执行完wait进程后    | 只执行一次，procd进程不等待它结束                            |
| respawn      | 启动完once进程后        | procd进程监测发现子进程退出时，重新启动它，永远不结束，如shell命令解释器 |
| askfirst     | 启动完respawn进程后     | 与respawn类似，不过procd进程先输出"Please press Enter to activate this console"，等用户输入回车后才启动子进程 |
| shutdown     | 系统关机时              | 即重启、关闭系统时执行的程序                                 |
| restart      | 系统重启时              | procd进程重启执行的程序，通常是procd程序本身先读取、解析inittab文件在执行restart程序 |
| ctrl+alt+del | 按下ctrl+alt+del        | 按下ctrl+alt+del组合键时执行的程序                           |

例如inittab内容如下:

```bash
::sysinit:/etc/init.d/rcS S boot
::shutdown:/etc/init.d/rcS K shutdown
::askconsole:/bin/login				#需要输入用户名与密码
ttyATH0::askfirst:/bin/ash --login  #不需要输入用户名与密码
```

（1）sysinit: 系统初始化路径，执行启动脚本，顺便记录日志。启动脚本会包括执行/etc/rc.d 目录下以 S 开头的文件，执行文件里的 boot 参数。

（2）shutdown：系统终止脚本，执行 /etc/rc.d 目录下以 K开头的文件，给文件赋予shutdown指令。

（3）askconsole： 串口密码登录

（4）ttyATH0: 向串口输出信息，包括道路信息，askfirst节省会话资源，按下一个键后激活。会显示

 **sysinit命令把/etc/rc.d/目录下所有启动脚本执行完成后将回调rcdone()函数把状态从STATE_INITl转变为**

**STATE_RUNNING** 

从上面的分析可以看出它在开机启动的时候执行/etc/init.d/rcS脚本，以前是有/etc/init.d/rcS脚本的，现在的openwrt已经去掉了这个脚本文件，只要有rcSSboot这几个参数就可以，但是功能是有的就是按顺序执行/etc/rc.d下面的各个脚本，以S开头代表启动的时候执行的脚本，与命令行中的S对应，以K开头的代表关机的时候需要执行的脚本，与命令行中的K对应。

 [关于init.d/目录下的启动脚本](https://blog.csdn.net/hzlarm/article/details/103028193 )

源码proced*/inittab.c中

procd_inittab()的源码不贴了，这个函数用正则表达式解析inittab每一行，这里我们只关注第一行sysinit的解析结果：

得到的action为sysinit，argv为{"/etc/init.d/rcS", "S", "boot"}

回到STATE_INIT状态机，最后运行了procd_inittab_run("sysinit");

再看procd_inittab_run源码：

```c

static void runrc(struct init_action *a) 
{
        if (!a->argv[1] || !a->argv[2]) {
                ERROR("valid format is rcS <S|K> <param>\n");
                return;
        }   
        /* proceed even if no init or shutdown scripts run */
        if (rcS(a->argv[1], a->argv[2], rcdone))
                rcdone(NULL);
}

static struct init_handler handlers[] = { 
        {   
                .name = "sysinit",
                .cb = runrc,
        }, {
                .name = "shutdown",
                .cb = runrc,
        }, {
                .name = "askfirst",
                .cb = askfirst,
                .multi = 1,
        }, {
                .name = "askconsole",
                .cb = askconsole,
                .multi = 1,
        }, {
                .name = "respawn",
                .cb = rcrespawn,
                .multi = 1,
        }
    //........ 
};

void procd_inittab_run(const char *handler)
{
        struct init_action *a; 

        list_for_each_entry(a, &actions, list)
                if (!strcmp(a->handler->name, handler)) {
                        a->handler->cb(a);
                        if (!a->handler->multi)
                                break;
                }   
}
```

所以，这里就相当于运行了runrc，runrc再调用rcS，rcS()函数调用/etc/rc.d/下面所有文件名以S开头（就是刚才解析/etc/inittab文件得到的argv[1]）的脚步，调用参数为"boot"（也就是argv[2]）。

在 procd 执行`/etc/rc.d/S*`时，其参数为"boot"（例如：`/etc/rc.d/S00sysfixtime boot`），这样就会执行
每个脚本里面的 boot 函数，也肯能是间接执行 stat 函数。/etc/rc.d/下的所有脚本都是链接到/etc/init.d/下的脚本。下面
分析几个重要的脚本。

S10boot :
调用 uci_apply_defaults 执行第 1 次开机时的 UCI 配置初始化工作。该函数执行/etc/uci-defaults/下的
所有脚本，执行成功后就删除。因此该目录下的脚本只有第一次开机才会执行。

S10system：
根据 UCI 配置文件/etc/config/system 配置系统，具体可参考该配置文件。

S11sysctl：
根据/etc/sysctl.conf 设置系统配置（[ -f /etc/sysctl.conf ] && sysctl -p -e >&-）。 

S19firewall：
启动防火墙 fw3。该工具来自 Openwrt 软件包 package/network/config/firewall

 S20network：
根据 UCI 配置文件/etc/config/network，使用守护进程/sbin/netifd 来配置网络。

S95done：

调用mount_root，set leds to normal state ，以及调用rc.local。

#### 最后总结

uboot -----> start_kernel -----> rest_init -----> kernel_init ----->  /etc/preinit  -----> /sbin/init   -----> （/sbin/procd      ----->   /etc/inittab   ----->   /etc/rc.d/S* -----> /sbin/procd作为pid为1的守护进程）&&  （ /etc/preinit  ----->  /lib/preinit/*  ----->结束）

