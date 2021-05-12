# github action 基础

### 简介

>  [GitHub Actions](https://github.com/features/actions) 是 Microsoft 收购 GitHub 后推出的持续集成 (Continuous integration，简称 CI) 服务，它提供了配置非常不错的虚拟服务器环境，基于它可以进行构建、测试、打包、部署项目。简单来讲就是将软件开发中的一些流程交给云服务器自动化处理，比方说开发者把代码 push 到 GitHub 后它会自动测试、编译、发布。有了持续集成服务开发者就可以专心于写代码，这样可以大大提高开发效率。  
>
>  GitHub Actions 为每个任务 (job) 都提供了一个虚拟机来执行，每台虚拟机都有相同的硬件资源：
>
>  - 2-core CPU
>  - 7 GB RAM 内存
>  - 14 GB SSD 硬盘空间
>
>  使用限制：
>
>  - 每个仓库只能同时支持20个 workflow 并行。
>  - 每小时可以调用1000次 GitHub API 。
>  - 每个 job 最多可以执行6个小时。
>  - 免费版的用户最大支持20个 job 并发执行，macOS 最大只支持5个。
>  - 私有仓库每月累计使用时间为2000分钟，超过后$ 0.008/分钟，公共仓库则无限制。
>
>  操作系统方面可选择 Windows server、Linux、macOS，并预装了大量软件包和工具。 虽然名称叫持续集成，但当所有任务终止和完成时，虚拟环境内的数据会随之清空，并不会持续。即每个新任务都是一个全新的虚拟环境。
>
>  ==[github action 官网参考 ](https://docs.github.com/cn/actions)资料齐全。==

### 基本概念

- **workflow** （工作流程）：持续集成一次运行的过程。
- **job** （任务）：一个 workflow 由一个或多个 job 构成，含义是一次持续集成的运行，可以完成多个任务。
- **step**（步骤）：每个 job 由多个 step 构成，一步步完成。
- **action** （动作）：每个 step 可以依次执行一个或多个命令（action）。

###  workflow 文件

 GitHub Actions 的配置文件叫做 workflow 文件  ，存放在代码仓库的 `.github/workflows` 目录中 。

 workflow 文件采用 [YAML](https://yaml.org/) 格式，文件名可以任意取，但是后缀名为`.yml`  或者 `.yaml` [官方推荐使用yaml](https://yaml.org/faq.html)。

 一个库可以有多个 work­flow 文件，GitHub 只要发现`.github/workflows` 目录里面有`yaml` 文件，就会按照文件中所指定的触发条件在符合条件时自动运行该文件中的工作流程。 

[GitHub  workflow 语法](https://docs.github.com/cn/actions/reference/workflow-syntax-for-github-actions)

##### name

name 字段 是GitHub在仓库的操作页面上显示 workflow 的名称。如果省略name，默认为当前 workflow 的文件名。

```yaml
name: GitHub Actions hello
```

##### on

on字段指定触发 workflow 的条件，通常是某些事件。[详细事件列表参考](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows)

```yaml
#触发workflow

#push事件触发 
on: push

#on字段也可以是事件的数组。
on: [push, pull_request]

#push 指定分支触发或tag
on:
  push:
    branches:
      - master

on:
  push:
    tags:
    - 'v*'

#定时触发
on:
  schedule:
    - cron: 0 11 * * *

#仓库被 star 时触发
on:
  watch:
    types: [started]

#发布 release 触发
on:
  release:
    types: [published]

```

##### env

环境变量的 `map` 可用于 workflow 中所有 jobs 。也可以在指定的 jobs 中设置。

##### jobs

 `jobs` 字段是 workflow 文件的主体。 表示要执行的一项或多项任务。 

 每一个 `jobs` 字段里面都必须有一个  `job_id`   ， `job_id` 里面的 `name` 字段是任务的名称。`job_id` 不能有空格，只能使用数字、英文字母和 `-` 或`_`符号，而 `name` 可以随意，若忽略 `name` 字段，则默认会设置为 `job_id`。 

```yaml
jobs:
  job_id1:
  job_id2:
    name: second job
```

默认是并行运行。如果需要按顺序执行，则需要 使用 ` <job_id>needs `关键词在其他 jobs 上定义依赖项。

```yaml
#此示例中，job1 必须在 job2 开始之前成功完成，而 job3 要等待 job1 和 job2 完成。
jobs:
  job1:
  job2:
    needs: job1
  job3:
    needs: [job1, job2]

#此示例中，job3 使用 always() 条件表达式，因此它始终在 job1 和 job2 完成后运行，不管它们是否成功。
jobs:
  job1:
  job2:
    needs: job1
  job3:
    if: always()
    needs: [job1, job2]

```

##### runs-on

 `runs-on`  必填字段，指定运行所需要的虚拟机环境。 可以是 [GitHub 托管的运行器](https://docs.github.com/cn/actions/reference/specifications-for-github-hosted-runners) 或自托管的运行器。

[可用的虚拟机以及限制](https://docs.github.com/cn/actions/hosting-your-own-runners/about-self-hosted-runners#usage-limits) 

| 虚拟环境             | YAML 工作流程标签                            |
| :------------------- | :------------------------------------------- |
| Windows Server 2019  | `windows-latest` 或 `windows-2019`           |
| Ubuntu 20.04         | `ubuntu-latest` (see note) or `ubuntu-20.04` |
| Ubuntu 18.04         | `ubuntu-latest` (see note) or `ubuntu-18.04` |
| Ubuntu 16.04         | `ubuntu-16.04`                               |
| macOS Big Sur 11.0   | `macos-11.0`                                 |
| macOS Catalina 10.15 | `macos-latest` 或 `macos-10.15`              |

```yaml
runs-on: ubuntu-18.04
```

##### steps

`steps`字段指定每个 Job 的运行步骤，可以包含一个或多个步骤。 步骤开头使用 `-` 符号。 

jobs 包含一系列任务，称为 `steps`。 步骤可以运行命令、运行设置任务，或者运行您的仓库、公共仓库中的操作或 Docker 注册表中发布的操作。 并非所有步骤都会运行操作，但所有操作都会作为步骤运行。 每个步骤在运行器环境中以其自己的进程运行，且可以访问工作区和文件系统。 因为步骤以自己的进程运行，所以步骤之间不会保留环境变量的更改。 GitHub 提供内置的步骤来设置和完成作业。 

每个步骤都可以指定以下字段:

- `name`：步骤名称，可以忽略 。
- `uses`：该步骤引用的 `action` 或 Docker 镜像。
- `run`：使用操作系统 shell 运行命令行程序。 如果不提供 `name`，步骤名称将默认为 `run` 命令中指定的文本。命令默认使用非登录 shell 运行。 您可以选择不同的 shell，也可以自定义用于运行命令的 shell。 更多信息请参阅“[使用指定 shell](https://docs.github.com/cn/actions/reference/workflow-syntax-for-github-actions#example-running-a-script-using-bash)”。
- `env`：该步骤所需的环境变量。

  `uses` 和 `run` 是必填字段，每个步骤只能选择一个。

##### action

[关于actions](https://docs.github.com/cn/actions/creating-actions/about-actions)

`action` 是 GitHub Ac­tions 中的重要组成部分， 比如抓取代码、运行测试、登录远程服务器，发布到第三方服务等 都属于actions，它是已经编写好的步骤脚本，存放在[官方 action 仓库](https://github.com/actions)或者 [GitHub Marketplace](https://github.com/marketplace?type=actions) 去获取。此外 [Awesome Actions](https://github.com/sdras/awesome-actions) 这个项目收集了很多非常不错的 `action`。

 `action` 是代码仓库，所以也有版本的概念。 使用`userName/repoName`的语法引用 action 。如： `actions/xxx`就表示`github.com/actions/xxx` 

```yaml
steps:
  - uses: actions/setup-node@74bc508 # 指定一个 commit
  - uses: actions/setup-node@v1.2    # 指定一个 tag
  - uses: actions/setup-node@master  # 指定一个分支
```
