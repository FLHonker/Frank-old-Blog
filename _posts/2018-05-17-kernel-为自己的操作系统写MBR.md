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

---
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

---
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

---
## 直接写入显存

无论是哪种显示器，都是由显卡控制的。而无论哪种显卡，都提供了IO端口和显存。显存是位于显卡内部的一块内存。

要往显存里写东西，得先了解显存的布局。

![显存布局](https://res.cloudinary.com/flhonker/image/upload/v1526549465/githubio/linux-service/bochs/gpu-mm.png)
我们使用文本模式，就要从0xB8000开始写入。我们往这块内存里输入的字符会直接落入显存，也就可以显示在屏幕上面了。
```asm
;主引导程序---直接操作显存显示“Hello MBR”
;mbr.S 调用BIOS 10H号中断
;显示Frank MBR
;---------------------

;vstart作用是告诉编译器，把我的起始地址编为0x7c00
SECTION MBR vstart=0x7c00 ;程序开始的地址
    mov ax, cs            ;使用cs初始化其他的寄存器
    mov ds, ax            ;因为是通过jmp 0:0x7c00到的MBR开始地址
    mov ss, ax            ;所以此时的cs为0,也就是用0初始化其他寄存器
    mov fs, ax			  ;此类的寄存器不同通过立即数赋值，采用ax中转
    mov sp, 0x7c00  	  ;初始化栈指针
    mov ax, 0xb800			;显存地址，中转入ax
    mov es, ax				;显存地址存入附加堆栈段es

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

;直接从(0,0)写入每个字符和对应色彩
;写入显存
;------------------------------
	mov byte[es: 0x00], 'H'
	mov byte[es: 0x01], 0xEE   ;黄色前景棕色背景+闪烁

	mov byte[es: 0x02], 'e'
	mov byte[es: 0x03], 0x33

	mov byte[es: 0x04], 'l'
	mov byte[es: 0x05], 0xDD

	mov byte[es: 0x06], 'l'
	mov byte[es: 0x07], 0x02

	mov byte[es: 0x08], 'o'
	mov byte[es: 0x09], 0xA2

	mov byte[es: 0x0A], ' '
	mov byte[es: 0x0B], 0x39

	mov byte[es: 0x0C], 'M'
	mov byte[es: 0x0D], 0x88

	mov byte[es: 0x0E], 'B'
	mov byte[es: 0x0F], 0x0C

	mov byte[es: 0x10], 'R'
	mov byte[es: 0x11], 0x1F

;------------------------------
    jmp $
    times 510-($-$$) db 0	;$表示当前指令的地址，$$表示程序的起始地址(也就是最开始的7c00)，
    ;所以$-$$就等于本条指令之前的所有字节数。
    ;510-($-$$)的效果就是，填充了这些0之后，从程序开始到最后一个0，一共是510个字节。
    db 0x55, 0xaa			;再加2个字节，刚好512B，占满一个扇区
```
将以上MBR的汇编代码汇编生成二进制文件，写入硬盘文件。注意，你可以直接在原硬盘文件`hd60M.img`上进行操作而无需进行任何重置工作或重新创建一个硬盘，因为我们使用的`dd`命令操作是可以直接覆盖写入硬盘开始的第一个512B的扇区，将原来的MBR覆盖。即之前刷入的MBR不会影响本次操作。
运行bochs，可以看见一下效果：

![HelloMBR](https://res.cloudinary.com/flhonker/image/upload/v1526566642/githubio/linux-service/bochs/helloMBR.gif)

---
## MBR进阶，使用硬盘

我们的MBR当然不止是在屏幕上显示“Hello MBR”就完事了，前面提到过MBR要从硬盘上把Loader加载到内存并且运行，并把接力棒交给它。

也许你会有如下疑问：

为什么要把loader加载入内存？

首先我们要知道MBR和操作系统都是位于硬盘上的。CPU的硬件电路被设计为只能运行处于内存中的程序，因为CPU运行内存中程序更快。所以CPU要从硬盘读取数据，决定把它加载到内存的什么位置。

### 怎样控制硬盘

CPU只能同IO接口进行交流，那么CPU要和硬盘交流的话，也一定要通过IO接口，硬盘的IO接口就是硬盘控制器。再具体一点，就是硬盘控制器与CPU之间通信是通过端口。所谓端口，其实就是一些位于IO接口中的寄存器。不同的端口有着不同的作用。

![硬盘控制器主要端口寄存器](https://res.cloudinary.com/flhonker/image/upload/v1526567481/githubio/linux-service/bochs/harddisk-register.png)
可以看到，端口分成了两组，我们重点看Command Block registers。

data寄存器的作用是读取或写入数据，16位(其他寄存器都是8位)。在读硬盘时，硬盘准备好数据后，硬盘控制器将其放在内部的缓冲区中，不断读此寄存器就是在读出缓冲区中的数据。写硬盘时，我们把数据送到此端口，数据就被存入缓冲区，硬盘控制器发现这个缓冲区中有数据了，就把这些数据写入相应扇区。

读硬盘时，端口0x171或0x1F1寄存器叫Error寄存器。只有在读取失败时有用，里面会记录失败信息，尚未读取的硬盘数在Sector count寄存器中。写硬盘时，这个寄存器叫Feature寄存器。用来记录一些参数。

Sector count寄存器用来指定待读取或待写入的扇区数。硬盘每完成一个扇区，就会把此寄存器值减1，如果中间失败了，那这个寄存器的值就是未完成的扇区数。如果它被指定为0，表示要操作256个扇区。

LBA寄存器涉及到`LBA方法`。

从硬盘读写数据，最经典的就是像硬盘控制器分别发送柱面号，磁头号，扇区号，就是我们前面说过的`CHS模式`。但是如果把<u>扇区统一编址</u>，把他们看做逻辑扇区，全都是从0开始编号，这样就能节省很多麻烦，这就是LBA方法。

最早的逻辑扇区编址方法是`LBA28`，用28个比特表示逻辑扇区号。则LBA28可以管理128GB的硬盘。随着硬盘技术的发展，`LBA48`已经出现，可管理容量达到131072TB。

但是我们为了方便，在这里使用LBA28模式。

LBA寄存器有low、mid、high 三个，都是8位。但是这三个也只能表示24位，剩下4位被放在device寄存器的低4位。

所以我们可以看出device寄存器是个“杂项寄存器”。它的第4位用来指定通道上的主盘(o)或从盘(1)，第6位用来设置是LBA(1)方式还是CHS(0)方式，第5和7位固定为1。

读硬盘时，端口号为0x1F7或0x177的寄存器是Status，用来给出硬盘状态信息。第0位是ERR位，若此位为1，表示命令出错。第3位是data request位，若为1，表示硬盘已经准备好数据，主机可以把数据读出来了，第7位是BSY位，为1表示硬盘正在忙着，此寄存器中其他位都无效。写硬盘时，它是Command寄存器，把命令写进此寄存器，硬盘就可以开始工作了。
* 读扇区：0x20
* 写扇区：0x30

**操作步骤如下：**

1. 先选择通道，往该通道的sector count寄存器写入待操作的扇区数；
2. 往该通道上的三个LBA寄存器写入扇区起始地址的低24位；
3. 往device寄存器中写入LBA地址的24~27位，并置第6位为1，使其为LBA模式，设置第4位，选择操作的硬盘(master硬盘或slave硬盘)；
4. 往该通道上的command寄存器写入操作命令；
5. 读取该通道上的status寄存器，判断硬盘工作是否完成；
6. 如果以上步骤是读硬盘，则进入下一个步骤，否则，结束；
7. 将硬盘数据读出。

---
## 改造MBR，操作硬盘

我们的MBR现在在第0扇区(LBA方式)，那么不如将Loader放在第2扇区，中隔一个扇区安全一些。MBR把loader读出来后，可以选择实模式下1MB的空闲内存存放。回顾实模式内存布局图，看到0x500-0x7BFF可用，0x7E00-0x9FBFF可用。因为内核地址增长是从低到高的，所以我们尽量选低地址加载Loader，因此选择0x900。
```asm
;主引导程序 --- 改造MBR，引导读取硬盘
;mbr3_Loader.S

;---------------------
LOADER_BASE_ADDR	 equ 0x900
LOADER_START_SECTION equ 0x2

;vstart作用是告诉编译器，把我的起始地址编为0x7c00
SECTION MBR vstart=0x7c00 ;程序开始的地址
    mov ax, cs            ;使用cs初始化其他的寄存器
    mov ds, ax            ;因为是通过jmp 0:0x7c00到的MBR开始地址
    mov ss, ax            ;所以此时的cs为0,也就是用0初始化其他寄存器
    mov fs, ax			  ;此类的寄存器不同通过立即数赋值，采用ax中转
    mov sp, 0x7c00  	  ;初始化栈指针
    mov ax, 0xb800			;显存地址，中转入ax
    mov es, ax				;显存地址存入附加堆栈段es

;---------------------------
; 显示“Frank MBR”
;清屏利用0x10中断的0x6号功能
;清屏(向上滚动窗口)
;AH=06H,AL=上滚行数(0表示全部)
;BH=上卷行属性
;(CL,CH)=窗口左上角坐标，(DL,DH)=窗口右下角
;---------------------------
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0			;左上角(0,0)
    mov dx, 0x184f		;右下角(79,24),
                     	;VGA文本模式中一行80个字符，共25行

    int 0x10

;直接从(0,0)写入每个字符和对应色彩
;------------------------------
	mov byte[es: 0x00], 'F'
	mov byte[es: 0x01], 0xEE   ;黄色前景棕色背景+闪烁

	mov byte[es: 0x02], 'r'
	mov byte[es: 0x03], 0xEE

	mov byte[es: 0x04], 'a'
	mov byte[es: 0x05], 0xEE

	mov byte[es: 0x06], 'n'
	mov byte[es: 0x07], 0xEE

	mov byte[es: 0x08], 'k'
	mov byte[es: 0x09], 0xEE

	mov byte[es: 0x0A], '-'
	mov byte[es: 0x0B], 0xEE

	mov byte[es: 0x0C], 'M'
	mov byte[es: 0x0D], 0xEE

	mov byte[es: 0x0E], 'B'
	mov byte[es: 0x0F], 0xEE

	mov byte[es: 0x10], 'R'
	mov byte[es: 0x11], 0xEE

;设置参数，调用函数读取硬盘
;------------------------------
	mov eax, LOADER_START_SECTION	;起始扇区LBA地址
	mov bx, LOADER_BASE_ADDR		;写入的地址
	mov cx, 1						;待读入的扇区数
	call rd_disk_m_16				;调用读取硬盘

	jmp LOADER_BASE_ADDR			;跳转到Loader区

;------------------------
;读取硬盘n个扇区
;------------------------
rd_disk_m_16:
;step1:设置读取扇区数
	mov esi, eax					;eax=LBA起始扇区号,备份eax
									;bx=数据写入的内存地址
	mov di, cx						;cx=读入的扇区数,1；备份cx
	mov dx, 0x1F2					;使用0x1F2端口,Sector count
	mov al, cl						;访问8位端口时使用寄存器AL
	out dx, al						;将AL中的数据写入端口号为0x1F2的寄存器中
									;out的操作数可以位8位立即数或寄存器DX，源操作数必须为AL或AX
	mov eax, esi

;step2:将LBA地址写入0x1F3-0x1F6(在这里我们地址为2)
	;0x1F3放0-7位
	mov dx, 0x1F3
	out dx, al

	;0xF4放8-15位
	mov cl, 8
	shr eax, cl			;右移8位,AL置0
	mov dx, 0x1F4
	out dx, al

	;0xF5放16-23位
	shr eax, cl
	mov dx, 0x1F5
	out dx, al

	shr eax, cl
	and al, 0x0F
	or	al, 0xE0		;设置7-4位为1110,LBA模式,主盘
	mov dx, 0x1F6
	out dx, al

;step3:往Command寄存器写入读命令
	mov dx, 0x1F7
	mov al, 0x20
	out dx, al

;step4:检查硬盘状态
  .not_ready:
	nop
	in  al, dx
	and al, 0x88
	cmp al, 0x08
	jnz .not_ready

;step5:从0xF0端口读出数据
	mov ax, di			;DI为要读取的扇区数,data寄存器为16位,即每次读取2个字节,要读(DI*512/2)次
	mov dx, 256
	mul dx				;MUL指令的被乘数隐含在AX中,乘积的低16位在AX中,高16位在DX中
	mov cx, ax			;把AX的的值赋给CX,用作计数器

	mov dx, 0x1F0
  .go_on_read:
	in  ax, dx			;把0x1F0端口读出的数据放在AX寄存器中
	mov [bx], ax		;再把AX寄存器中的数据放在偏移地址为BX指向的内存空间
	add bx, 2			;一次读2个字节
	loop .go_on_read
	ret					;记得调用函数后要返回

;------------------------------
    times 510-($-$$) db 0
    db 0x55, 0xaa
```
然后在你自己的文件目录下依次执行：
> nasm -o mbr_disk.bin mbr_disk.S
> dd if=mbr3_Loader.bin of=/home/frank/Developer/bochs-2.6.9/bin/hd60M.img bs=512 count=1 conv=notrunc

我们现在的loader还什么都没干了，那干脆就让它显示“Loader...”好了。
```asm
;Loader_!.S, 暂时什么有用工作也不做，只显示“Loader...”
;-----------------------------------
LOADER_BASE_ADDR 	equ 0x900
LOADER_START_SECTOR equ 0x2

SECTION LOADER vstart=LOADER_BASE_ADDR
	mov byte[es: 0x00], 'L'
	mov byte[es: 0x01], 0xEE   ;黄色前景棕色背景+闪烁

	mov byte[es: 0x02], 'o'
	mov byte[es: 0x03], 0xEE

	mov byte[es: 0x04], 'a'
	mov byte[es: 0x05], 0xEE

	mov byte[es: 0x06], 'd'
	mov byte[es: 0x07], 0xEE

	mov byte[es: 0x08], 'e'
	mov byte[es: 0x09], 0xEE

	mov byte[es: 0x0A], 'r'
	mov byte[es: 0x0B], 0xEE

	mov byte[es: 0x0C], '.'
	mov byte[es: 0x0D], 0xEE

	mov byte[es: 0x0E], '.'
	mov byte[es: 0x0F], 0xEE

	mov byte[es: 0x10], '.'
	mov byte[es: 0x11], 0xEE

	jmp $
```
依次执行：

> nasm -o loader.bin loader.S
> dd if=Loader_1.bin of=/home/frank/Developer/bochs-2.6.9/bin/hd60M.img bs=512 count=1 seek=2 conv=notrunc

<i>一定要注意这里**seek=2**，意思是跳过2块，因为我们的Loader在2号扇区。缺少seek的话会出错。</i>实验中这一步嫌麻饭的话可以自己写成脚本哈～

最后在bochs目录下执行：
> ./bochs -f bochsrc.disk

效果如下：

[gif]：

![Loader...](https://res.cloudinary.com/flhonker/image/upload/v1526700197/githubio/linux-service/bochs/Loader.gif)

[vedio]：

<iframe width="560" height="315" src="https://res.cloudinary.com/flhonker/video/upload/v1526699718/githubio/linux-service/bochs/Loader.mp4" frameborder="0" allowfullscreen></iframe>
