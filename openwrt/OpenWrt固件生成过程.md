11.1 Openwrt 固件生成过程（基于 MPR-A2 硬件平台） （1） 编译 Linux 内核生成 vmlinux，并将其拷贝为 vmlinux-mpr-a2
build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/linux-ramips_rt305x/vmlinux-mpr-a2
（2） 使用内核自带的工具 dtc 将 target/linux/ramips/dts/MPRA2.dts 编译成 dtb 格式的 MPRA2.dtb
build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/linux-ramips_rt305x/MPRA2.dtb
（3） 使用 Openwrt 提供的工具 patch-dtb 将上面生成的 MPRA2.dtb 填充到 vmlinux-mpr-a2
（4） 使用 lzma 压缩 vmlinux-mpr-a2，生成 vmlinux-mpr-a2.bin.lzma
build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/linux-ramips_rt305x/vmlinux-mpr-a2.bin.lzma
（5） 使用 u-boot 提供的工具 mkimage 将 vmlinux-mpr-a2.bin.lzma 制作成 vmlinux-mpr-a2.uImage
build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/linux-ramips_rt305x/vmlinux-mpr-a2.uImage
（6） 使用 mksquashfs4 将根文件系统 build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/root-ramips/制 作成 root.squashfs
build_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2/linux-ramips_rt305x/root.squashfs
（7） 使用 dd 命令将 root.squashfs 写入 openwrt-ramips-rt305x-root.squashfs
bin/openwrt-ramips-rt305x-root.squashfs
（8） 使用 cat 命令读取 vmlinux-mpr-a2.uImage 和 root.squashfs，将它们依次写入文件 openwrt-ramips-rt305x-mpr-a2-squashfs-sysupgrade.bin

