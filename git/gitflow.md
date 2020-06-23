## gitflow

一种规范git工作流的方式web

### gitflow分支功能

主分支：master

开发新特性：delvelop

临时性分支：

- 功能(feature)分支
- 预发布(release)分支
- 修改bug(hotfix)分支

![image-20191127092042042](E:\gateway_git\openwrt-database\note\hzp\git\gitflow.png)

## 1.1 Master

- master分支只有一个。
- master分支上的代码总是稳定的，随时可以发布出去。
- 平时一般不在master分支上操作，当release分支和hotfix分支合并代码到master分支上时，master上代码才更新。
- 当仓库创建时，master分支会自己创建。



## 1.2 Develop

- develop分支只有一个
- 新特性的开发是基于develop分支的，但不直接在develop分支下开发，特性是在feature分支上进行的。
- 当develop分支上足够可以发布新版本是，可以创建release分支。



## 1.3 Feature

- 可以同时存在多个feature分支，新特性的开发就在此分支上面。
- 可以对每个新特性创建一个新的feature分支，当新特性开发完毕时，将次feature分支合并到delvelop分支下。
- 创建一个feature分支代码如下：

```
git flow feature start test
```

执行完此命令后，feature分支会被创建。

当新特性开发完，需要将此分支合并到delvelop分支，

```
git flow feature finish test
```

上面的命令会将feature/test分支的内容merge到delvelop分支下，并将feature/test分支删除。

feature分支只会存在本地代码库，如果需要多人共同开发此特性，也可以将feature分支推到远程仓库。

```
git flow feature publish test
git push origin develop
```

feature分支的生命周期持续到特性开发完毕，当你开发完毕后，可以用git命令删除。



## 1.4 Release

- 当完成特性的开发，并且将feature分支内容merge到delvelop分支上，这时可以着手准备新版本的发布，创建release分支测试。
- release分支是基于delvelop分支下，同一时间内只有一个release分支，其生命周期较短，只是为了发布使用。所以只能进行较少代码修正。比如bug修复、完善优化。

通过以下命令来创建release分支：

```
git flow release start v1.0
```

执行过完上面的命令，release分支下release/v1.0会被创建出来，并切换到release分支下：

```
git flow release finish v1.0
```

这个命令会执行以下的操作：

- 分支release/v.1.0 merge回master分支
- 使用release/v.1.0分支名称打tag
- 分支release/v.1.0 merge回develop分支
- 删除release/v.1.0分支



git flow init 

git flow release start v1.0

git flow release finish v1.0

git push origin --tags



## 1.5 Hotfix

- 当发现master分支出现一个紧急需要修复的bug，可以使用hotfix分支，hotfix分支是基于maser分支下的。当完成bug修复后，将其merge到master分支上。
- 同一时间只有一个hotfix分支，生命周期较短。

可以使用一下命令创建hotfix分支。

```
git flow hotfix start test
```

使用以下命令结束hotfix分支的生命周期。

```
git flow hotfix finish test
```

- 这句命令会将hotfix分支merge到master分支和release分支，并删除该hotfix分支。
- 值得注意的是，如果bug修复时，正存在着release分支，那么hotfix分支会merge到release分支，而不是develop分支。

#### 安装gitflow

在Windows上安装，对于Windows用户，推荐使用Windows版Git，按照[Windows版Git主页](https://git-for-windows.github.io/)上的说明安装Windows版Git。从适用于Windows 2.6.4的Git开始，已包含GitFlow（AVH版），因此您已完成所有工作。

在Linux上安装,` apt-get install git-flow`

#### 使用git flow

* 初始化`git flow init`

  ```bash
  Initialized empty Git repository in C:/Users/Administrator/Desktop/gitflow/.git/
  No branches exist yet. Base branches must be created now.
  Branch name for production releases: [master]
  Branch name for "next release" development: [develop]
  
  How to name your supporting branch prefixes?
  Feature branches? [feature/]
  Bugfix branches? [bugfix/]
  Release branches? [release/]
  Hotfix branches? [hotfix/]
  Support branches? [support/]
  Version tag prefix? []
  Hooks and filters directory? [C:/Users/Administrator/Desktop/gitflow/.git/hooks]
  ```

  



Git Flow流程开发流程：以发布为中心

一个较为复杂的开发分支流程：
    可分为：master主干分支、hotfix修复BUG分支、release发布分支、develog开发分支、feature特性分支
    一般可以采取的做法为：
        master主干分支：用于打Tag标签(对应某个release发布分支,并不是每个Tag标签一定对应一个release发布分支，hotfix分支也可以合并到master分支以产生对应一个Tag标签)，
        此外，一般release产生Tag标签如1.0->2.0,而hotfix产生的Tag标签则如0.1->0.2，其必须保证可以正常运行
        hotfix修复BUG分支：应只负责修复master分支时的BUG，修复BUG时从master主干分支创建hotfix分支，修复后合并到master分支再打新的Tag标签、以及合并到develop分支
        release发布分支：主要用于发布版本，当然也可以修复某些个BUG,若是修复某些BUG则可以在必要时合并到master主干分支再打新的Tag标签，
        以及合并到develop分支,这个分支一般不做功能增改、只需要关注小BUG修改和合并等事宜
        develop分支：一直处于开发状态，其为代码中心分支，包括自身BUG修复，或者从其创建feature特性分支以在特性分支上添加新的功能，当develop分支到合适时候可以合并
        发布到release分支，并以此release发布分支合并到master分支再打Tag标签
        feature特性分支：主要增加新的功能特性，从develop分支创建并完成后需要与develop分支合并，此后便可删除该特性分支，一般情况下feature特性分支可能有多个。
    以上的这些分支中：一般使用项目的用户可能使用master分支或者release发布分支，开发者用户一般使用到feature、hotfix、develop分支
    这些分支中，master、develop分支最重要。发者还需要记住当前所处的分支以及各个分支的状态、创建、合并分支等操作。
    

    鉴于以上手动操作的复杂性：建议使用辅助工具git-flow，帮助管理,减少操作出错

git-flow流程：

    0. github上创建远程仓库
    1. git clone该仓库到本地
    2. 进入该仓库所在目录，使用git flow来初始化默认仓库设置 git flow init -d，-d参数此会默认产生master、develop这两个分支
    3. 同样地在远程仓库创建develop分支(以分支develop设置为跟踪来自origin的远程分支develop) git push -u origin develop
    4. 后面的操作便是其他开发者fork或者git clone到其本地仓库进行修改develop分支，对该分支进行操作前应先git pull最新github上
       的develop代码，此后再进行开发，修改完成后可以git push操作或者Pull Request操作
       步骤：
    　　　　0. git clone 远程的develop分支到本地仓库
      　　　1. git pull 获取最新源码(第一次git clone时已为最新源码)
           2. git flow feature start xxx 创建feature分支xxx，xxx一般以有意义的当前实现某功能命名，该分支为feature/xxx
           3. 在新创建的分支中实现功能(包括写代码、提交到本地特性仓库)后并提交到远程对应的特性仓库 git push origin feature/xxx
              此操作后，可在github上创建Pull Request合并到develop分支请求(可在github上设置默认处理发送请求的分支，一般为develop分支)
           4. 审查该Pull Request合并请求，若没有问题，可将其与develop分支合并，否则反馈问题该请求给提交者
           5. 基本上若有问题需要返工则可能会重复3.4步骤直到可以满足合并的要求便可关闭该请求，或者拒绝时也可以直接关闭该请求
              一般反馈的问题可能有：没有测试或者测试未通过、编码规范不到位、代码质量不高、还可以重构、有重复的部分等
           6. 请求合并后，提交者若要进行新的功能开发，应先更新本地develop分支，然后再从最新的develop分支重新创建新的特性分支
              进行开发，git checkout develop，git pull，git flow feature start feature-other,git push origin feature/feature-other
           7. 重复创建特性分支提交分支、合并分支、更新develop分支到一定适合时便可发布，此时使用到release分支，创建release分支
              git checkout develop，git pull，git flow release start '1.0.0',创建发布分支release/1.0.0
           8. 在release分支中可以修复bug或者结束发布分支与develop分支合并 git flow release finish ‘1.0.0’,此后便会输入一系列信息
              包括合并到当前develop分支、删除release/1.0.0分支、对应release分支打tag标签(git tag 可查看)、合并到master分支并打相同
              标签、切回到develop分支
           9. 提交develop分支到远程develop仓库，git push origin develop
           10. 切换到master分支，并提交master分支到远程master仓库并push标签信息，git checkout master，git push origin master, 
               git push --tags
           11. 如果master分支或者发布版本的标签分支出现突发BUG，需要紧急修复，此时需要从该master或某tag标签下分支下创建hotfix分支，
               如：以tag 1.0.0创建hotfix分支1.0.1: git flow hotfix start '1.0.1' '1.0.0'
           12. 完成修改后，便可提交到远程仓库中，git flow hotfix finish '1.0.1'(此会使得其自动合并到本地master和develop分支中)，
               git push origin master,git push origin develop
           13. 创建tag 1.0.1，需要在github的release中draft a new release创建，此后本地仓库可以更新并查看tag，git fetch origin，
               git tag

　以上这些流程，建议时常查看a-successful-git-branching-model开发流程图，以便于理解流程内容；
　website：http://nvie.com/posts/a-successful-git-branching-model/










