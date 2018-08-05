---
layout:     post
title:      E2E软件自动化测试中的OCR功能
subtitle:   基于sikuli进行二次开发自动化的测试工具，使用tesseract-OCR进行文本识别与定位。
date:       2018-07-27
author:     Frank Liu
header-img: img/post-bg-coffee.jpg
catalog: true
tags:
    - Algorithm
    - sikuli
    - tessercact
---

# E2E软件自动化测试中的OCR功能

## Sikuli

MIT的研究人员设计了一种新颖的图形脚本语言[Sikuli][1]，计算机用户只须有最基本的编程技能（比如会写print"hello world"），他不需要去写出一行行代码，而是用屏幕截图的方式，用截出来的图形元素组合出神奇的程序。Sikuli脚本自动化，你在屏幕上看到的任何东西。它使用图像识别，识别和控制GUI组件。这是有用的，当有一个GUI的内部或源代码的访问是不容易的。

[Sikuli][1]（在墨西哥维乔印第安人的语言里是”上帝之眼”的意思）是由美国麻省理工学院开发的一种最新编程技术，使得编程人员可以使用截图替代代码，从而简化代码的编写流程。从它研究方向上看，是一种编程技术，但是该技术还可以用于进行大规模的程序测试，脚本程序编写使用的是python语言。

![Sikuli][2]

当你看到上图sikuli的脚本时，一定会惊呼，这样都可以~！脚本加截图~~~

更多关于Sikuli的使用可以查看[官方文档][3]

在我们自主开发的E2E自动化测试工具中，使用Sikuli做二次开发，使用tesseract-OCR完成文本识别和定位功能，对软件GUI中大量的文本框、按钮等控件，在测试中无需反复的人工输入和点击，只需截图识别后生成自动化测试脚本。对于输入的一些非常长的账号、数字等，无需人工比对结果，也是通过截图识别判断测试结果。关于文本定位功能，就是在一张GUI截图中，搜索指定的文本并获得它的坐标位置。

## tesseract-OCR

光学字符识别(OCR,Optical Character Recognition)是指对文本资料进行扫描，然后对图像文件进行分析处理，获取文字及版面信息的过程。OCR技术非常专业，一般多是印刷、打印行业的从业人员使用，可以快速的将纸质资料转换为电子资料。关于中文OCR，目前国内水平较高的有清华文通、汉王、尚书，其产品各有千秋，价格不菲。国外OCR发展较早，像一些大公司，如IBM、微软、HP等，即使没有推出单独的OCR产品，但是他们的研发团队早已掌握核心技术，将OCR功能植入了自身的软件系统。对于我们程序员来说，一般用不到那么高级的，主要在开发中能够集成基本的OCR功能就可以了。

Tesseract的OCR引擎最先由HP实验室于1985年开始研发，至1995年时已经成为OCR业内最准确的三款识别引擎之一。然而，HP不久便决定放弃OCR业务，Tesseract也从此尘封。
数年以后，HP意识到，与其将Tesseract束之高阁，不如贡献给开源软件业，让其重焕新生——2005年，Tesseract由美国内华达州信息技术研究所获得，并求诸于Google对Tesseract进行改进、消除Bug、优化工作。
Tesseract目前已作为开源项目发布在Google Project，其项目主页在[这里][4]查看，其最新版本3.0已经支持中文OCR，并提供了一个命令行工具。

简单来讲，tesseract-ocr已经帮我们封装好了文本识别算法，我们只需输入一张图片，就可以返回识别结果。以Linux为例，命令行下使用tesseract-ocr也非常简单：
```bash
Usage:
  tesseract --help | --help-extra | --version
  tesseract --list-langs
  tesseract imagename outputbase [options...] [configfile...]

OCR options:
  -l LANG[+LANG]        Specify language(s) used for OCR.
NOTE: These options must occur before any configfile.

Single options:
  --help                Show this help message.
  --help-extra          Show extra help for advanced users.
  --version             Show version information.
  --list-langs          List available languages for tesseract engine.
```
最常用的就是：

> tesseract imagename outputbase -l eng

一般来讲，为了提高识别准确率，我们都要下载训练好的语言包，手动制定识别文本的语言。关于怎么训练自己的语言库，可以查看[CSDN-Tesseract-OCR 3.0.1训练自己的语言库之图像文字识别][5]。

作为Developer，我们肯定不会直接使用现成的命令输入输出，我们要使用tesseract-dev API，来调用tesseract实现文本识别。tesseract提供了C++、Ruby和Python的API，但是我们这里要使用java开发，也有一个jar的库：[Tess4J][6]，在Java项目中引入即可，并且可以使用自己训练的字库进行识别。

## OpenCV

这个我就不多介绍了吧，我们的老朋友了。Frank目前就是专门研究opencv的，最近推出的很多都是opencv的文章。在本项目中，opencv可是作为特邀嘉宾，负责所有的图像处理。相对于其他图像处理库或者使用Java内置类库自己写的图像处理模块，opencv兼具高性能与简洁的特性。为此，opencv是我强烈推荐使用的，也是由我引入本项目中的，在后面的算法介绍中opencv将闪亮登场并贯穿始终。新来的朋友，可以去[opencv官网][7]或者[github][8]了解一下opencv。

## 该项目中的几项关键技术

关于如何使用Sikuli二次开发并不在我们小组负责的范围内，只是了解了它在我们整个项目中的作用；我们4人的团队只负责基于tesseract开发OCR功能和文本搜索定位。关于Tess4J在InteliJ IDEA、Eclipse中的配置和使用这里也不做过多介绍，大家可以去Google，不过是些工具的使用问题而已。关于[使用Tesseract训练自己的字库教程][5]我也告诉了你们链接。训练过程十分繁琐和无聊，“有多少智能，就得付出多少人工”。

以上，简单介绍了我们整个项目中使用的工具和目的。接下来，前方高能！

限于篇幅问题，我们对关键技术详细的设计算法在后续文章中分章节介绍。

1. 控件截图预处理与去边框算法

2. 基于连通域检测的文本区域提取算法

3. GUI截图文本搜索定位

4. GUI截图文本搜索定位（多线程版本）



[1]:https://de.wikipedia.org/wiki/Sikuli_(Software)
[2]:https://res.cloudinary.com/flhonker/image/upload/v1533435284/githubio/icbc/sikuli_use.jpg
[3]:http://sikulix-2014.readthedocs.io/en/latest/index.html
[4]:https://github.com/tesseract-ocr/tesseract
[5]:https://blog.csdn.net/m0epNwstYk4/article/details/78890681
[6]:http://tess4j.sourceforge.net/
[7]:https://opencv.org/
[8]:https://github.com/opencv