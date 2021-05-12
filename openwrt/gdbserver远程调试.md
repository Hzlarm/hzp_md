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
	单独编译包时  ==(建议)==
	`make package/xxxxx/{clean,compile} V=s STRIP=/bin/true CONFIG_DEBUG=y`

或者:
	使能debug选项：make menuconfig
	`Global build settings > Compile packages with debugging info`


#### 第三步 
将编译好的固件传到目标板上，并安装。
```sh
tftp -gr gdbserver_8.3.1-1_mipsel_24kc.ipk 192.168.5.55
tftp -gr xxx.ipk 192.168.5.55

opkg install gdbserver_8.3.1-1_mipsel_24kc.ipk
opkg install xxx.ipk
```

#### 第四步
在目标板上(OpenWRT路由）上开启gdbserver
`gdbserver :9000 /bin/hellogdb`

`gdbserver --once --remote-debug  :9000 /usr/bin/hellogdb`

#### 第五步
在编译主机上开启gdb(假如调试 hellogdb)
`./scripts/remote-gdb 192.168.x.x:9000 ./build_dir/target-*/hellogdb/hellogdb`

`./scripts/remote-gdb 192.168.5.84:9000 ./build_dir/target-mipsel_24kc_musl/xxx/xx`


