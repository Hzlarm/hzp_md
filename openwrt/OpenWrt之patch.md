OpenWrt使用的是quilt工具来制作补丁非传统的diff

[diff和quilt使用方法参考博客](https://blog.csdn.net/hzlarm/article/details/103179953)

[官方quilt文档](https://openwrt.org/docs/guide-developer/build-system/use-patches-with-buildsystem)


准备工作
```bash
cat > ~/.quiltrc <<EOF
QUILT_DIFF_ARGS="--no-timestamps --no-index -p ab --color=auto"
QUILT_REFRESH_ARGS="--no-timestamps --no-index -p ab"
QUILT_SERIES_ARGS="--color=auto"
QUILT_PATCH_OPTS="--unified"
QUILT_DIFF_OPTS="-p"
EDITOR="vim"
EOF
```

================给gdb打补丁修复Remote 'g' packet reply is too long=======================

准备gdb源码以及patch文件

`make  toolchain/gdb/{clean,prepare} V=s QUILT=1`

进入到gdb源码目录

`cd build_dir/toolchain-mipsel_24kec+dsp_gcc-4.8-linaro_uClibc-0.9.33.2/gdb-linaro-7.6-2013.05/`

打上原来的所有补丁

`quilt push -a`

创建新的patch

`quilt new 700-fix-remote-g-packet-reply-too-long.patch`

修改源文件

`quilt edit gdb/remote.c  `

```diff
--- a/gdb/remote.c
+++ b/gdb/remote.c
@@ -6110,8 +6110,19 @@ process_g_packet (struct regcache *regca
   buf_len = strlen (rs->buf);
 
   /* Further sanity checks, with knowledge of the architecture.  */
-  if (buf_len > 2 * rsa->sizeof_g_packet)
-    error (_("Remote 'g' packet reply is too long: %s"), rs->buf);
+  // if (buf_len > 2 * rsa->sizeof_g_packet)
+  //  error (_("Remote 'g' packet reply is too long: %s"), rs->buf);
+  if (buf_len > 2 * rsa->sizeof_g_packet) {
+    rsa->sizeof_g_packet = buf_len;
+    for (i = 0; i < gdbarch_num_regs (gdbarch); i++) {
+      if (rsa->regs[i].pnum == -1)
+        continue;
+      if (rsa->regs[i].offset >= rsa->sizeof_g_packet)
+        rsa->regs[i].in_g_packet = 0;
+      else
+        rsa->regs[i].in_g_packet = 1;
+    }
+  }

```



查看修改前后对比

` quilt diff `

 更新修改到patch文件 

`quilt refresh`

返回buildroot目录

`cd -`

打上新的补丁

`make  toolchain/gdb/update V=s`

重新编译

`make  toolchain/gdb/{clean,compile,install} V=s`



cat ./scripts/remote-gdb

### 示例二：内核打补丁
```shell
make target/linux/{clean,prepare} V=s QUILT=1

cd build_dir/target-mipsel_24kc_musl/linux-ramips_mt76x8/linux-4.14.149/

quilt push -a

#quilt new platform/666-reboot-softreset-2-hardreset-by-GPIO5.patch
quilt new platform/555-reboot-crash-add-m25p_shutdown-to-m25p80.patch


quilt edit drivers/mtd/devices/m25p80.c
#quilt edit kernel/reboot.c
#quilt edit 其他文件

quilt diff

quilt refresh

make target/linux/update V=s  
```

```diff
--- a/drivers/mtd/devices/m25p80.c
+++ b/drivers/mtd/devices/m25p80.c
@@ -313,6 +313,21 @@ static int m25p_remove(struct spi_device
        return mtd_device_unregister(&flash->spi_nor.mtd);
 }
 
+static void m25p_shutdown(struct spi_device *spi)
+{
+        struct m25p        *flash = spi_get_drvdata(spi);
+
+        if ((&flash->spi_nor)->addr_width > 3) {
+                printk(KERN_INFO "m25p80: exit 4-byte address mode\n");
+                flash->command[0] = SPINOR_OP_EX4B;  // exit 4-byte address mode: 0xe9
+                spi_write(flash->spi, flash->command, 1);
+                flash->command[0] = 0x66;  // enable reset
+                spi_write(flash->spi, flash->command, 1);
+                flash->command[0] = 0x99;  // reset
+                spi_write(flash->spi, flash->command, 1);
+        }
+}
+
 /*
  * Do NOT add to this array without reading the following:
  *
@@ -387,6 +402,7 @@ static struct spi_driver m25p80_driver =
        .id_table       = m25p_ids,
        .probe  = m25p_probe,
        .remove = m25p_remove,
+    .shutdown = m25p_shutdown,
 
        /* REVISIT: many of these chips have deep power-down modes, which
         * should clearly be entered on suspend() to minimize power use.
```





