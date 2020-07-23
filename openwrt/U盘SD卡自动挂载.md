#### U盘的自动挂载卸载

> Hotplug一个常见的实例应用就是U盘或SD卡等外设的自动挂载和卸载功能。所以这里我们主要介绍如何利用hotplug实现U盘，移动硬盘等外设自动挂载的方法和原理。本文中的例子还需要根据实际情况作相应适配。当然，首先得内核有相应的驱动程序支持才行。当U盘插入后，会产生uevent事件，hotplug收到这个内核广播事件后，根据uevent 事件json格式的附带信息内容，在hotplug.json中进行定位。事件包含的信息一般为如下所示：
> ACTION(add), DEVPATH(devpath), SUBSYSTEM(block), MAJOR(8), MINOR(1), DEVNAME(devname), DEVTYPE(devtype), SEQNUM(865)
> 根据上面的信息，就可以在hotplug.json中定位到两个条目，如上面hotplug.json中蓝色显示字段。第一个条目执行的是makedev，该命令会创建设备节点。第二个条目会根据附带信息中的ACTION, DEVPATH, SUBSYSTEM, DEVNAME, DEVTYPE 等变量，调用命令exec去执行hotplug-call脚本。于是 hotplug-call 会尝试执行 /etc/hotplug.d/block/ 目录下的所有可执行脚本。所以我们可以在这里放置我们的自动挂载/卸载处理脚本。 例如，编写/etc/hotplug.d/block/30-usbmount,填入以下内容实现U盘自动挂载，卸载：

```bash
#!/bin/sh
 
# Copyright (C) 2009 OpenWrt.org  (C) 2010 OpenWrt.org.cn

env > /tmp/envs_log.log
blkdev=`dirname $DEVPATH`
basename=`basename $blkdev`
device=`basename $DEVPATH`

path=$DEVPATH

if [ $basename != "block" ] && [ -z "${device##sd*}" ]; then

	case "$ACTION" in
	add)
		mkdir -p /mnt/$device
		# vfat & ntfs-3g check
		if  [ `which fdisk` ]; then
			isntfs=`fdisk -l | grep $device | grep NTFS`
			isvfat=`fdisk -l | grep $device | grep FAT`
			isfuse=`lsmod | grep fuse`
			isntfs3g=`which ntfs-3g`
		else
			isntfs=""
			isvfat=""
		fi 
		echo 3 > /proc/sys/vm/drop_caches
		umount -l /dev/$device

		# mount with ntfs-3g if possible, else with default mount
		if [ "$isntfs" -a "$isfuse" -a "$isntfs3g" ]; then
			ntfs-3g -o nls=utf8 /dev/$device /mnt/$device
		elif [ "$isvfat" ]; then
			mount -t vfat -o iocharset=utf8,rw,sync,umask=0000,dmask=0000,fmask=0000 /dev/$device /mnt/$device
		else
			mount /dev/$device /mnt/$device
		fi		
		
	;;
	remove)
		umount -l /dev/$device
		if [ "$?" != "0" ]; then
			umount -l /dev/$device
		fi
		
	;;
	esac

fi

if [ $basename == "block" ] && [ -z "${device##mmcblk*}" ]; then

	case "$ACTION" in
	add)
		mkdir -p /mnt/$device
		# vfat & ntfs-3g check
		if  [ `which fdisk` ]; then
			isntfs=`fdisk -l | grep $device | grep NTFS`
			isvfat=`fdisk -l | grep $device | grep FAT`
			isfuse=`lsmod | grep fuse`
			isntfs3g=`which ntfs-3g`
		else
			isntfs=""
			isvfat=""
		fi 
		echo 3 > /proc/sys/vm/drop_caches
		umount -l /dev/$device
		
		
		# mount with ntfs-3g if possible, else with default mount
		if [ "$isntfs" -a "$isfuse" -a "$isntfs3g" ]; then
			ntfs-3g -o nls=utf8 /dev/$device /mnt/$device
		elif [ "$isvfat" ]; then
			mount -t vfat -o iocharset=utf8,rw,sync,umask=0000,dmask=0000,fmask=0000 /dev/$device /mnt/$device
		else
			mount /dev/$device /mnt/$device
		fi
		
		
	;;
	remove)
		umount -l /dev/$device
		if [ "$?" != "0" ]; then
			umount -l /dev/$device
		fi
	;;
	esac
	
fi
```