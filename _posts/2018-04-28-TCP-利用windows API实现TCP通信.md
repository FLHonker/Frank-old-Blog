---
layout:     post                    # 使用的布局（不需要改）
title:      C++的TCP通信（多线程）               # 标题
subtitle:   利用Windows API实现TCP/IP通信 # 副标题
date:       2018-04-28              # 时间
author:     Frank Liu               # 作者
header-img: img/post-bg-commu.jpeg    # 这篇文章标题背景图片
catalog: true                       # 是否归档
tags:                               # 标签
    - C++
    - TCP/IP
    - win API
    - socket
---

# C++的TCP通信（多线程）
> 简述：TCP通信服务端和客户端代码是不同的。首先，服务端有一个ServerSocket，初始化以后（包括设置IP和端口，绑定监听等过程），这些都设置好以后，就可以使用accept（）方法等待客户端连接了，这个方法是阻塞的。一旦连接成功，就会返回一个新的Socket，使用这个Socket就可以接收数据和发送数据了。客户端自始始终都只有一个Socket，这个Socket初始化以后，使用connect()方法和服务器进行连接，连接成功后，这个Socket就可以进行通信了。

**服务端tcp过程**
<div align=center>
![server](https://github.com/FLHonker/Cplus-engineer/blob/master/images/C-img/tcpserver.png?raw=true)
</div>
**客户端tcp过程**
<div align=center>
![client](https://github.com/FLHonker/Cplus-engineer/blob/master/images/C-img/tcpclient.png?raw=true)
</div>

### Windows下API简介
在windows下进行TCP通信，使用Ws2_32.dll动态链接库。

（1）WSAStartup函数：该函数用于初始化Ws2_32.dll动态链接库，在使用socket之前，一定要初始化该链接库。 
初始化：

WSADATA wsaData;
WSAStartup(MAKEWORD(2, 2), &wsaData)//第一个参数表示winsock的版本，本例使用的是winsock2.2版本。

（2）socket函数，创建一个socket

//af:一个地址家族，通常为AF_INET
//type:套接字类型，SOCK_STREAM表示创建面向流连接的套接字。为SOCK_DGRAM，表示创建面向无连接的数据包套接字。为SOCK_RAW，表示创建原始套接字
//protocol:套接字所用协议，不指定可以设置为0
//返回值就是一个socket
SOCKET socket(int af,int type,int protocol);

（3）bind函数：该函数用于将套接字绑定到指定的端口和地址。 
第一个参数为socket，第二个参数是一个结构指针，它包含了端口和IP地址信息，第三个参数表示缓冲区长度。需要说明的是，第二个参数在API中表示为：const struct sockaddr FAR*,这个语法结构我还没见过，网上说这是远指针，win16时期的产物，算是长见识了。
```
 SOCKADDR_IN addrSrv;
 addrSrv.sin_family = AF_INET;
 addrSrv.sin_port = htons(8888); //1024以上的端口号
 addrSrv.sin_addr.S_un.S_addr = htonl(INADDR_ANY);//IP地址
 bind(sockSrv, (LPSOCKADDR)&addrSrv, sizeof(SOCKADDR_IN));
```
(4) listen函数：将socket设置为监听模式，服务端的socket特有。必须将服务端的socket设置为监听模式才能和服务端简历连接。 
里面有两个参数，第一个参数为socket，第二个参数为等待连接最大队列的长度。
```
listen(sockSrv,10)
```
(5) accept函数：服务端socket接收客户端的连接请求，连接成功，则返回一个socket，该socket可以在服务端发送和接收数据。第一个参数为socket，第二个参数为包含客户端端口IP信息的sockaddr_in结构指针，第三个参数为接收参数addr的长度。
```
int len = sizeof(SOCKADDR);
accept(sockSrv, (SOCKADDR *) &addrClient, &len);
```
(6) closesocket函数：关闭socket，里面的唯一的一个参数就是要关闭的socket。 
(7) connect函数：客户端socket发送连接请求的函数，第一个参数是客户端的socket，第二个参数是一个结构体指针，里面包括连接主机的地址和ip，第三个参数为缓冲区的长度。
```
connect(sockClient, (struct  sockaddr*)&addrSrv, sizeof(addrSrv));
```
(8) htons函数：将一个16位无符号短整型数据由主机排列方式转化为网络排列方式，htonl函数的作用恰好相反。 
(9) recv函数：接收数据，第一个参数为socket，第二个参数为接收数据缓冲区，第三个参数为缓冲区的长度，第四个参数为函数的调用方式。
``````
char buff[1024];
recv(sockClient, buff, sizeof(buff), 0);
```
(10) send函数：发送数据，里面的参数基本和recv()一样。

[服务端代码cpp](https://github.com/FLHonker/Cplus-engineer/blob/master/C%2B%2B/tcp-com/tcp-communication-server.cpp)

[客户端代码cpp](https://github.com/FLHonker/Cplus-engineer/blob/master/C%2B%2B/tcp-com/tcp-communication-client.cpp)

[服务端的class实现](https://github.com/FLHonker/Cplus-engineer/blob/master/C%2B%2B/tcp-com/tcp-server-class.cpp)