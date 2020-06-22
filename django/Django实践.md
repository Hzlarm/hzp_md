# [官方的投票应用实例](https://docs.djangoproject.com/zh-hans/3.0/intro/tutorial01/)



#### 创建一个项目并进入

`django-admin startproject mysite`  然后`cd mysite`

配置可以远程访问,修改语言和时区

``` python
#vi mysite/settings.py

from django.utils.translation import gettext_lazy as _
LANGUAGES = [
    ('zh-Hans', _('Chinese')),
]

ALLOWED_HOSTS = ['*']

LANGUAGE_CODE = 'zh-Hans'

TIME_ZONE = 'Asia/Shanghai'
```

#### 创建一个应用

`python manage.py startapp polls`

开启服务：

```python
python manage.py runserver 0:8000   #0 是 0.0.0.0 的简写 ,可以远程访问
```

##### 编写视图

```python
#vi polls/view.py

from django.http import HttpResponse


def index(request):
    return HttpResponse("Hello, world. You're at the polls index.")
```

##### 创建URL conf来映射

```python
#vi polls/urls.py

from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
]

```

#####  在根 URL conf 文件中指定我们创建的 `polls.urls` 模块。 

```python
#vi mysite/urls.py

from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('polls/', include('polls.urls')),
    path('admin/', admin.site.urls),
]
#函数 include() 允许引用其它 URLconfs。每当 Django 遇到 include() 时，它会截断与此项匹配的 URL 的部分，并将剩余的字符串发送到 URLconf 以供进一步处理。
#函数 path() 具有四个参数，两个必须参数：route 和 view，两个可选参数：kwargs 和 name
#route 是一个匹配 URL 的准则（类似正则表达式）。当 Django 响应一个请求时，它会从 urlpatterns 的第一项开始，按顺序依次匹配列表中的项，直到找到匹配的项
#view 当Django 找到了一个匹配的准则，就会调用这个特定的视图函数，并传入一个 HttpRequest 对象作为第一个参数，被“捕获”的参数以关键字参数的形式传入
#kwargs  任意个关键字参数可以作为一个字典传递给目标视图函数。
# name   为 URL 取名,在 Django 的任意地方唯一地引用它，尤其是在模板中。这个有用的特性允许你只改一个文件就能全局地修改某个 URL 模式
```

#####  数据库配置

```python
# vi mysite/settings.py

#这个配置文件使用 SQLite 作为默认数据库。Python 内置 SQLite，
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}

#ENGINE -- 可选值有 'django.db.backends.sqlite3'，'django.db.backends.postgresql'，'django.db.backends.mysql'，或 'django.db.backends.oracle'

#如果使用mysql数据库,
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql'
        'NAME': 'name',
        'USER': 'user',
        'PASSWORD': 'password',
        'HOST': 'localhost',
        'PORT': 3306,
        'OPTIONS': {'charset': 'utf8mb4'},
    }
}
```

##### 创建模型

 投票应用中，需要创建两个模型：问题 `Question` 和选项 `Choice`。`Question` 模型包括问题描述和发布时间。`Choice` 模型有两个字段，选项描述和当前得票数。每个选项属于一个问题。 

```python
#vi polls/models.py

from django.db import models

class Question(models.Model):
    question_text = models.CharField(max_length=200)
    pub_date = models.DateTimeField('date published')
    
    def __str__(self):
        return self.question_text
    

class Choice(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    choice_text = models.CharField(max_length=200)
    votes = models.IntegerField(default=0)
    def __str__(self):
        return self.choice_text
    
```



##### 激活模型

首先需要在配置中添加polls应用

```python
# mysite/settings.py
INSTALLED_APPS = [
    'polls.apps.PollsConfig',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]
'''
通常， INSTALLED_APPS 默认包括了以下 Django 的自带应用：
django.contrib.admin -- 管理员站点， 你很快就会使用它。
django.contrib.auth -- 认证授权系统。
django.contrib.contenttypes -- 内容类型框架。
django.contrib.sessions -- 会话框架。
django.contrib.messages -- 消息框架。
django.contrib.staticfiles -- 管理静态文件的框架。
这些应用被默认启用是为了给常规项目提供方便。
不需要的可以直接删除
'''
```



为对应的应用创建数据表： `python manage.py migrate`

 检测模型文件的修改，并且把修改的部分储存为一次 迁移 ： `python manage.py makemigrations polls`

总结改变模型需要这三步：

- 编辑 `models.py` 文件，改变模型。
- 运行 [`python manage.py makemigrations`](https://docs.djangoproject.com/zh-hans/3.0/ref/django-admin/#django-admin-makemigrations) 为模型的改变生成迁移文件。
- 运行 [`python manage.py migrate`](https://docs.djangoproject.com/zh-hans/3.0/ref/django-admin/#django-admin-migrate) 来应用数据库迁移。



### Django管理界面



##### 创建管理员账号

```python
python manage.py createsuperuser
#键入你想要使用的用户名，然后按下回车键：输入邮箱，然后按下回车键输入密码。

```

##### 向管理页面中加入投票应用

```python
#vi polls/admin.py

from django.contrib import admin

from .models import Question

admin.site.register(Question)
```



##### 编写更多视图

在我们的投票应用中，我们需要下列几个视图：

- 问题索引页——展示最近的几个投票问题。
- 问题详情页——展示某个投票的问题和不带结果的选项列表。
- 问题结果页——展示某个投票的结果。
- 投票处理器——用于响应用户为某个问题的特定选项投票的操作。



```python
# vi polls/views.py
#这些使徒可以接收参数
def detail(request, question_id):
    return HttpResponse("You're looking at question %s." % question_id)

def results(request, question_id):
    response = "You're looking at the results of question %s."
    return HttpResponse(response % question_id)

def vote(request, question_id):
    return HttpResponse("You're voting on question %s." % question_id)
```

 把这些新视图添加进 `polls.urls` 模块里，只要添加几个 [`url()`](https://docs.djangoproject.com/zh-hans/3.0/ref/urls/#django.conf.urls.url) 函数调用就行： 

```python
# vi polls/urls.py
from django.urls import path

from . import views

urlpatterns = [
    # ex: /polls/
    path('', views.index, name='index'),
    # ex: /polls/5/
    path('<int:question_id>/', views.detail, name='detail'),
    # ex: /polls/5/results/
    path('<int:question_id>/results/', views.results, name='results'),
    # ex: /polls/5/vote/
    path('<int:question_id>/vote/', views.vote, name='vote'),
]
```



#####  修改视图

```python
# vi polls/views.py
# 首页显示最新的5个问题
from django.http import HttpResponse

from .models import Question

def index(request):
    latest_question_list = Question.objects.order_by('-pub_date')[:5]
    output = ', '.join([q.question_text for q in latest_question_list])
    return HttpResponse(output)

# Leave the rest of the views (detail, results, vote) unchanged
```



##### 增加模板并跟新视图

```html
# vi  polls/templates/polls/index.html
 
 {% if latest_question_list %}
    <ul>
    {% for question in latest_question_list %}
        <li><a href="/polls/{{ question.id }}/">{{ question.question_text }}</a></li>
    {% endfor %}
    </ul>
{% else %}
    <p>No polls are available.</p>
{% endif %}
 
```



```python
# vi polls/views.py
from django.http import HttpResponse
#from django.template import loader
from django.shortcuts import render
from .models import Question


def index(request):
    latest_question_list = Question.objects.order_by('-pub_date')[:5]
    template = loader.get_template('polls/index.html')
    context = {
        'latest_question_list': latest_question_list,
    }
#    return HttpResponse(template.render(context, request))
    return render(request, 'polls/index.html', context)
#render快捷函数   将给定的模板与给定的上下文字典组合HttpResponse在一起，并返回具有该渲染文本的 对象。
#render（request，template_name，context = None，content_type = None，status = None，using = None）
#必须参数request用于生成此响应的请求对象。template_name要使用的模板的全名或模板名称的顺序。如果给出了序列，将使用存在的第一个模板。
#context要添加到模板上下文的值字典。content_type用于结果文档的MIME类型，默认为 'text/html'。status响应的状态码默认为200。using该NAME模板引擎的使用加载的模板。
#我们不再需要导入 loader 和 HttpResponse 。不过如果你还有其他函数（比如说 detail, results, 和 vote ）需要用到它的话，就需要保持 HttpResponse 的导入。
```



##### 抛出404错误

```python
# vi polls/views.py
# 如果指定问题 ID 所对应的问题不存在，这个视图就会抛出一个 Http404 异常。
from django.http import Http404
from django.shortcuts import render

from .models import Question
# ...
def detail(request, question_id):
    try:
        question = Question.objects.get(pk=question_id)
    except Question.DoesNotExist:
        raise Http404("Question does not exist")
    return render(request, 'polls/detail.html', {'question': question})
#为了保证代码正常运行可以暂时 加一个
# vi polls/templates/polls/detail.html 
# {{ question }}
```



##### 关于错误的快捷函数 [`get_object_or_404()`](https://docs.djangoproject.com/zh-hans/3.0/topics/http/shortcuts/#django.shortcuts.get_object_or_404)

 尝试用 [`get()`](https://docs.djangoproject.com/zh-hans/3.0/ref/models/querysets/#django.db.models.query.QuerySet.get) 函数获取一个对象，如果不存在就抛出 [`Http404`](https://docs.djangoproject.com/zh-hans/3.0/topics/http/views/#django.http.Http404) 错误也是一个普遍的流程。Django 也提供了一个快捷函数，下面是修改后的详情 `detail()` 视图代码： 

```python
#vi polls/views.py
from django.shortcuts import get_object_or_404, render
from .models import Question
# ...
def detail(request, question_id):
    question = get_object_or_404(Question, pk=question_id)
    return render(request, 'polls/detail.html', {'question': question})
```

同样  [`get_list_or_404()`](https://docs.djangoproject.com/zh-hans/3.0/topics/http/shortcuts/#django.shortcuts.get_list_or_404) 函数，工作原理和 [`get_object_or_404()`](https://docs.djangoproject.com/zh-hans/3.0/topics/http/shortcuts/#django.shortcuts.get_object_or_404) 一样，除了 [`get()`](https://docs.djangoproject.com/zh-hans/3.0/ref/models/querysets/#django.db.models.query.QuerySet.get) 函数被换成了 [`filter()`](https://docs.djangoproject.com/zh-hans/3.0/ref/models/querysets/#django.db.models.query.QuerySet.filter) 函数。如果列表为空的话会抛出 [`Http404`](https://docs.djangoproject.com/zh-hans/3.0/topics/http/views/#django.http.Http404) 异常 。



##### 去除模板中的硬编码 URL

 在 `polls/index.html` 里编写投票链接时，链接是硬编码的： 

`<li><a href="/polls/{{ question.id }}/">{{ question.question_text }}</a></li>`

 问题在于，硬编码和强耦合的链接，对于一个包含很多应用的项目来说，修改起来是十分困难的。然而，因为你在 `polls.urls` 的 [`url()`](https://docs.djangoproject.com/zh-hans/3.0/ref/urls/#django.conf.urls.url) 函数中通过 name 参数为 URL 定义了名字，你可以使用 `{% url %}` 标签代替它： 

`<li><a href="{% url 'detail' question.id %}">{{ question.question_text }}</a></li>`

 具有名字 'detail' 的 URL 是在如下语句中定义的： 

```python
# vi polls/urls.py
#...
# the 'name' value as called by the {% url %} template tag
path('<int:question_id>/', views.detail, name='detail'),
#...
```

##### 为 URL 名称添加命名空间

```python
#vi polls/urls.py

from django.urls import path

from . import views

app_name = 'polls' #在根 URLconf 中添加命名空间,Django 分辨重名的 URL
urlpatterns = [
    path('', views.index, name='index'),
    path('<int:question_id>/', views.detail, name='detail'),
    path('<int:question_id>/results/', views.results, name='results'),
    path('<int:question_id>/vote/', views.vote, name='vote'),
]
```

然后更改index.html

```python
# vi polls/templates/polls/index.html

#<li><a href="{% url 'detail' question.id %}">{{ question.question_text }}</a></li>
<li><a href="{% url 'polls:detail' question.id %}">{{ question.question_text }}</a></li>

```



##### 编写一个简单的表单

```html
<!-- vi polls/templates/polls/detail.html -->

<h1>{{ question.question_text }}</h1>

{% if error_message %}<p><strong>{{ error_message }}</strong></p>{% endif %}

<form action="{% url 'polls:vote' question.id %}" method="post">
{% csrf_token %}
{% for choice in question.choice_set.all %}
    <input type="radio" name="choice" id="choice{{ forloop.counter }}" value="{{ choice.id }}">
    <label for="choice{{ forloop.counter }}">{{ choice.choice_text }}</label><br>
{% endfor %}
<input type="submit" value="Vote">
</form>
```



#####  创建一个 Django 视图来处理提交的数据 

```python
#vi polls/views.py

from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import get_object_or_404, render
from django.urls import reverse

from .models import Choice, Question
# ...
def vote(request, question_id):
    question = get_object_or_404(Question, pk=question_id)
    try:
        selected_choice = question.choice_set.get(pk=request.POST['choice'])
    except (KeyError, Choice.DoesNotExist):
        # Redisplay the question voting form.
        return render(request, 'polls/detail.html', {
            'question': question,
            'error_message': "You didn't select a choice.",
        })
    else:
        selected_choice.votes += 1
        selected_choice.save()
        # Always return an HttpResponseRedirect after successfully dealing
        # with POST data. This prevents data from being posted twice if a
        # user hits the Back button.
        return HttpResponseRedirect(reverse('polls:results', args=(question.id,)))
```



 当有人对 Question 进行投票后， `vote()` 视图将请求重定向到 Question 的结果界面。让我们来编写这个视图： 

```python
#vi polls/views.py

from django.shortcuts import get_object_or_404, render

def results(request, question_id):
    question = get_object_or_404(Question, pk=question_id)
    return render(request, 'polls/results.html', {'question': question})
```



```html
<!-- vi polls/templates/polls/results.html -->
<h1>{{ question.question_text }}</h1>

<ul>
{% for choice in question.choice_set.all %}
    <li>{{ choice.choice_text }} -- {{ choice.votes }} vote{{ choice.votes|pluralize }}</li>
{% endfor %}
</ul>

<a href="{% url 'polls:detail' question.id %}">Vote again?</a>
```



### 使用通用视图：代码还是少点好

让我们将我们的投票应用转换成使用通用视图系统，这样我们可以删除许多我们的代码。我们仅仅需要做以下几步来完成转换，我们将：

1. 转换 URLconf。
2. 删除一些旧的、不再需要的视图。
3. 基于 Django 的通用视图引入新的视图。



##### 改良 URLconf

```python
# vi polls/urls.py

from django.urls import path

from . import views

app_name = 'polls'
urlpatterns = [
    path('', views.IndexView.as_view(), name='index'),
    path('<int:pk>/', views.DetailView.as_view(), name='detail'),
    path('<int:pk>/results/', views.ResultsView.as_view(), name='results'),
    path('<int:question_id>/vote/', views.vote, name='vote'),
]

```

##### 改良视图





















