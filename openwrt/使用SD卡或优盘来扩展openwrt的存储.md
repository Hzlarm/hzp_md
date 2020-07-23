#### [官方参考]( https://openwrt.org/docs/guide-user/additional-software/extroot_configuration )

##### 挂载扩展存储脚本：

```bash
#!/bin/sh 
# 一键脚本挂载rootfs到SD卡,u盘则改mmcblk0p1为sda1
umount /dev/mmcblk0p1
mkfs.ext4 /dev/mmcblk0p1 -F
mount /dev/mmcblk0p1 /mnt
tar -C /overlay -cvf - . | tar -C /mnt -xf - 
umount /mnt
block detect > /etc/config/fstab
sed -i s/option$'\t'enabled$'\t'\'0\'/option$'\t'enabled$'\t'\'1\'/ /etc/config/fstab
sed -i s#/mnt/mmcblk0p1#/overlay# /etc/config/fstab
cat /etc/config/fstab
```

#### 制作exroot 需要的前提条件：

首先要使用USB或者 Micro SD 卡槽，需要安装必须的模块内核模块：

SD：`opkg install kmod-sdhci kmod-sdhci-mt7620`，在 /dev 会看到 mmcblk0 文件，就是 Micro SD。

U盘：` kmod-usb-core  kmod-usb-ohci  kmod-usb-uhci  kmod-usb-storage   kmod-usb-storage-extras   kmod-usb2  kmod-usb3   kmod-fs-ext4   kmod-fs-vfat   kmod-scsi-core `，并不是全部必须。

然后再安装一些文件系统相关的软件包。

`block-mount kmod-fs-ext4 e2fsprogs fdisk`

#### 脚本解读(SD为例)

首先是把 SD 卡格式化成 ext4 格式。：`mkfs.ext4 /dev/mmcblk0p1`

然后把现有的文件拷贝到SD卡中。/overlay 目录的意义的可以看后面。

`mount /dev/mmcblk0p1 /mnt ; tar -C /overlay -cvf - . | tar -C /mnt -xf - ; umount /mnt`

创建 mmcblk0p1 的挂载配置，将配置信息(SD卡的UUID，`block info`也可查看)重定向到fstab 文件中并把`/mnt/mmcblk0p1`改为`voerlay`,0改为1。实现自动挂载。

```bash
block detect > /etc/config/fstab;\
sed -i s/option$'\t'enabled$'\t'\'0\'/option$'\t'enabled$'\t'\'1\'/ /etc/config/fstab; \
sed -i s#/mnt/mmcblk0p1#/overlay# /etc/config/fstab; \
cat /etc/config/fstab;
```

`mount /dev/mmcblk0p1 /overlay`

现在可以看到，/overlay 的空间已经增加了。但是这个是时候overlay与文件系统中的内容并不关联，重启之后无论修改那哪个下面的文件，对应的都会发生改变。

`df -h`可以查看是否成功

```bash
#执行block detect得到以下信息重定向到fstab并修改target与enable
#默认配置
config 'global'
        option  anon_swap  '0'
        option  anon_mount '0'
        option  auto_swap  '1'
        option  auto_mount '1'
        option  delay_root '5'
        option  check_fs   '0'
#关于挂载exroot的配置
config 'mount'
        option  target  '/mnt/mmcblk0p1'
        option  uuid    'ac3174ef-7c68-47c1-b3c8-5613d138e9d4'
        option  enabled '0'
```



#### 注意有坑

如果不想使用exroot了，这个时候修改/etc/config/fstab文件中enable为0，重启发现未生效。甚至删除相关配置信息，依然能够挂载。原因是这里修改的fstab并不是openwrt路由器启动所读取的配置文件。查看启动日志可以发现：

openwrt在加载文件系统时，所读取的fstab如下所示：对应的fstab是板载emmc中的配置文件中的fstab

` block: attempting to load /tmp/jffs_cfg/upper/etc/config/fstab`

我们在最开始修改/etc/config/fstab时，修改的就是这个fstab，然后将/overlay下的信息拷贝到SD卡中。配置完成后重启，依然读的是板载emmc中的fstab，然后配置文件中设置是通过SD卡的uuid找到设备挂载为/voerlay。

如果关机重启之前拔掉SD卡则提示`block: extroot: cannot find device with UUID ac3174ef-7c68-47c1-b3c8-5613d138e9d4`5秒内再次尝试，还未找到，则` mount_root: switching to jffs2 overlay`选择板载emmc对应的分区挂载。所以，其实配置文件不修改的情况下，只需要关机拔出SD卡重启即可即可。如想修改文件则需要在未挂载SD卡时修改/etc/config/fstab文件。



### 附录

> /overlay 是什么意思呢？
> OpenWRT 一般使用的文件系统是 SquashFS ，这个文件系统的特点就是：只读。
> 那，一个只读的文件系统，是怎么做到保存设置和安装软件的呢？
> 这里就是使用一个 /overlay 的分区，overlay顾名思义就是覆盖在上面一层的意思。
> 虽然原来的文件不能修改，但我们把修改的部分放在 overlay 分区上，然后映射到原来的位置，读取的时候就可以读到我们修改过的文件了。
> 但为什么要用这么复杂的方法呢？ OpenWRT 当然也可以使用 EXT4 文件系统，但使用 SquashFS + overlay 的方式有一定的优点。
> 首先 SquashFS 是经过压缩的，在路由器这种小型 ROM 的设备可以放下更多的东西。
> 然后 OpenWRT 的恢复出厂设置也要依赖于这个方式。在你捅 Reset 重置的时候，它只需要把 overlay 分区清空就可以了，一切都回到了刚刷进去的样子。
> 如果是 EXT4 文件系统，就只能够备份每个修改的文件，在恢复出厂设置的时候复制回来，十分复杂。
> 当然，SquashFS + overlay 也有它的缺点，修改文件的时候会占用更多的空间。
> 首先你不能够删除文件，因为删除文件实际上是在 overlay 分区中写入一个删除的标识，反而占用更多的空间。
> 另外在修改文件的时候相当于增加了一份文件的副本，占用了双份的空间。