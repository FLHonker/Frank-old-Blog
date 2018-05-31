---
layout:     post
title:      IPFS入门笔记
subtitle:   永久的、去中心化的、共享文件系统
date:       2018-05-31
author:     Frank Liu
header-img: img/post-bg-ipfs.jpg
catalog: true
tags:
    - IPFS
    - cloud
    - blockchain
---

# IPFS入门笔记

### 1. IPFS 是什么？

[IPFS（InterPlanetary File System，星际文件系统）](https://zh.wikipedia.org/wiki/%E6%98%9F%E9%99%85%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F)是永久的、去中心化保存和共享文件的方法，这是一种<u>内容可寻址、版本化、点对点(对等)超媒体</u>的分布式协议。

IPFS是一个对等的分布式文件系统，它尝试为所有计算设备连接同一个文件系统。在某些方面，IPFS类似于万维网，但它也可以被视作一个独立的BitTorrent群、在同一个Git仓库中交换对象。换种说法，IPFS提供了一个高吞吐量、按内容寻址的块存储模型，及与内容相关超链接。这形成了一个广义的Merkle有向无环图（DAG）。IPFS结合了分布式散列表、鼓励块交换和一个自我认证的名字空间。IPFS没有单点故障，并且节点不需要相互信任。分布式内容传递可以节约带宽，和防止HTTP方案可能遇到的DDoS攻击。

该文件系统可以通过多种方式访问，包括FUSE与HTTP。将本地文件添加到IPFS文件系统可使其面向全世界可用。文件表示基于其哈希，因此有利于缓存。文件的分发采用一个基于BitTorrent的协议。其他查看内容的用户也有助于将内容提供给网络上的其他人。IPFS有一个称为IPNS的名称服务，它是一个基于PKI的全局名字空间，用于构筑信任链，这与其他NS兼容，并可以映射DNS、.onion、.bit等到IPNS。

* 内容可寻址：通过文件内容生成唯一哈希值来标识文件，而不是通过文件保存位置来标识。相同内容的文件在系统中只会存在一份，节约存储空间。
* 版本化：可追溯文件修改历史。
* 点对点超媒体：P2P 保存各种各样类型的数据。

可以把 IPFS 想象成所有文件数据是在同一个 BitTorrent 群并且通过同一个 Git 仓库存取。

总之，它集一些成功系统（分布式哈希表、BitTorrent、Git、自认证文件系统）的优势于一身，是一套很厉害的文件存取系统。

### 2. 为什么有IPFS?

众所周知, 互联网是建立在HTTP协议上的. HTTP协议是个伟大的发明, 让我们的互联网得以快速发展.但是互联网发展到了今天HTTP逐渐出来了不足：
HTTP的中心化是低效的, 并且成本很高。

使用HTTP协议每次需要从中心化的服务器下载完整的文件(网页, 视频, 图片等), 速度慢, 效率低. 如果改用P2P的方式下载, 可以节省近60%的带宽. P2P将文件分割为小的块, 从多个服务器同时下载, 速度非常快。

**（1）Web文件经常被删除**

回想一下是不是经常你收藏的某个页面, 在使用的时候浏览器返回404(无法找到页面), http的页面平均生存周期大约只有100天. Web文件经常被删除(由于存储成本太高), 无法永久保存. IPFS提供了文件的历史版本回溯功能(就像git版本控制工具一样), 可以很容易的查看文件的历史版本, 数据可以得到永久保存

**（2）中心化限制了web的成长**

我们的现有互联网是一个高度中心化的网络. 互联网是人类的伟大发明, 也是科技创新的加速器. 各种管制将对这互联网的功能造成威胁, 例如: 互联网封锁, 管制, 监控等等. 这些都源于互联网的中心化.而分布式的IPFS可以克服这些web的缺点.

**（3）互联网应用高度依赖主干网**

主干网受制于诸多因素的影响, 战争, 自然灾害, 互联网管制, 中心化服务器宕机等等, 都可能是我们的互联网应用中断服务. IPFS可以是互联网应用极大的降低互联网应用对主干网的依赖.

【IPFS的目标】：IPFS不仅仅是为了加速web. 而是为了最终取代HTTP协议, 使互联网更加美好。

> **Merkle数据格式:**
每个Merkle都是一个有向无环图 ，因为每个节点都通过其名称访问。每个Merkle分支都是其本地内容的哈希，它们的子节点使用它们的哈希而非完整内容来命名。因此，在创建后将不能编辑节点。这可以防止循环（假设没有哈希碰撞），因为无法将第一个创建的节点链接到最后一个节点从而创建最后一个引用。

对任何Merkle来说，要创建一个新的分支或验证现有分支，通常需要在本地内容的某些组合体（例如列表的子哈希和其他字节）上使用一种哈希算法。IPFS中有多种散列算法可用。

### 3. IPFS包含哪些内容?

(1) IPFS是一个协议，类似http协议

* 定义了基于内容的寻址文件系统
* 内容分发
* 使用的技术分布式哈希、p2p传输、版本管理系统

(2) IPFS是一个文件系统

* 有文件夹和文件
* 可挂载文件系统

(3) IPFS是一个web协议

* 可以像http那样查看互联网页面
* 未来浏览器可以直接支持 ipfs:/ 或者 fs:/ 协议

(4) IPFS是模块化的协议

* 连接层：通过其他任何网络协议连接
* 路由层：寻找定位文件所在位置
* 数据块交换：采用BitTorrent技术

(5) IPFS是一个p2p系统

* 世界范围内的p2p文件传输网络
* 分布式网络结构
* 没有单点失效问题

(6) IPFS天生是一个CDN

* 文件添加到IPFS网络，将会在全世界进行CDN加速
* bittorrent的带宽管理

(7) IPFS拥有命名服务

* IPNS：基于SFS（自认证系统）命名体系
* 可以和现有域名系统绑定

### 6. IPFS工作原理

IPFS的的”宏伟”目标是取代HTTP, 那么先来看看IPFS是如何工作的?

IPFS为每一个文件分配一个独一无二的哈希值(文件指纹: 根据文件的内容进行创建), 即使是两个文件内容只有1个比特的不相同, 其哈希值也是不相同的.所以IPFS是基于文件内容进行寻址, 而不像传统的HTTP协议一样基于域名寻址。
IPFS在整个网络范围内去掉重复的文件, 并且为文件建立版本管理, 也就是说每一个文件的变更历史都将被记录(这一点类似版本控制工具git, svn等), 可以很容易个回到文件的历史版本查看数据.
当查询文件的时候, IPFS网络根据文件的哈希值(全网唯一)进行查找. 由于每个文件的哈希值全网唯一, 查询将很容易进行。
如果仅仅使用哈希值来区分文件的话, 会给传播造成困难, 因为哈希值不容易记忆, 就像ip地址一样不容易记忆, 于是人类发明的域名. IPFS利用IPNS将哈希值映射为容易记的名字
每个节点除了存储自己需要的数据, 还存储了一张哈希表, 用来记录文件存储所在的位置. 用来进行文件的查询下载。

那么问题来了, IPFS是如何来解决HTTP 及一些中心化服务器的这些缺点的?

(1) 下载速度快, 不再依赖主干网, 中心化服务器

整个IPFS系统是一个分布式的文件存储系统, 那么在下载相关数据的时候, 将从多个节点同时下载, 相比于HTTP从中心服务器的下载速度要快很多, 大家都用过P2P下载(比如: 迅雷, BitTorrent), IPFS下载过程跟这个类似.

(2) 存储空间变得非常便宜

由于IPFS使用的是区块链技术, 利用 Filecoin(为了的文章中会将如何获取filecoin, 也就是挖矿)来激励矿工分享自己的硬盘, 并且IFPS从全网去掉了冗余存储(从整个网络空间考虑, 这将大大节省网络存储空间), 将来的IPFS存储将会变得非常便宜(与我们现在的云盘, 各种中心化的CND相比较).

(3) 安全

中心化服务器目前很难抵挡DDoS攻击, 当大量的访问请求从四面八方涌来, 中心化的服务器几乎会在一瞬间瘫痪, 做过运维的同学应该深有感触, 比如每年双11, 不能睡觉的除了阿里, 腾讯的技术同学, 还有整个银行业的小朋友. 巨大的访问量随时可能造成服务器宕机. IPFS天生就拥有抵挡这种攻击的能力. 因为所有的访问将会被分散到不同的节点. 甚至攻击者自己也是节点之一. 某种程度上讲, IPFS甚至能抵挡量子计算的攻击.

(4) 开放

众所周知, 比特币是一种去中心化, 匿名的数据货币, 这些特性使得比特币无法被管制, 交易无法篡改. IPFS同样, 由于是建立在去中心化的分布式网络上的, 所以IFPS很难被中心化管理, 限制. 互联网将更加开放.

### 7. IPFS 使用场景

IPFS 的发明者 Juan Benet（juan@benet.ai）在 IPFS 技术白皮书中假设了一些使用场景：

* 在 /ipfs 和 /ipns 下挂载全球文件系统
* 挂载的个人同步文件夹，拥有版本功能
* 文件加密，数据共享系统
* 可用于所有软件的带版本的包管理器（已经实现了：<https://github.com/whyrusleeping/gx>）
* 可以作为虚机的根文件系统
* 可以作为数据库：应用可以直接操作 Merkle DAG，拥有 IPFS 提供的版本化、缓存以及分布式特性
* 可以做（加密）通讯平台
* 各种类型的 CDN
* 永久的 Web，不存在不能访问的链接

我觉得作为数据库这一点对应用开发者来说会很有用。

### 8. 安装与初始化

下载 [go-ipfs](https://dist.ipfs.io/#go-ipfs) 解压（下面的示例我是在Ubuntu 18.04LTS上做的，解压目录为 ~/Developer/go-ipfs-v0.4.15），然后到解压目录执行命令 ./ipfs init;或者运行:
> $ sudo ./install.sh

![ipfs-install](https://res.cloudinary.com/flhonker/image/upload/v1527777285/githubio/linux-service/ipfs/ipfs-install.png)

执行上述命令将自动把ipfs可执行文件移动到系统目录`/usr/local/bin`,直接在终端中执行:
> $ ipfs init

将在用户 home（~）下建立 .ipfs 目录存放数据，默认最大存储 10G。init 命令可以带参，比如修改最大存储、目录等，具体参考
> $ ipfs init help

![ipfs-init](https://res.cloudinary.com/flhonker/image/upload/v1527777285/githubio/linux-service/ipfs/ipfs-init.png)
继续执行命令启动节点服务器：
> $ ipfs daemon

![ipfs-daemon](https://res.cloudinary.com/flhonker/image/upload/v1527777285/githubio/linux-service/ipfs/ipfs-daemon.png)

* 加入 IPFS 网络
* 本地 HTTP 服务器，默认 8080 端口
* 处理后续 ipfs 的客户端命令

新开一个命令行，执行命令以查看当前节点标识:
> $ ipfs id

![ipfs-id](https://res.cloudinary.com/flhonker/image/upload/v1527777285/githubio/linux-service/ipfs/ipfs-id.png)

浏览器访问 http://localhost:5001/webui 进入管理界面，查看系统状态、管理文件以及配置系统。

![ipfsdashboard](https://res.cloudinary.com/flhonker/image/upload/v1527777706/githubio/linux-service/ipfs/ipfs-dashboard.png)

#### IPFS 配置

除了使用 Web 管理界面修改配置外，也可以直接用命令行先导出当前配置（JSON 格式，
> $ ipfs config show > ipfs.conf

配置项不多且含义明显），改完后使用以下命令更新配置，重启服务器就生效了。
> $ ipfs config replace ipfs.conf

当然，修改配置也可以直接用:
> $ ipfs config edit

服务器最终使用的配置文件保存在`~/.ipfs/config`中，对比刚刚导出的文件我们发现导出的文件只比这个 config 少了一项 Identity.PrivKey，即节点初始化时自动生成的 RSA 私钥。

#### 密钥对

节点初始化时会自动生成 RSA 密钥对，并且私钥没有设置密码。

公钥通过多重哈希得到节点 id（即上面的 QmZQqhrsJ41JFKpSAUNdpnGpyijazYrthWFdcMJcVu27K4），节点服务器启动后会和其他节点交互公钥，后续通讯时使用对方公钥加密数据，通过多重哈希对方公钥、对比对方节点 id 来确认是否正在和正确的节点交互。

私钥用来解密接收到的数据，也用于 ipns 来绑定文件名。整个过程没有引入证书，仅是使用了 PKI 机制。

总之，我觉得可以暂时不用关心密钥对，可能只有在一些使用场景下面才需要吧。

### 9. 添加文件

我的Template/文件夹下有一个网页的文件夹`wutim_2.2/`，我准备把他添加进ipfs，执行命令：

![ipfs-add](https://res.cloudinary.com/flhonker/image/upload/v1527780301/githubio/linux-service/ipfs/ipfs-add.png)
这样我们使用 ipfs cat ~/ipfs/QmWkkuaANJCXKu4nkVR1MUfzArK7eiscNrxQmUh6voUZSc 就可以查看 animate.css 了。在其他节点上也可以，只要记住这个文件的哈希值就行了。我们可以在自己的 HTTP 网关上试试（注意我的端口改成了 5002，你的默认应该是 8080）：

![ipfs-cat](https://res.cloudinary.com/flhonker/image/upload/v1527780567/githubio/linux-service/ipfs/ipfs-cat.png)

![ipfs-http-5002](https://res.cloudinary.com/flhonker/image/upload/v1527780709/githubio/linux-service/ipfs/ipfs-http-5002.png)

当然也可以用 ipfs 官方的 HTTP 网关：<https://ipfs.io/ipfs/QmWkkuaANJCXKu4nkVR1MUfzArK7eiscNrxQmUh6voUZSc>

### 10. 获取文件

> 注：wutim_2.2\的hash=“QmezBmf7Z24Ukz6Q6JfFbFMyw4evPU9XFPiwgjRQm7i9MS”

> $ ipfs get QmezBmf7Z24Ukz6Q6JfFbFMyw4evPU9XFPiwgjRQm7i9MS

将获取刚才我们发布的 wutim_2.2 目录。

![ipfs-get](https://res.cloudinary.com/flhonker/image/upload/v1527781218/githubio/linux-service/ipfs/ipfs-get.png)

#### Pin

IPFS 的本意是让用户觉得所有文件都是在本地的，没有“从远程服务器上下载文件”。Pin 是将文件长期保留在本地，不被垃圾回收。

执行`ipfs pin ls`可以查看哪些文件在本地是持久化的，通过 add 添加的文件默认就是 pin 过的。

#### 绑定节点名

每次修改文件后 add 都会返回不同的哈希，这对于网站来说就没法固定访问地址了，所以我们需要通过 ipns 来“绑定”节点名。

上面 wutim_2.2/ 目录的哈希值是 QmezBmf7Z24Ukz6Q6JfFbFMyw4evPU9XFPiwgjRQm7i9MS，我们将整个目录作为节点根目录发布：
> $ ipfs name publish QmezBmf7Z24Ukz6Q6JfFbFMyw4evPU9XFPiwgjRQm7i9MS

![ipfs-publish](https://res.cloudinary.com/flhonker/image/upload/v1527781639/githubio/linux-service/ipfs/ipfs-publish.png)

然后我们就可以通过 ipns 访问了，注意是 ipns：
> $ ipfs cat /ipns/QmezBmf7Z24Ukz6Q6JfFbFMyw4evPU9XFPiwgjRQm7i9MS/index.html

以后每次更新文件都再 publish 一下就行了。

#### DNS 解析

IPFS 允许用户使用现有的域名系统，这样就能用一个好记的地址来访问文件了，比如：
> $ ipfs cat /ipns/www.wutim.com/index.html

只需要在 DNS 解析加入一条 TXT 记录：

| 记录类型 |  主机记录 |	记录值  |
|:-------:|:---------:|:--------|
|  TXT	| www.wutim.com	  |dnslink=/ipns/QmezBmf7Z24Ukz6Q6JfFbFMyw4evPU9XFPiwgjRQm7i9MS/index.tml|
