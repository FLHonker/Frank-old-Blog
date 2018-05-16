---
layout:     post
title:      bochs环境搭建
subtitle:   学习Linux内核？先搭建一个bochs简易环境
date:       2018-05-16
author:     Frank Liu
header-img: img/post-bg-linux (2).jpg
catalog: true
tags:
    - Linux
    - kernel
    - bochs
---

# bochs环境搭建

> Linux kernel学习专栏——1

最近Frank又想着手研究放下好久的Linux内核，发现一个好的学习工具——bochs。利用它来一步步搭建自己的OS，理解操作系统内核原理最好不过过了。
> Bochs是一个x86硬件平台的开源模拟器。它可以模拟各种硬件的配置。Bochs模拟的是整个PC平台，包括I/O设备、内存和BIOS。更为有趣的是，甚至可以不使用PC硬件来运行Bochs。事实上，它可以在任何编译运行Bochs的平台上模拟x86硬件。通过改变配置，可以指定使用的CPU(386、486或者586)，以及内存大小等。一句话，Bochs是电脑里的“PC”。根据需要，Bochs还可以模拟多台PC，此外，它甚至还有自己的电源按钮。

## 配置要求

一台Linux/Windows操作系统的机器即可，最好是32位/64位皆可，反正是我们自行编译C\++源码，平台无关哈哈，Frank最喜欢了。Frank用的最新的Ubuntu18.04LTS，最新的gcc 7.3.0，都一切正常，接下来一切以Ubuntu为例。

## 安装bochs

[bochs下载地址](https://link.zhihu.com/?target=https%3A//sourceforge.net/projects/bochs/files/bochs/)

![bochs-download1](https://res.cloudinary.com/flhonker/image/upload/v1526438137/githubio/linux-service/bochs/bochs-download1.png)
进入下载地址会发现有很多个版本，这里最新的为`2.6.9`，其实bochs官网上目前最新的是bochs-20180511，不过Frank亲身尝试发现make编译的时候有个源码错误，采用2.6.9版本没有问题，那我们就用2.6.9版本。如果你是Windows或者rpm系列Linux（如CentOS、redhat），也可以直接下载相应的版本安装包。这里我们直接下载源码`bochs-2.6.9.tar.gz`自行编译安装。
![bochs-download2](https://res.cloudinary.com/flhonker/image/upload/v1526438137/githubio/linux-service/bochs/bochs-download2.png)

其实我们也可以通过
> sudo apt install bochs

这个命令进行安装，我不用这个方法安装的原因是安装之后的bochs文件比较分散，造成配置时比较麻烦，自己下载的文件进行安装时配置文件都在一起，管理起来方便。

好了，文件下载好了之后解压：
> tar -zxvf bochs-2.6.9.tar.gz

解压之后的文件有：
![](https://res.cloudinary.com/flhonker/image/upload/v1526438545/githubio/linux-service/bochs/bochs-source.png)

配置前先安装依赖库：
> sudo apt install libx11-dev libxrandr-dev

进入到bochs-2.6.9的目录中，输入:
```bash
./configure --prefix=/home/frank/Developer/bochs-2.6.9 --enable-debugger --enable-disasm --enable-iodebug --enable-iodebug --enable-x86-debugger --with-x --with-x11 libs='-lx11'
```
一定要将“--perfix”后面的`/home/frank/Developer/bochs-2.6.9`换成你自己的安装目录。

![configure](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/configure-bochs.png)

### 编译

编译很简单，但是比较揪心，说必定就报什么错误和warning，幸好，Frank已经帮大家探好了路。
进入解压后的bochs-2.6.9目录，执行make：
> make

![make](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/make-bochs.png)
首次make过程比较长，会有部分warning，不必理会，像这样的：
![make-warning](https://res.cloudinary.com/flhonker/image/upload/v1526436937/githubio/linux-service/bochs/make-warning.png)

下一步，
> make install

![make-install](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/make-install-bochs.png)

安装完成，大家可以看看自己的安装目录下是否出现这个bochs-2.6.9，里面有两个文件夹（bin和share），安装目录参考自己配置文件中填写的路径。

## 配置

安装好了bochs之后我们要对它进行配置，这个配置大家可以参考安装目录下的bochsrc-sample.txt，该文件的路径在bochs目录下的
> share/doc/bochs/bochsrc-sample.txt

因为bochs在运行的时候要加载我们的配置文件，这个配置文件需要我们自己指定，所以我把配置文件放在了bochs目录下的my_conf文件夹中。

```bash
$ cd bochs-2.6.9/my_conf
$ vim bochsrc.disk

// 配置如下
＃首先设置 Bochs 在运行过程中能够使用的内存，本例为 32MB。
＃关键字为 megs
megs 32

＃设置对应真实机器的 BIOS 和 VGA BIOS 。
＃对应两个关键字为 ： romimage 和 vgaromimage
romimage: file＝/home/frank/Developer/bochs-2.6.9/share/bochs/BIOS-bochs-latest
vgaromimage: file＝/home/frank/Developer/bochs-2.6.9/share/bochs/VGABIOS-lgpl-latest

#选择启动盘符
boot: disk  #从硬盘启动

# 设置日志文件的输入位置
log: bochs.out

# 关闭鼠标，打开键盘
mouse: enabled=0
keyboard: keymap=/home/frank/Developer/bochs-2.6.9/share/bochs/keymaps/x11-pc-us.map

# 设置硬盘
ata0: enabled=1,ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14
```
大家在写配置文件的时候一定要把这些路径写成绝对路径，不要使用相对路径，因为bochs不认相对路径。
配置文件写完了，那我们运行一下bochs试试， 看看是什么样子。

在bochs的bin目录下输入
> ./bochs

接下来就会看到如下界面：

![run-bochs](https://res.cloudinary.com/flhonker/image/upload/v1526436937/githubio/linux-service/bochs/run-bochs1.png)

可以看到默认的选项是2，要求我们输入配置文件的名称，此时输入myconf/bochsrc.disk即可，也就是以前我们写的配置文件的名称。

![](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/panic-error.png)

在我们输入配置文件按下回车之后可以看到，报了一个PANIC级别的错误，意思是我们没有启动盘，因为bochs是模拟的操作系统进行运行，此时我们还没有启动盘，所以它不知道从哪里开始运行，接下来我们就开始创建启动盘。

退出后运行：
> ./bximage

![bximage](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/new-bximage.png)
![hd60M-img](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/hd60M-img.png)
60代表该硬盘的大小为60M，hd60M.img是我给改硬盘取得名字，最后我们需要加入到配置文件中的，这是我们硬盘配置好之后，bochs给我们自动生成的硬盘信息，接下来在配置文件的最后一行加上该硬盘的信息。

完整的配置如下:
```bash
＃首先设置 Bochs 在运行过程中能够使用的内存，本例为 32MB。
＃关键字为 megs
megs 32

＃设置对应真实机器的 BIOS 和 VGA BIOS 。
＃对应两个关键字为 ： romimage 和 vgaromimage
romimage: file＝/home/frank/Developer/bochs-2.6.9/share/bochs/BIOS-bochs-latest
vgaromimage: file＝/home/frank/Developer/bochs-2.6.9/share/bochs/VGABIOS-lgpl-latest

#选择启动盘符
boot: disk  #从硬盘启动

# 设置日志文件的输入位置
log: bochs.out

# 关闭鼠标，打开键盘
mouse: enabled=0
keyboard: keymap=/home/frank/Developer/bochs-2.6.9/share/bochs/keymaps/x11-pc-us.map

# 设置硬盘
ata0: enabled=1,ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14

# 启动盘信息
ata0-master: type=disk, path="my_conf/hd60M.img", mode=flat
```
硬盘信息配置好了之后我们初步的配置就已经搞定了，接下来我们在此启动一下试试

> ./bochs -f my_conf/bochsrc.disk

通过-f 可以直接指定我们的配置文件的名称，如果嫌麻烦，每次必须进入bochs文件下，都要输入这么多字的话，可以直接用别名来代替
```bash
$ cd ~
$ vim .bashrc

alias bochs='/home/frank/Developer/bochs-2.6.9/bin/bochs -f /home/frank/Developer/bochs-2.6.9/bin/my_conf/bochsrc.disk'

$ source .bashrc
```
![](https://res.cloudinary.com/flhonker/image/upload/v1526436935/githubio/linux-service/bochs/bochs-key.png)
当然，路径得改成你们自己的。接下来我们就可以在任意路径下输入bochs运行我们的虚拟机啦，此时如果你想运行看看结果的话，大概就是这样吧:

![](https://res.cloudinary.com/flhonker/image/upload/v1526436936/githubio/linux-service/bochs/parameter-exit.png)

这样其实说明一切都准备好了，属于正常现象，如果不是这样，可能您需要回头再看看自己是不是哪里配置出现了问题。

出现这用错误的原因是因为我们现在的硬盘还只是一个空的硬盘，没有任何数据，又如何能够运行呢，从图上可以看到，CPU一下就跑没影了。在我们平时开机的时候，是不是都要通过BIOS引导，进行硬件，内存的各项检测之后，再将我们的操作系统从硬盘上唤醒。此时操作系统才接管了我们的电脑。我们的配置讲完了，关于主引导的编写可能要等我研究透了之后再和大家分享啦。