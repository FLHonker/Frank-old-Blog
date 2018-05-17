---
layout:     post
title:      为自己的操作系统写MBR
subtitle:   利用汇编写个MBR主引导，进入硬盘启动你的OS
date:       2018-05-17
author:     Frank Liu
header-img: img/post-bg-cpu.jpg
catalog: true
tags:
    - Kernel
    - OS
    - MBR
---

# 为自己的操作系统写MBR

接上一节，我们搭建起了bochs的模拟器环境，创建了硬盘，但是没有办法正常启动OS，就是因为缺少MBR主引导唤醒BIOS，进而进入硬盘OS。现在我们就开始了解计算机的启动过程和MBR，然后实现它。

## 计算机的启动过程

当我们按下计算机的power键后，首先运行的就是BIOS，全程为Basic Input/Output System。

BIOS用于电脑开机时运行系统各部分的的自我检测（Power On Self Test），并加载引导程序或存储在主存的操作系统。

由于BIOS是计算机上第一个软件，所以它的启动依靠硬件。

那么BIOS被启动以后，下一棒要交给谁呢？

BIOS的最后一项工作就是校验启动盘中位于0盘0道1扇区的内容。为什么是1扇区不是0扇区，这是因为CHS方法(Cylinder柱面-Header磁头-Sector扇区)中扇区的编号是从1开始编号的。如果检查到此扇区末尾的两个字节分别是`0x55`和`0xaa`，BIOS就认为此扇区中确实存在可执行程序(此程序便是我们这节讨论的MBR)，便加载到物理地址`0x7c00`，然后跳转到此地址执行。若检查的最后两个字节不是0x55和0xaa，那么就算里面有可执行代码也不能执行了。

当MBR接受了BIOS传来的接力棒，它又做了那些事情呢？

首先了解一下MBR：主引导记录（Master Boot Record，缩写：MBR），又叫做主引导扇区，是计算机开机后访问硬盘时所必须要读取的首个扇区。但是它只有512字节大小，没办法把内核加载到内存并运行，我们要另外实现一个程序来完成初始化和加载内核的任务，这个程序叫做`Loader`。

所以MBR的使命，就是从硬盘把Loader加载到内存，就可以把接力棒交给Loader了。Loader的实现我们先不讲。不过还得多说一句，现在我们还在实模式下晃悠。

## 实模式的内存布局

我们已经在前面提过了实模式，那么实模式到底是什么，和保护模式又有什么区别？
实模式指的是8086CPU的工作环境，工作方式，工作状态等等这一系列内容。
在最开始的模式里，程序用的地址都是**真实的物理地址**，`段基址：段内偏移地址`的策略在8086CPU上首次出现，CPU运行环境为16位。
缺点也显而易见，没有对系统级别程序做任何保护，用户程序可以自由访问所以内存；20根地址线，1MB的内存大小远远不够用。
直到32位CPU出现，打破了上述囧境。我们也等以后再具体讨论保护模式。

在实模式下，有20根地址线，因此可以访问1MB的内存空间。来看看实模式下1MB内存的布局：

![memory](https://res.cloudinary.com/flhonker/image/upload/v1526436961/githubio/linux-service/bochs/memory.jpg)
图中的内容我们现在只需要关注红色框出来的地方，可以看到BIOS的入口地址处只有16BYTE的空间，很显然，这一小块空间肯定存放的不是数据，只能是指令了，图中也写的很明显了:
> jmp f000:e05b

也就是跳转到了(f000 << 4) + e05b = fe05b处，这里的段基址左移四位的原因是，在实模式下段基址寄存器只有16位，想一下，16位的寄存器最多访问2^16=64KB的空间，我们想访问实模式下1MB的空间的话就需要将段基址左移4位，自然就可以访问到1MB的空间了，这么做的原因也是出于兼容性而采取的曲线救国方式，虽然我们现在的OS都已经到了64位，它也还得向下兼容不是吗?

当我们的电脑加电的一瞬间cs：ip就会被强制置位f000:e05b了，接下来就对内存，显卡等外设进行检查，做好它的初始化工作之后就完成它的任务了，在最后的时候，BIOS会通过绝对远跳:
> jmp 0:0x7c00

将接力棒交由MBR来加载我们的内核，我们初步的工作就是编写MBR。在进行内核加载之前，我们先通过MBR打印一些字符，来验证我们之前所说是否正确。

## 编写MBR，初见显存

BIOS要检测到MBR的最后两个字节为0x55和0xaa，然后才会开始执行MBR中的代码。

首先我们得知道MBR的具体地址，好，前面说过是`0x7c00`。

那么为什么是这个数字，网上有篇文章解释的很好：

[为什么主引导记录的内存地址是0x7C00？](https://link.jianshu.com/?t=http%3A%2F%2Fwww.ruanyifeng.com%2Fblog%2F2015%2F09%2F0x7c00.html)

作为一只初学的萌新，我们先不谈让MBR干什么大事，先测试一下能否从BIOS跳到MBR如何？我们的初版MBR的任务就是显示彩色的“Frank MBR”。一旦BIOS能跳转过来，就在屏幕上打印这个字符串。
这就牵扯到了另一个问题？如何在屏幕上显示东西。
我们将使用2种方法: **1是利用BIOS的中断调用服务，2是直接写入显存。**

我们都学过计算机组成原理，因此应该了解ASCII码，而显卡在任何时候都认为你发送的是ASCII码，如果你要发送数字5，应该发送数字5的ASCII码。

显卡的文本模式有多种，在此我使用默认的80*25。<u>每个字符在屏幕上都是用连续的2个字节来表示的，低字节是字符的ASCII码，高字节的低4位是字符前景色，高4位是字符背景色。</u>

![color-principle](https://res.cloudinary.com/flhonker/image/upload/v1526548029/githubio/linux-service/bochs/color-principle.png)

K位是闪烁位，0不闪烁，1闪烁。I是亮度位，0正常，1高亮。
RGB颜色对照表如下，你可以选择使用自己喜欢的配色：

![color-rgb](https://res.cloudinary.com/flhonker/image/upload/v1526548030/githubio/linux-service/bochs/color-rgb.png)

#### BIOS第10h号中断调用

看看Wikipedia的解释：

> `INT 10h` `INT 10H` 或者 `INT 16` 是BIOS中断调用的第10H功能的简写， 在基于x86的计算机系统中属于第17中断向量。BIOS通常在此创建了一个中断处理程序提供了实模式下的视频服务。此类服务包括设置显示模式，字符和字符串输出，和基本图形（在图形模式下的读取和写入像素）功能。要使用这个功能的调用，在寄存器AH赋予子功能号，其它的寄存器赋予其它所需的参数，并用指令INT 10H调用。INT 10H的执行速度是相当缓慢的，所以很多程序都绕过这个BIOS例程而直接访问显示硬件。设置显示模式并不经常使用，可以通过BIOS来实现，而一个游戏在屏幕上绘制图形，需要做得很快，所以直接访问显存比用BIOS调用每个像素更适合。

```asm
;主引导程序
;mbr.S 调用BIOS 10H号中断
;显示Frank MBR
;---------------------

;vstart作用是告诉编译器，把我的起始地址编为0x7c00
SECTION MBR vstart=0x7c00 ;程序开始的地址
    mov ax, cs            ;使用cs初始化其他的寄存器
    mov ds, ax            ;因为是通过jmp 0:0x7c00到的MBR开始地址
    mov es, ax            ;所以此时的cs为0,也就是用0初始化其他寄存器
    mov ss, ax            ;此类的寄存器不同通过立即数赋值，采用ax中转
    mov fs, ax
    mov sp, 0x7c00  ;初始化栈指针

;清屏利用0x10中断的0x6号功能
;清屏(向上滚动窗口)
;AH=06H,AL=上滚行数(0表示全部)
;BH=上卷行属性
;(CL,CH)=窗口左上角坐标，(DL,DH)=窗口右下角
;------------------------
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0			;左上角(0,0)
    mov dx, 0x184f		;右下角(79,24),
                     	;VGA文本模式中一行80个字符，共25行

    int 0x10

;获取光标位置
;---------------------
    mov ah, 3   ; 3号子功能获取光标位置
    mov bh, 1   ; bh寄存器存储带获取光标位置的页号,从0开始，此处填1可以看成将光标移动到最开始
    int 0x10

;打印字符串
;AH=13H 写字符串
;AL=写模式,BH=页码,BL=颜色,CX=字符串长度,DH=行,DL=列,ES:BP=字符串偏移量
;-------------------------------
    mov ax, message
    mov bp, ax

    mov cx, 10    		;字符串长度，不包括'\0'
    mov ax, 0x1301
    mov bx, 0x2			;前景色：绿，背景色：黑

    int 0x10

;------------------------------
    jmp $
    message db "Frank MBR."
    times 510-($-$$) db 0	;$表示当前指令的地址，$$表示程序的起始地址(也就是最开始的7c00)，
    ;所以$-$$就等于本条指令之前的所有字节数。
    ;510-($-$$)的效果就是，填充了这些0之后，从程序开始到最后一个0，一共是510个字节。
    db 0x55, 0xaa			;再加2个字节，刚好512B，占满一个扇区
```
这段代码通过0x10号中断直接操控显卡，达到打印字符串的目的。

程序开头出现了vstart这个词，我来解释一下vstart的意义。
vstart=xxxx的用处就是告诉编译器：你帮我把后面的数据的地址都从xxxx开始编吧。不然的话，编译器会把数据相对文件头的偏移量作为数据的地址，那么就全都是从0开始往后加。

在程序所在目录下执行以下代码，源码程序名为mbr.S：
> nasm -o mbr.bin mbr.S

这句话意思是把mbr.S汇编成纯二进制文件(默认格式)。如果要汇编成别的格式，可参考具体nasm中文手册。
然后执行(注意讲对应路径换成你自己计算机上的)：
>dd if=mbr.bin of=/home/frank/Developer/bochs-2.6.9/hd60M.img bs=512 count=1 conv=notrunc

dd是Linux下用于磁盘操作的命令，在Linux下man dd即可查看。
上面的命令是：读取mbr.bin，把数据输出到我们指定的硬盘hd.img中，块大小指定为512字节，只操作1块。

对我们的汇编代码进行编译并写入之前创建的磁盘中，接下来运行bochs，应该可以看到如下结果:

![bochs-start-ok](https://res.cloudinary.com/flhonker/image/upload/v1526490068/githubio/linux-service/bochs/bochs-start-ok.png)
默认[6]，开始模拟器,

![](https://res.cloudinary.com/flhonker/image/upload/v1526490068/githubio/linux-service/bochs/bochs-mbr.png)
输入c，执行下一步，就是加载MBR了，我们的MBR测试程序会在模拟中断上打印字符：

![frankmbr-ok](https://res.cloudinary.com/flhonker/image/upload/v1526490066/githubio/linux-service/bochs/FrankMBR.png)
看见了吧？黑底绿字。

## 直接写入显存

无论是哪种显示器，都是由显卡控制的。而无论哪种显卡，都提供了IO端口和显存。显存是位于显卡内部的一块内存。

要往显存里写东西，得先了解显存的布局。

![显存布局](https://res.cloudinary.com/flhonker/image/upload/v1526549465/githubio/linux-service/bochs/gpu-mm.png)
我们使用文本模式，就要从0xB8000开始写入。我们往这块内存里输入的字符会直接落入显存，也就可以显示在屏幕上面了。
