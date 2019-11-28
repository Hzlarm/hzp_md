### git 添加ssh秘钥

##### 检查现有秘钥 ：
​	打开 Git Bash。`ls -al ~/.ssh`  
​	默认为：id_rsa.pub 或者 id_ecdsa.pub 或者 id_ed25519.pub
​	如果提示不存在则重新生成秘钥
##### 生成新 SSH 密钥
​	打开 Git Bash。`ssh-keygen -t rsa -b 4096 -C "xxx@xxx.com"`
​	三次回车：
​		1，回车默认文件即可 2、3回车默认无密码

##### 将 SSH 密钥添加到 GitHub 帐户。
​	`clip < ~/.ssh/id_rsa.pub`   //复制秘钥
​	添加到github中的管理ssh秘钥
​	
​	
[官网添加SSH key](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)

#### 出现多个git秘钥时候

一个公司的git服务器，一个自己的github。

添加自己的github则

先按照上面的方式生成秘钥，需要指定名字否则会覆盖公司git秘钥。这里起名id_rsa_github。把秘钥添加到github。

 `vi ~/.ssh/config`
```bash
Host github
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_rsa_github
```

` ssh -T git@github`  //测试是否成功

```bash
ssh-agent -s 
ssh-agent bash
ssh-add ~/.ssh/id_rsa_github 
```

在github创建一个新的空仓库

```bash
#在本地创建仓库
or create a new repository on the command line
echo "# test" >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin git@github.com:Hzlarm/test.git
git push -u origin master
```

成功！
