

[github action 基础](https://blog.csdn.net/hzlarm/article/details/113847470) 中提到 `on` 字段指定触发 workflow 的条件，通常是某些事件。

### [配置 workflow 事件](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows#configuring-workflow-events)

常用的配置 workflow 事件如下：

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

#定时触发 https://crontab.guru/ 
#schedule 事件允许在计划的时间触发 workflow。
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

### [主动事件](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows#manual-events)

 主动触发 workflow 要是用   `workflow_dispatch` 事件 。 可以使用 REST API 或从 Actions（操作）选项卡在 GitHub 上运行工作流程。 

[在 GitHub 上点击 Run workflow](https://docs.github.com/cn/actions/managing-workflow-runs/manually-running-a-workflow)

```yaml
#最简单的方式
on: workflow_dispatch
#只需要在 workflow 的页面下点击 Run workflow 按钮即可触发
```

也可以直接在 workflow 中配置事件的自定义输入属性、默认输入值和必要输入。 当工作流程运行时，可以访问 `github.event.inputs` 上下文中的输入值。参考[GitHub Actions 的上下文和表达式语法](https://docs.github.com/cn/actions/reference/context-and-expression-syntax-for-github-actions#github-context)

此示例定义了 `name` 和 `home` 输入，并使用 `github.event.inputs.name` 和 `github.event.inputs.home` 上下文打印。 如果未提供 `home` ，则打印默认值“The Octoverse”。

```yaml
name: Manually triggered workflow
on:
  workflow_dispatch:
    inputs:
      name:
        description: 'Person to greet'
        required: true
        default: 'Mona the Octocat'
      home:
        description: 'location'
        required: false
        default: 'The Octoverse'

jobs:
  say_hello:
    runs-on: ubuntu-latest
    steps:
    - run: |
        echo "Hello ${{ github.event.inputs.name }}!"
        echo "- in ${{ github.event.inputs.home }}!"
```

在 GitHub 上触发事件时，可以在 GitHub 上直接提供 `ref` 和任何 `inputs`。[对操作使用输入和输出](https://docs.github.com/cn/actions/learn-github-actions/finding-and-customizing-actions#using-inputs-and-outputs-with-an-action)





要使用 REST API 触发自定义 `workflow_dispatch` web 挂钩事件，必须发送 `POST` 请求到 GitHub API 端点，并提供 `ref` 和任何必要的 `inputs`。 更多信息请参阅“[创建工作流程调度事件](https://docs.github.com/cn/rest/reference/actions/#create-a-workflow-dispatch-event)”REST API 端点。







  repository_dispatch:
  workflow_dispatch:
    inputs:
      ssh:
        description: 'SSH connection to Actions'
        required: true
        default: 'false'





 [`repository_dispatch`](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows#)

| Web 挂钩事件有效负载                                         | 活动类型 | `GITHUB_SHA`         | `GITHUB_REF` |
| :----------------------------------------------------------- | :------- | :------------------- | :----------- |
| [repository_dispatch](https://docs.github.com/cn/webhooks/event-payloads/#repository_dispatch) | n/a      | 默认分支上的最新提交 | 默认分支     |

**注：**仅当工作流程文件在默认分支上时，此事件才会触发工作流程运行。

当您想要触发在 GitHub 外发生的活动的工作流程时，可以使用 GitHub API 触发名为 [`repository_dispatch`](https://docs.github.com/cn/webhooks/event-payloads/#repository_dispatch) 的 web 挂钩事件。 更多信息请参阅“[创建仓库调度事件](https://docs.github.com/cn/rest/reference/repos#create-a-repository-dispatch-event)”。

要触发自定义 `repository_dispatch` web 挂钩事件，必须将 `POST` 请求发送到 GitHub API 端点，并提供 `event_type` 名称来描述活动类型。 要触发工作流程运行，还必须配置工作流程使用 `repository_dispatch` 事件。

[示例](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows#示例-1)

默认情况下，所有 `event_types` 都会触发工作流程运行。 您可以限制工作流程在 `repository_dispatch` web 挂钩有效负载中发送特定 `event_type` 值时运行。 创建仓库调度事件时定义在 `repository_dispatch` 有效负载中发送的事件类型。

```yaml
on:
  repository_dispatch:
    types: [opened, deleted]
```

 [Web 挂钩事件](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows#webhook-events)

您可以将工作流程配置为在 GitHub 上创建 web 挂钩事件时运行。 某些事件有多种触发事件的活动类型。 如果有多种活动类型触发事件，则可以指定哪些活动类型将触发工作流程运行。 更多信息请参阅“[web 挂钩](https://docs.github.com/cn/webhooks)”。







[详细事件列表参考](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows)