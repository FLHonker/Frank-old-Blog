---
layout:     post
title:      使用webbench压力测试Go服务器
subtitle:   介绍一款精致小巧的web压力测试工具，并结合测试实例
date:       2018-05-14
author:     Frank Liu
header-img: img/post-bg-golang2.png
catalog: true
tags:
    - webbench
    - go
    - 服务器
---

# 使用webbench压力测试Go服务器

## 1. Webbench

Webbench是Radim Kolar在1997年写的一个在Linux下使用的非常简单的网站压测工具。它使用fork()模拟多个客户端同时访问我们设定的URL，测试网站在压力下工作的性能，最多可以模拟3万个并发连接去测试网站的负载能力。官网地址:<http://home.tiscali.cz/~cz210552/webbench.html>

### 依赖

ctags

### 安装

Webbench是一个命令行工具，需要自行下载源码编译安装，
源码地址：
[1]github: <https://github.com/EZLippi/WebBench.git>
[2]<http://www.ha97.com/code/webbench-1.5.tar.gz>

安装命令：
```bash
wget http://www.ha97.com/code/webbench-1.5.tar.gz
tar zxvf webbench-1.5.tar.gz
cd webbench-1.5
make
make install
```

### 使用方式

1.最常用命令：

> webbench -c 1000 -t 60 http:/127.0.0.1/phpinfo.php
> webbench -c 并发数 -t 运行测试时间 URL

2.其他命令：
可以根据`webbench -h`查看，
![webbench-h](https://res.cloudinary.com/flhonker/image/upload/v1526265119/githubio/go/goServer/webbench-h.png)

3.命令行选项：

| 短参           | 长参数         | 作用   |
| ------------- |:-------------:| -----:|
|-f     |--force                |不需要等待服务器响应               |
|-r     |--reload               |发送重新加载请求                   |
|-t     |--time <sec>           |运行多长时间，单位：秒"            |
|-p     |--proxy <server:port>  |使用代理服务器来发送请求	    |
|-c     |--clients <n>          |创建多少个客户端，默认1个"         |
|-9     |--http09               |使用 HTTP/0.9                      |
|-1     |--http10               |使用 HTTP/1.0 协议                 |
|-2     |--http11               |使用 HTTP/1.1 协议                 |
|       |--get                  |使用 GET请求方法                   |
|       |--head                 |使用 HEAD请求方法                    |
|       |--options              |使用 OPTIONS请求方法               |
|       |--trace                |使用 TRACE请求方法                 |
|-?/-h  |--help                 |打印帮助信息                       |
|-V     |--version              |显示版本号                         |

## 2. 使用webbench测试迷你Go服务器

我们使用Webbench对上一节100行代码写的迷你Go服务器上运行的"模拟购物网站"的首页index.html进行压力测试。goServer和webbench都是运行在以下环境中：
> CPU: Intel Core-i5 4x2.2GHz
> memory: 8GB
> OS: Ubuntu 18.04 LTS
> WLAN: 50M campus-wlan

(1) 把`goServer`程序文件放到web的根目录下，命令行中运行服务。

(2) 先开2000 clinets运行20s试探一下。

![2000clients](https://res.cloudinary.com/flhonker/image/upload/v1526264089/githubio/go/goServer/goSrv-webbench1.png)
可以看到：
每秒钟响应请求数：Speed=349806 pages/min，每秒钟传输数据量81409488 bytes/sec.
请求数Requests=116602 succeed,0 failed.   毫无压力。

(3)加到4000 clients,每秒钟响应数提升至359298 pages/min，但是每秒钟传输量下降至77539696，请求数Requests有所增加119766 succeed， 0failed。再大胆加到8000 clients，每秒钟响应数提升至361326 pages/min，每秒钟传输量下降至7700080，请求成功数增加至120442，仍未出现failed。

![4000clients](https://res.cloudinary.com/flhonker/image/upload/v1526264089/githubio/go/goServer/goSrv-webbench3.png)

(5) 那么，加到10000 clients呢？
每秒钟响应请求数：Speed=357678 pages/min，每秒钟传输数据量仍下降：74558376 bytes/sec.
请求数相比8000 clients下降但仍未出翔failed：Requests=119226 succeed,0 failed。此时，测试机器应该已经达到了并发访问瓶颈，因为Request有所减少，可能是fork()线程数有限，并且出现资源争夺。

![10000clients](https://res.cloudinary.com/flhonker/image/upload/v1526264088/githubio/go/goServer/goSrv-webbench5.png)

(6) 再大胆一点，加到12000 clients。
完了，`problem forking worker no. 10356`，测试机器已经撑不住了，无法获取到耕读资源用于访问测试。

![12000clients](https://res.cloudinary.com/flhonker/image/upload/v1526264083/githubio/go/goServer/goSrv-webbench6.png)

服务器端日志显示开始出现“Accept error”：

![server](https://res.cloudinary.com/flhonker/image/upload/v1526264084/githubio/go/goServer/goSrv-webbench7.png)

  然而，后面我再把clients数降到10001、10000，都是同样获取不到足够资源了，使用`ps aux |grep webbench`一查进程，全是后台的webbench进程!也许是僵尸进程，我也没看清楚，因为后面再也不敢开到12000 clients了，一开我的ubuntu就直接黑屏退出到注销后的登录界面，应该是本用户fork过多资源被清理了。好了，方式就到这里吧，我么主要是熟悉一下webebnch的使用方式和增量试探式的测试方法，另外顺便检验一下我们的迷你Go服务器。怎么样，还可以吧，没有自己写任何多线程的处理代码，内置高并发帮你轻松实现1w+的并发访问量。要知道我之前用的双核1GHz，1GB内存的阿里云CentOS7运行Tomcat8.0才达到1500-2000的并发量，逼着差远了。
--- 
