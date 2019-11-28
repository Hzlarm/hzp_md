[GPIO基础]( https://blog.csdn.net/hzlarm/article/details/103120139 
)

在Linux中使用GPIO例子
导出一个引脚的操作步骤



1、首先计算此引脚编号。

引脚编号 = 控制引脚的寄存器基数 + 控制引脚寄存器位数



　　举个例子（具体 GPIO 需要参考数据手册），如果使想用 GPIO1_20，那么引脚编号就可能等于 1 x 32 + 20 = 54。



2、向 /sys/class/gpio/export 写入此编号，比如12号引脚，在 shell 中可以通过以下命令实现：

echo 12 > /sys/class/gpio/export

命令成功后生成 /sys/class/gpio/gpio12 目录，如果没有出现相应的目录，说明此引脚不可导出。 

　　 

3、direction 文件，定义输入输入方向，可以通过下面命令定义为输出。

echo out > /sys/class/gpio/gpio12/direction

direction 接受的参数可以是：in、out、high、low。其中参数 high / low 在设置方向为输出的同时，将 value 设置为相应的 1 / 0。 

4、value 文件是端口的数值，为1或0，通过下面命令将 gpio12 设置为高电平。

echo 1 > /sys/class/gpio/gpio12/value



四、重温几个简单的例子



1、导出

\# echo 44 > /sys/class/gpio/export



2、设置方向



\# echo out > /sys/class/gpio/gpio44/direction

1

3、查看方向



\# cat /sys/class/gpio/gpio44/direction

1

4、设置输出



\# echo 1 > /sys/class/gpio/gpio44/value



5、查看输出值

\# cat /sys/class/gpio/gpio44/value



6、取消导出

\# echo 44 > /sys/class/gpio/unexport



在G1-C中，gpio45是蓝牙驱动开关(G1-B为GPIO19)，设置后使用失败：

因为gpio45为复用io，所以需要修改dts 

`vi target/linux/ramips/dts/Thingoo.dts `

加入：

uart1 {
				ralink,group = "uart1";
				ralink,function = "gpio";
           };