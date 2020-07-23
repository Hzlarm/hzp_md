### Git基本常用命令如下：

**全局设置**

第一个要配置的是你个人的用户名称和电子邮件地址。这两条配置很重要，每次 Git 提交时都会引用这两条信息，说明是谁提交了更新，所以会随更新内容一起被永久纳入历史记录

```shell
$ git config --global user.name "xxx"
$ git config --global user.email "xxx@.com"
$ git config --global core.editor vim
```

配置完成之后会在$HOME目录下生成一个.gitconfig配置文件。

`--local` 是将这些内容写入 project 下的 .git/config 文件中，每个project都可以有不同的配置。

设置完新的ssh文件后， windows下每次重新开始起git bash 都要执行以下命令 或者添加到git安装目录的etc/bash.bashrc文件末尾。

```bash
ssh-agent -s 
ssh-agent bash
ssh-add ~/.ssh/id_rsa_github
```



* mkdir：         XX (创建一个空目录 XX指目录名)   
* pwd：          显示当前目录的路径。
* git init          把当前的目录变成可以管理的git仓库，生成隐藏.git文件。    
* git add XX       把xx文件添加到暂存区去。
* git commit –m “XX”  提交文件 –m 后面的是注释。 再次修改后加上-a跳过git add步骤。加--amend  添加到上次提交过程中  push 需要-f
* git status        查看仓库状态
* git diff  XX      查看XX文件修改了那些内容 
* git rm XX          删除XX文件 如果已经add到缓存区域的话加-r删除
* git mv  old new 改名 相当于 mv old new ;git rm old ;git add new

*****

* git checkout -- XX   把XX文件在工作区的修改(删除)全部撤销。同git restore XX
* git reset HEAD 目录   把已经添加到了暂存区的文件退回到工作区，
  ​								再执行上一条命令撤销修改(删除)。同git restore --staged XX
* git reset  --hard HEAD^ 或者 git reset  --hard HEAD~ 回退到上一个版本
  ​                     (如果想回退到100个版本，使用git reset –hard HEAD~100 )
* git 强行pull并覆盖本地文件  `git fetch --all;  git reset --hard origin/master ;git pull`
* git log          可以查看提交历史，以便确定要回退到哪个版本.  
* git log -3 --stat 查看最近3次提交更新所更改的文件及内容
* git reflog       查看历史记录的版本号id,	以便确定要回到未来的哪个版本

****

* git remote add origin url 关联一个远程库   add改为remove取消关联
* git push [remote-name] [branch-name] (第一次要用-u 以后不需要) 如：git push  -u origin hzlarm 把当前hzlarm 分支推送到远程库。`git push origin newxx:xx`提交本地的newxx分支到远程的xx分支。 删除远程分支xx： `git push origin :heads/xx` or `git push origin :xx`
* git clone  url  从远程库中克隆

********

* git checkout –b dev  创建dev分支 并切换到dev分支上 =  git branch dev ;git checkout dev
* `git checkout -b xx origin/xx`  创建一个xx分支关联远程origin/xx
* git branch  查看当前所有的分支
* git checkout master 切换回master分支
* git merge dev    在当前的分支上合并dev分支(把两个分支的最新快照以及二者最新的共同祖先进行三方合并)
* git branch –d dev 删除dev分支 未合并删除失败 用 -D 强行删除
* git branch name  创建分支
* git stash 把当前的工作隐藏起来 等以后恢复现场后继续工作
* git stash list 查看所有被隐藏的文件列表
* git stash apply 恢复被隐藏的文件，但是内容不删除
  	修复bug时，我们会通过创建新的bug分⽀进⾏修复，然后合并，最后删除；
  当⼿头⼯作没有完成时，先把⼯作现场git stash⼀下，然后去修复bug，修复后，再git 
  stash pop，回到⼯作现场
* git stash drop 删除文件
* git stash pop 恢复文件的同时 也删除stash内容
* git remote 查看远程库的信息
* git remote –v 查看远程库的详细信息
* git rebase -i HEAD~2 合并之前两次commit为一次，将第二个pick改为squash



设置dev和origin/dev的链接：
$ git branch --set-upstream dev origin/dev

在本地创建和远程分⽀对应的分⽀，使⽤git checkout -b branch-name origin/branch-name，本地和远程分⽀的名称最好⼀致

建⽴本地分⽀和远程分⽀的关联，使⽤git branch --set-upstream branch-name 
origin/branch-name；





**永远不要衍合那些已经推送到公共仓库的更新。**

如果把衍合当成一种在推送之前清理提交历史的手段，而且仅仅衍合那些永远不会公开的
commit那就不会有任何问题。如果衍合那些已经公开的 commit，而与此同时其他人已经
用这些 commit 进行了后续的开发工作，那就麻烦大了。



私有的小型团队提交

`git push origin master`  提交自己的主分支到远程仓库 ，如果别人在此之前提交过则失败。

`git fetch origin`   获取最新的远程仓库master指针

` git merge origin/master`  把远程仓库的主分支与本地主分支合并。

`git push origin master`  再次提交本地主分支到远程主分支

或者

在分支issue54开发完成后。



`git checkout master` 切换到本地主分支

`git merge issue54` 合并开发分支到本地主分支

`git fetch origin` 和服务器上的数据同步，下载数据

`git merge origin/master`  把远程仓库的主分支与本地主分支合并。

`git push origin master` 提交本地主分支到远程主分支



在分支issue54开发完成后。

`git checkout develop` 切换到本地develop分支

`git merge issue54` 合并开发分支到本地develop分支

`git fetch origin` 和服务器上的数据同步，下载数据

`git merge origin/develop`  把远程仓库的develop分支与本地develop分支合并。

`git push origin develop` 提交本地develop分支到远程develop分支



git fetch从远程分支拉取代码。

fetch常结合merge一起用，git fetch + git merge == git pull
 一般要用git fetch+git merge，因为git pull会将代码直接合并，造成冲突等无法知道，fetch代码下来要git diff orgin/xx来看一下差异然后再合并。



**git clone 含有子模块得项目**

 `git clone --recursive https://github.com/example/example.git `

or

> 1  初始化本地子模块配置文件 
>
>  git submodule init 
>
> 2 更新项目，抓取子模块内容 
>
>  git submodule update 



git建立一个新的空分支
```shell
git checkout  --orphan study
git rm -rf .
git add study.md
git commit -m "第一次记录"
```


git bash 不显示中文 

 `git config --global core.quotepath false `  基本可以解决

 在 git log 时中文依然不能显示，首先试试用 git --no-pager log 能不能显示中文，如果可以，则设置pager为more： git config --global core.pager more  

2.设置 commit log 提交时使用 utf-8 编码，可避免服务器上乱码，同时与linux上的提交保持一致！

git config --global i18n.commitencoding utf-8

git config --global i18n.logoutputencoding **utf-8**

注：

windows系统默认编码为gbk，可改成gbk

如果系统设置了：

export LANG=zh_CN.UTF-8

则日志输出编码设置为utf-8

git config --global i18n.logoutputencoding utf-8

3.在 /etc/profile 中添加：

export LESSCHARSET=utf-8

在试一下问题解决了！







Git仓库维护：

0. Fork或者clone来的仓库，可能与原仓库源码不是最新的，需要时常更新以与原仓库一致
1. Fork某原仓库至github账户下
2. clone该Fork后的仓库至本地仓库
3. 给原仓库设置某个简易的名称，如update-project，并将其作为远程仓库；也即是以update-project作为原仓库的标志符号
   git remote add update-project git@github.com:some-user/some-project.git

4. 从原仓库中(远程仓库)的master分支下获取(拉取fetch)最新源码并与自己本地仓库的分支进行合并
   git fetch update-project
   　　git merge update-project/master

5. 一般在创建特性分支时，一定要确保在最新源码的基础上创建，故先将仓库更新到最新源码状态。