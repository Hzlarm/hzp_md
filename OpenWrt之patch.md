OpenWrt使用的是quilt工具来制作补丁非传统的diff

[diff和quilt使用方法参考博客]( https://blog.csdn.net/hzlarm/article/details/103179953 )

[官方quilt文档]( https://openwrt.org/docs/guide-developer/build-system/use-patches-with-buildsystem )


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

```pach
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



