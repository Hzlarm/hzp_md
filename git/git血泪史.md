2020年1月7号 今天记录两个小问题，关于git提交方面。

1、由于提交代码是疏忽大意一个文件少了后缀名，原以为出错没事只需要使用`git commit --amend`就可以不断

修改不断提交。结果在仓库中看到全是我的提交历史。

修改 log历史 反反复复出现n次错误。最后折腾好一会才终于明白。总结如下，

`git log --oneline -5`

查看最近5次commit的简要信息，输出信息为：简短commitID 与commit_message，可以根据需要查看最近n次

的提交。也可以git log -5，输出信息相对详细些，commitID为完整的，这里只需要加上参数--oneline查看简短commitID即可。

`git rebase -i <简短commitID>`

 如果需要修改从上往下第2个commit_message，这里的简短commitID为上面输出信息的第3个，以此类推

在弹出的窗口中，以VIM编辑方式显示了最近两次的提交信息

如果出错了就退出，然后` rm .git/rebase-merge/ -rf`。

 第一个pick不变，其他改为squash。将所有的合并为第一次提交的并且使用第一次的信息

```
p、 pick=使用提交
r、 reword=使用commit，但编辑commit消息
e、 edit=使用提交，但停止修改
s、 squash=使用commit，但混入前一个commit
f、 fixup=类似于“squash”，但放弃此提交的日志消息
x、 exec=使用shell运行命令（行的其余部分）
d、 drop=删除提交
```
==存之后需要强制push上去==  `git push -f` 

没有强制push，按照提示先git pull再push所以导致越改越多。

2、最后只剩自己满意的最后一条了。但是又发现一个问题，自己用的github邮箱是qq号邮箱，公司用的是公司邮箱，提交时没有注意检查，误用了qq邮箱。

所以需要改作者邮箱。因为只有一条commit所以只需要` git commit --amend `修改信息就可以了。但是发现每次改完都没有生效。最后查找到另一个办法才得到解决。 由于我们的主要目的是修改提交者的信息，因此光用 `git commit --amend` 是不够的 需要使用`git commit --amend --author="xxxxx <xxx@xxx.com>" --no-edit`
然后执行 `git rebase --continue` 。提交上去ok。
下次提交前记得一定要检查。
```　bash
$ git config user.name
$ git config user.email
```

值修改一条commit总结。

1、修改最近一次的commit 信息 :`git commit --amend`

2、要修改的commit是倒数第三条：`git rebase -i HEAD~3`

3、执行 `git rebase --continue`

4、执行 `git push -f `推送到服务端。



2020年1月8号 今天记录1个大问题，昨天虽然通过研究干掉了自己因为愚蠢git push上去的一条条垃圾记录 。

但是因为这个仓库是多人共同拥有的，所有强制push上去需要提前告知其他人，在合作伙伴去进行 

pull时候会发生冲突，有的人已经pull过你原来的垃圾记录了，这个时候为了解决冲突他应该强制

pull才可以。但是，所有人都去强制pull，万一有了疏漏就尴尬了，所以为了避免问题。又给我退回

来了。所以仓库里留着七八条我的垃圾记录。尴尬但是不慌，以后提交量多了，估计也没人去看，

也算是给自己上了一课，以后一定要谨慎使用git。