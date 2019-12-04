### Git 内部原理

##### git init 初始化目录

当我们执行`gin init`命令时候，Git会创建一个.git目录。几乎所有 Git 存储和操作的内容都位于该目录下。如果你要备份或复制一个库，基本上将这一目录拷贝至其他地方就可以了。

目录结构：

```bash
$ ls
HEAD			#HEAD 文件指向当前分支
config			#包含了项目特有的配置选项
description		#description 文件仅供GitWeb 程序使用，所以不用关心这些内容
hooks/			#包含了一些客户端或服务端钩子脚本
index			#index 文件保存了暂存区域信息
info/			#保存不希望在 .gitignore(全局可执行文件)中管理的忽略模式 (ignored patterns) 。
objects/
refs/
```

> 其实 Git 一开始被设计成供 VCS 使用的工具集而不是一整套用户友好的 VCS，它还包含了许多底层命令，这些命令用于以 UNIX 风格使用或由脚本调用。这些命令一般被称为 “plumbing” 命令（底层命令），其他的更友好的命令则被称为 “porcelain” 命令（高层命令）。

底层命令plumbing：

* [git hash-object](https://git-scm.com/docs/git-hash-object  )  使用命名文件的内容（可以在工作树之外）计算具有指定类型的对象的对象ID值，并可以选择将结果对象写入对象数据库。将其对象ID报告给其标准输出。它用于`git cvsimport`更新索引，而无需修改工作树中的文件。如果未指定type，则默认为“ blob”。 

  -t  ：指定类型（默认值：“ blob”）。

  -w：实际上将对象写入对象数据库。

  --stdin  ：从标准输入设备读取对象。如：`echo 'test content' | git hash-object -w --stdin`

  --stdin-paths ：从标准输入中读取文件名，每行一个，而不是从命令行中读取。

例如：`git hash-object -w test.txt `

这个命令是对文件test.txt的内容生成一个40位的hash值。保存在objects目录下前两位为文件夹名后38位为文件名。参数 `-w` 指示 hash-object 命令存储 (数据) 对象，若不指定这个参数该命令仅仅返回键值。

* [`git cat-file`](https://git-scm.com/docs/git-cat-file  ) 命令显示版本库对象的内容、类型及大小信息。 

  -t ：显示对象类型

  -s ：显示对象大小

  -p ：打印对象内容

  -e ：如果对象存在且有效，命令结束状态返回值为 0 。 

例如：`git cat-file -p a639a4e85d1eadc2836e9c42b249b60f208514d8`

这个命令是解析该 SHA-1值所对应的内容，可以通过重定向写回test.txt原来的内容。 

```bash
git cat-file -p master^{tree}
100644 blob a906cb2a4a904a152e80877d4088654daad0c859 README
100644 blob 8f94139338f9404f26296befa88755fc2598c289 Rakefile
040000 tree 99f1a6d12cb4b6f19c8655fca46c3ecf317074e0 lib
```

masterˆtree 表示 branch 分支上最新提交指向的 tree 对象。请注意 lib 子目录并非
一个 blob 对象，而是一个指向别一个 tree 对象的指针

* [update-index](https://git-scm.com/docs/git-update-index)    修改索引或目录缓存。提到的每个文件都会更新到索引中，并且清除任何`unmerged`或`needs updating`状态。 

 --add ：如果指定的文件不在索引中，则将其添加。默认行为是忽略新文件。 

--cacheinfo ：用于注册不在当前工作目录中的文件。 

例如：

```bash
git update-index --add --cacheinfo 100644 \
83baae61804e65cc73a7201a7252750c76066a30 test.txt
```

指定了文件模式为 100644，表明这是一个普通文件。其他可用的模式
有：100755 表示可执行文件，120000 表示符号链接

* [git write-tree](https://git-scm.com/docs/git-write-tree )  将暂存区域的内容写到 tree 对象

  ```bash
  $ git write-tree
  d8329fc1cc938780ffdd9f94e0d364e0ea74f579
  $ git cat-file -p d8329fc1cc938780ffdd9f94e0d364e0ea74f579
  100644 blob 83baae61804e65cc73a7201a7252750c76066a30 test.txt
  #可以这样验证这确实是一个 tree 对象：
  $ git cat-file -t d8329fc1cc938780ffdd9f94e0d364e0ea74f579
  tree
  ```

* [git commit-tree](https://git-scm.com/docs/git-commit-tree )   创建一个新的提交对象 

























##### Git对象

Git 是一套内容寻址文件系统。从内部来看，Git 是简单的 key-value 数据存储。它允许插入任意类型的内容，并会返回一个键值，通过该键值可以在任何时候再取出该内容。可以通过底层命令 hash-object 来示范这点，传一些数据给该命令，它会将数据保存在 .git 目录并返回表示这些数据的键值。

首先初使化一个 Git 仓库并确认 objects 目录仅仅包含了pack与info这两个空目录，没有其他任何文件。

```bash
echo 'test content' | git hash-object -w --stdin
d670460b4b4aece5915caf5c68d12f560a9fe3e4
```

参数 -w 指示 hash-object 命令存储 (数据) 对象，若不指定这个参数该命令仅仅返回键值。--stdin 指定从标准输入设备 (stdin) 来读取内容，若不指定这个参数则需指定一个要存储的文件的路径。该命令输出长度为 40 个字符的校验和。这是个 SHA-1 哈希值——其值为要存储的数据加上你马上会了解到的一种头信息的校验和。现在可以查看到 Git已经存储了数据

```bash
find .git/objects -type f
.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4
```

可以在 objects 目录下看到一个文件。这便是 Git 存储数据内容的方式——为每份内容生成一个文件，取得该内容与头信息的 SHA-1 校验和，创建以该校验和前两个字符为名称的子目录，并以 (校验和) 剩下 38 个字符为文件命名 (保存至子目录下)。通过 cat-file 命令可以将数据内容取回。该命令是查看 Git 对象的瑞士军刀。传入 -p参数可以让该命令输出数据内容的类型：

```bash
git cat-file -p d670460b4b4aece5915caf5c68d12f560a9fe3e4
test content
```

























