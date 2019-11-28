#### [Openwrt GNU Debugger(GDB)](https://openwrt.org/docs/guide-developer/gdb)

#### 第一步
首先`make menuconfig`,  选择gdb相关选项。

添加 gdb。(可以在路由器开发板调试，空间有限所以不建议)。
`Advanced configuration options (for developers) → Toolchain Options → Build gdb`

添加 gdbserver
`Development → gdbserver` 如果位置不一样`/`搜一下找到对应位置
#### 第二步
在需要调试的包（package)的Makefile增加调试选项
	`TARGET_CFLAGS += -ggdb3`
或者：
	单独编译包时 
	`make package/xxxxx/{clean,compile} V=s CONFIG_DEBUG=y`

或者:
	使能debug选项：make menuconfig
	`Global build settings > Compile packages with debugging info`


#### 第三步 
在目标板上(OpenWRT路由）上开启gdbserver
`gdbserver :9000 /bin/hellogdb`

#### 第四步
在编译主机上开启gdb(假如调试 hellogdb)
`./scripts/remote-gdb 192.168.x.x:9000 ./build_dir/target-*/hellogdb/hellogdb`




